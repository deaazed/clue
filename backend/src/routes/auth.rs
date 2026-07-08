use axum::{
    extract::State,
    http::{HeaderMap, StatusCode},
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::PgPool;
use uuid::Uuid;

pub fn router() -> Router<PgPool> {
    Router::new()
        .route("/auth/google", post(google))
        .route("/auth/register", post(register))
        .route("/auth/login", post(login))
        .route("/auth/me", get(me))
}

#[derive(Serialize, sqlx::FromRow)]
pub struct User {
    pub id: String,
    pub email: String,
    pub display_name: String,
}

#[derive(Serialize)]
struct AuthResponse {
    token: Uuid,
    user: User,
}

/// Resolve the user id from an `Authorization: Bearer <token>` header.
/// Returns None when absent or invalid — callers treat that as anonymous.
pub async fn user_id_from_headers(pool: &PgPool, headers: &HeaderMap) -> Option<String> {
    let token = headers
        .get("authorization")?
        .to_str()
        .ok()?
        .strip_prefix("Bearer ")?
        .trim()
        .parse::<Uuid>()
        .ok()?;

    sqlx::query_scalar::<_, String>("SELECT user_id FROM auth_tokens WHERE token = $1")
        .bind(token)
        .fetch_optional(pool)
        .await
        .ok()
        .flatten()
}

async fn issue_token(pool: &PgPool, user_id: &str) -> Result<Uuid, StatusCode> {
    let token = Uuid::new_v4();
    sqlx::query("INSERT INTO auth_tokens (token, user_id) VALUES ($1, $2)")
        .bind(token)
        .bind(user_id)
        .execute(pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;
    Ok(token)
}

async fn fetch_user(pool: &PgPool, id: &str) -> Result<User, StatusCode> {
    sqlx::query_as::<_, User>("SELECT id, email, display_name FROM users WHERE id = $1")
        .bind(id)
        .fetch_optional(pool)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
        .ok_or(StatusCode::NOT_FOUND)
}

// ── Google SSO ────────────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct GoogleBody {
    id_token: String,
}

#[derive(Deserialize)]
struct GoogleTokenInfo {
    sub: String,
    email: Option<String>,
    email_verified: Option<String>,
    name: Option<String>,
    aud: Option<String>,
    #[serde(default)]
    error_description: Option<String>,
}

/// POST /api/auth/google — verify a Google ID token via the tokeninfo
/// endpoint, upsert the user, return a bearer token.
async fn google(
    State(pool): State<PgPool>,
    Json(body): Json<GoogleBody>,
) -> Result<Json<AuthResponse>, StatusCode> {
    let info: GoogleTokenInfo = reqwest::Client::new()
        .get("https://oauth2.googleapis.com/tokeninfo")
        .query(&[("id_token", body.id_token.as_str())])
        .send()
        .await
        .map_err(|_| StatusCode::BAD_GATEWAY)?
        .json()
        .await
        .map_err(|_| StatusCode::UNAUTHORIZED)?;

    if info.error_description.is_some() {
        return Err(StatusCode::UNAUTHORIZED);
    }
    // Optionally pin the OAuth client: set GOOGLE_CLIENT_ID on the server.
    if let Ok(expected) = std::env::var("GOOGLE_CLIENT_ID") {
        if info.aud.as_deref() != Some(expected.as_str()) {
            return Err(StatusCode::UNAUTHORIZED);
        }
    }
    let email = info.email.ok_or(StatusCode::UNAUTHORIZED)?;
    if info.email_verified.as_deref() != Some("true") {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let id = format!("google:{}", info.sub);
    let name = info.name.unwrap_or_else(|| email.clone());

    sqlx::query(
        "INSERT INTO users (id, email, display_name)
         VALUES ($1, $2, $3)
         ON CONFLICT (id) DO UPDATE
           SET email = EXCLUDED.email, display_name = EXCLUDED.display_name",
    )
    .bind(&id)
    .bind(&email)
    .bind(&name)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let token = issue_token(&pool, &id).await?;
    let user = fetch_user(&pool, &id).await?;
    Ok(Json(AuthResponse { token, user }))
}

// ── Email + password ──────────────────────────────────────────────────────────

#[derive(Deserialize)]
struct RegisterBody {
    email: String,
    password: String,
    display_name: String,
}

/// POST /api/auth/register
async fn register(
    State(pool): State<PgPool>,
    Json(body): Json<RegisterBody>,
) -> Result<Json<AuthResponse>, StatusCode> {
    let email = body.email.trim().to_lowercase();
    if email.is_empty() || !email.contains('@') || body.password.len() < 8 {
        return Err(StatusCode::BAD_REQUEST);
    }
    let id = format!("email:{email}");
    let hash =
        bcrypt::hash(&body.password, bcrypt::DEFAULT_COST).map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    let inserted = sqlx::query(
        "INSERT INTO users (id, email, display_name, password_hash)
         VALUES ($1, $2, $3, $4)
         ON CONFLICT (id) DO NOTHING",
    )
    .bind(&id)
    .bind(&email)
    .bind(body.display_name.trim())
    .bind(&hash)
    .execute(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    if inserted.rows_affected() == 0 {
        return Err(StatusCode::CONFLICT);
    }

    let token = issue_token(&pool, &id).await?;
    let user = fetch_user(&pool, &id).await?;
    Ok(Json(AuthResponse { token, user }))
}

#[derive(Deserialize)]
struct LoginBody {
    email: String,
    password: String,
}

/// POST /api/auth/login
async fn login(
    State(pool): State<PgPool>,
    Json(body): Json<LoginBody>,
) -> Result<Json<AuthResponse>, StatusCode> {
    let email = body.email.trim().to_lowercase();
    let id = format!("email:{email}");

    let hash = sqlx::query_scalar::<_, Option<String>>(
        "SELECT password_hash FROM users WHERE id = $1",
    )
    .bind(&id)
    .fetch_optional(&pool)
    .await
    .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?
    .flatten()
    .ok_or(StatusCode::UNAUTHORIZED)?;

    if !bcrypt::verify(&body.password, &hash).unwrap_or(false) {
        return Err(StatusCode::UNAUTHORIZED);
    }

    let token = issue_token(&pool, &id).await?;
    let user = fetch_user(&pool, &id).await?;
    Ok(Json(AuthResponse { token, user }))
}

/// GET /api/auth/me — who am I (validates the bearer token)
async fn me(
    State(pool): State<PgPool>,
    headers: HeaderMap,
) -> Result<Json<User>, StatusCode> {
    let user_id = user_id_from_headers(&pool, &headers)
        .await
        .ok_or(StatusCode::UNAUTHORIZED)?;
    Ok(Json(fetch_user(&pool, &user_id).await?))
}
