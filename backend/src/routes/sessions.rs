use axum::{
    extract::{Path, State},
    http::StatusCode,
    routing::{get, post},
    Json, Router,
};
use sensors::Session;
use serde::Serialize;
use serde_json::Value;
use sqlx::PgPool;
use uuid::Uuid;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/sessions", post(upload))
        .route("/sessions", get(list))
        .route("/sessions/:id", get(get_one))
}

async fn upload(
    State(pool): State<PgPool>,
    Json(session): Json<Session>,
) -> Result<(StatusCode, Json<Value>), StatusCode> {
    let id = Uuid::parse_str(&session.id).unwrap_or_else(|_| Uuid::new_v4());
    let duration = session.duration_ms() as i64;
    let sample_count =
        (session.accel.len() + session.gyro.len() + session.mag.len()) as i32;
    let data =
        serde_json::to_value(&session).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    sqlx::query(
        "INSERT INTO sessions (id, started_at_ms, duration_ms, sample_count, data)
         VALUES ($1, $2, $3, $4, $5)
         ON CONFLICT (id) DO NOTHING",
    )
    .bind(id)
    .bind(session.started_at_ms as i64)
    .bind(duration)
    .bind(sample_count)
    .bind(&data)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok((StatusCode::CREATED, Json(serde_json::json!({ "id": id }))))
}

#[derive(Serialize, sqlx::FromRow)]
struct SessionMeta {
    id: Uuid,
    started_at_ms: i64,
    duration_ms: i64,
    sample_count: i32,
}

async fn list(State(pool): State<PgPool>) -> Result<Json<Vec<SessionMeta>>, StatusCode> {
    let rows = sqlx::query_as::<_, SessionMeta>(
        "SELECT id, started_at_ms, duration_ms, sample_count
         FROM sessions
         ORDER BY started_at_ms DESC",
    )
    .fetch_all(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(rows))
}

async fn get_one(
    State(pool): State<PgPool>,
    Path(id): Path<Uuid>,
) -> Result<Json<Value>, StatusCode> {
    let row = sqlx::query_as::<_, (Value,)>("SELECT data FROM sessions WHERE id = $1")
        .bind(id)
        .fetch_optional(&pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)?;

    Ok(Json(row.0))
}
