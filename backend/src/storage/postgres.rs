use sqlx::{PgPool, postgres::PgPoolOptions};
use std::time::Duration;

pub async fn create_pool(database_url: &str, max_connections: u32, timeout: u64) -> PgPool {
    PgPoolOptions::new()
        .max_connections(max_connections)
        .acquire_timeout(Duration::from_secs(timeout))
        .connect(database_url)
        .await
        .expect("Failed to connect to Postgres")
}
