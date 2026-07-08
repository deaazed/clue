use axum::{extract::State, http::StatusCode, routing::get, Json, Router};
use serde::Serialize;
use sqlx::PgPool;

pub fn router() -> Router<PgPool> {
    Router::new().route("/community/top", get(top))
}

#[derive(Serialize, sqlx::FromRow)]
struct Contributor {
    user_id: String,
    display_name: String,
    contributions: i64,
}

#[derive(Serialize)]
struct CommunityStats {
    contributors: Vec<Contributor>,
    anonymous_contributions: i64,
}

/// GET /api/community/top — most contributing users (public places + clues)
async fn top(State(pool): State<PgPool>) -> Result<Json<CommunityStats>, StatusCode> {
    let contributors = sqlx::query_as::<_, Contributor>(
        "SELECT u.id AS user_id,
                u.display_name,
                (SELECT count(*) FROM places   p WHERE p.user_id = u.id)
              + (SELECT count(*) FROM memories m WHERE m.user_id = u.id)
                  AS contributions
         FROM users u
         ORDER BY contributions DESC, u.created_at ASC
         LIMIT 20",
    )
    .fetch_all(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let anonymous: i64 = sqlx::query_scalar(
        "SELECT (SELECT count(*) FROM places   WHERE user_id IS NULL)
              + (SELECT count(*) FROM memories WHERE user_id IS NULL)",
    )
    .fetch_one(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(CommunityStats {
        contributors: contributors
            .into_iter()
            .filter(|c| c.contributions > 0)
            .collect(),
        anonymous_contributions: anonymous,
    }))
}
