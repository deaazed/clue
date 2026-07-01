use axum::{
    extract::State,
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;


pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/places", post(create))
        .route("/places", get(list))
}

#[derive(Deserialize)]
struct CreatePlace {
    id: String,
    name: String,
    lat: f64,
    lng: f64,
}

#[derive(Serialize, sqlx::FromRow)]
struct PlaceRow {
    id: String,
    name: String,
    lat: f64,
    lng: f64,
}

async fn create(
    State(pool): State<PgPool>,
    Json(body): Json<CreatePlace>,
) -> Result<StatusCode, StatusCode> {
    sqlx::query(
        "INSERT INTO places (id, name, lat, lng)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (id) DO NOTHING",
    )
    .bind(&body.id)
    .bind(&body.name)
    .bind(body.lat)
    .bind(body.lng)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(StatusCode::CREATED)
}

async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<PlaceRow>>, StatusCode> {
    let rows = sqlx::query_as::<_, PlaceRow>(
        "SELECT id, name, lat, lng FROM places ORDER BY created_at DESC",
    )
    .fetch_all(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(rows))
}
