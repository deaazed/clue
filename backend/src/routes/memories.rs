use axum::{
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    routing::{delete, get, post},
    Json, Router,
};

use super::auth;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/memories", post(create))
        .route("/memories", get(list))
        .route("/memories/{id}", get(get_one))
        .route("/memories/{id}", delete(remove))
}

#[derive(Deserialize)]
struct CreateMemory {
    id: String,
    place_id: Option<String>,
    label: String,
    icon_type: Option<String>,
    note: Option<String>,
    lat: Option<f64>,
    lng: Option<f64>,
    ble_devices: Option<Value>,
    path: Option<Value>,
    boundary: Option<Value>,
    timestamp_ms: Option<i64>,
}

#[derive(Serialize, sqlx::FromRow)]
struct MemoryRow {
    id: String,
    place_id: Option<String>,
    label: String,
    icon_type: String,
    note: Option<String>,
    lat: Option<f64>,
    lng: Option<f64>,
    timestamp_ms: i64,
    ble_devices: Option<Value>,
    path: Option<Value>,
    boundary: Option<Value>,
}

async fn create(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<CreateMemory>,
) -> Result<StatusCode, StatusCode> {
    let ble = body.ble_devices.unwrap_or_else(|| Value::Array(vec![]));
    let icon = body.icon_type.unwrap_or_else(|| "other".into());
    let user_id = auth::user_id_from_headers(&pool, &headers).await;

    sqlx::query(
        "INSERT INTO memories (id, place_id, label, icon_type, note, lat, lng, ble_devices, path, boundary, timestamp_ms, user_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
         ON CONFLICT (id) DO UPDATE
           SET label       = EXCLUDED.label,
               icon_type   = EXCLUDED.icon_type,
               note        = EXCLUDED.note,
               lat         = EXCLUDED.lat,
               lng         = EXCLUDED.lng,
               ble_devices = EXCLUDED.ble_devices,
               path        = EXCLUDED.path,
               boundary    = EXCLUDED.boundary,
               user_id     = COALESCE(EXCLUDED.user_id, memories.user_id)",
    )
    .bind(&body.id)
    .bind(&body.place_id)
    .bind(&body.label)
    .bind(&icon)
    .bind(&body.note)
    .bind(body.lat)
    .bind(body.lng)
    .bind(&ble)
    .bind(&body.path)
    .bind(&body.boundary)
    .bind(body.timestamp_ms)
    .bind(&user_id)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::CREATED)
}

async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<MemoryRow>>, StatusCode> {
    let rows = sqlx::query_as::<_, MemoryRow>(
        "SELECT id, place_id, label, icon_type, note, lat, lng,
                ble_devices, path, boundary,
                COALESCE(timestamp_ms, (EXTRACT(EPOCH FROM created_at) * 1000)::bigint) AS timestamp_ms
         FROM memories ORDER BY created_at DESC",
    )
    .fetch_all(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(rows))
}

async fn get_one(
    State(pool): State<PgPool>,
    Path(id): Path<String>,
) -> Result<Json<Value>, StatusCode> {
    let row = sqlx::query_as::<_, (Value,)>(
        "SELECT row_to_json(m) FROM (
            SELECT id, place_id, label, icon_type, note, lat, lng,
                   ble_devices, path, boundary, created_at,
                   COALESCE(timestamp_ms, (EXTRACT(EPOCH FROM created_at) * 1000)::bigint) AS timestamp_ms
            FROM memories WHERE id = $1
        ) m",
    )
    .bind(&id)
    .fetch_optional(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .ok_or(StatusCode::NOT_FOUND)?;

    Ok(Json(row.0))
}

/// DELETE /api/memories/:id
async fn remove(
    State(pool): State<PgPool>,
    Path(id): Path<String>,
) -> Result<StatusCode, StatusCode> {
    let result = sqlx::query("DELETE FROM memories WHERE id = $1")
        .bind(&id)
        .execute(&pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if result.rows_affected() == 0 {
        Err(StatusCode::NOT_FOUND)
    } else {
        Ok(StatusCode::NO_CONTENT)
    }
}
