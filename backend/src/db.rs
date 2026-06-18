use sqlx::PgPool;

pub async fn connect() -> PgPool {
    let url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set in .env");
    PgPool::connect(&url)
        .await
        .expect("failed to connect to PostgreSQL")
}

pub async fn migrate(pool: &PgPool) {
    sqlx::migrate!("./migrations")
        .run(pool)
        .await
        .expect("failed to run migrations");
}
