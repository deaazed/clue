use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/memories", post(create))
        .route("/memories", get(list))
        .route("/memories/:id", get(get_one))
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
}

async fn create(
    State(pool): State<PgPool>,
    Json(body): Json<CreateMemory>,
) -> Result<StatusCode, StatusCode> {
    let ble = body
        .ble_devices
        .unwrap_or_else(|| Value::Array(vec![]));
    let icon = body.icon_type.unwrap_or_else(|| "other".into());

    sqlx::query(
        "INSERT INTO memories (id, place_id, label, icon_type, note, lat, lng, ble_devices, path)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
         ON CONFLICT (id) DO NOTHING",
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
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::CREATED)
}

async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<MemoryRow>>, StatusCode> {
    let rows = sqlx::query_as::<_, MemoryRow>(
        "SELECT id, place_id, label, icon_type, note, lat, lng
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
                   ble_devices, path, created_at
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
