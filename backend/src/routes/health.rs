use axum::{routing::get, Router};
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new().route("/health", get(handler))
}

async fn handler() -> &'static str {
    "ok"
}
