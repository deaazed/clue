mod health;
mod sessions;

use axum::Router;
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new()
        .merge(health::router())
        .nest("/api", sessions::router())
}
