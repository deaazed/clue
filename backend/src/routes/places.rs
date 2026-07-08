use axum::{
    extract::{Path, State},
    http::{HeaderMap, StatusCode},
    routing::{delete, get, post, put},
    Json, Router,
};

use super::auth;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/places", post(upsert))
        .route("/places", get(list))
        .route("/places/{id}", put(update))
        .route("/places/{id}", delete(remove))
}

#[derive(Deserialize)]
struct PlaceBody {
    id: Option<String>,
    name: String,
    lat: f64,
    lng: f64,
    boundary: Option<Value>,
    timestamp_ms: Option<i64>,
}

#[derive(Serialize, sqlx::FromRow)]
struct PlaceRow {
    id: String,
    name: String,
    lat: f64,
    lng: f64,
    boundary: Option<Value>,
    timestamp_ms: i64,
}

/// POST /api/places — create or update (full upsert so renames and shapes sync correctly).
/// Attributed to the bearer-token user when signed in; anonymous otherwise.
async fn upsert(
    State(pool): State<PgPool>,
    headers: HeaderMap,
    Json(body): Json<PlaceBody>,
) -> Result<StatusCode, StatusCode> {
    let id = body.id.ok_or(StatusCode::BAD_REQUEST)?;
    let user_id = auth::user_id_from_headers(&pool, &headers).await;
    sqlx::query(
        "INSERT INTO places (id, name, lat, lng, boundary, timestamp_ms, user_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7)
         ON CONFLICT (id) DO UPDATE
           SET name        = EXCLUDED.name,
               lat         = EXCLUDED.lat,
               lng         = EXCLUDED.lng,
               boundary    = EXCLUDED.boundary,
               user_id     = COALESCE(EXCLUDED.user_id, places.user_id)",
    )
    .bind(&id)
    .bind(&body.name)
    .bind(body.lat)
    .bind(body.lng)
    .bind(&body.boundary)
    .bind(body.timestamp_ms)
    .bind(&user_id)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::CREATED)
}

/// GET /api/places
async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<PlaceRow>>, StatusCode> {
    let rows = sqlx::query_as::<_, PlaceRow>(
        "SELECT id, name, lat, lng, boundary,
                COALESCE(timestamp_ms, (EXTRACT(EPOCH FROM created_at) * 1000)::bigint) AS timestamp_ms
         FROM places ORDER BY created_at DESC",
    )
    .fetch_all(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(rows))
}

/// PUT /api/places/:id — partial update (name, lat/lng, boundary)
async fn update(
    State(pool): State<PgPool>,
    Path(id): Path<String>,
    Json(body): Json<PlaceBody>,
) -> Result<StatusCode, StatusCode> {
    let result = sqlx::query(
        "UPDATE places SET name = $2, lat = $3, lng = $4, boundary = $5 WHERE id = $1",
    )
    .bind(&id)
    .bind(&body.name)
    .bind(body.lat)
    .bind(body.lng)
    .bind(&body.boundary)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if result.rows_affected() == 0 {
        Err(StatusCode::NOT_FOUND)
    } else {
        Ok(StatusCode::NO_CONTENT)
    }
}

/// DELETE /api/places/:id — deletes the place; memories cascade via FK
async fn remove(
    State(pool): State<PgPool>,
    Path(id): Path<String>,
) -> Result<StatusCode, StatusCode> {
    let result = sqlx::query("DELETE FROM places WHERE id = $1")
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
