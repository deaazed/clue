use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{delete, get, post, put},
    Json, Router,
};
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
    id: Option<String>, // only required on POST
    name: String,
    lat: f64,
    lng: f64,
    boundary: Option<Value>,
}

#[derive(Serialize, sqlx::FromRow)]
struct PlaceRow {
    id: String,
    name: String,
    lat: f64,
    lng: f64,
    boundary: Option<Value>,
}

/// POST /api/places — create or update (full upsert so renames sync correctly)
async fn upsert(
    State(pool): State<PgPool>,
    Json(body): Json<PlaceBody>,
) -> Result<StatusCode, StatusCode> {
    let id = body.id.ok_or(StatusCode::BAD_REQUEST)?;
    sqlx::query(
        "INSERT INTO places (id, name, lat, lng, boundary)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO UPDATE
           SET name     = EXCLUDED.name,
               lat      = EXCLUDED.lat,
               lng      = EXCLUDED.lng,
               boundary = EXCLUDED.boundary",
    )
    .bind(&id)
    .bind(&body.name)
    .bind(body.lat)
    .bind(body.lng)
    .bind(&body.boundary)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::CREATED)
}

/// GET /api/places
async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<PlaceRow>>, StatusCode> {
    let rows = sqlx::query_as::<_, PlaceRow>(
        "SELECT id, name, lat, lng, boundary FROM places ORDER BY created_at DESC",
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
