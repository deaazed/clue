pub mod auth;
mod community;
mod health;
mod memories;
mod places;
mod sessions;

use axum::Router;
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new()
        .merge(health::router())
        .nest("/api", sessions::router())
        .nest("/api", places::router())
        .nest("/api", memories::router())
        .nest("/api", auth::router())
        .nest("/api", community::router())
}
