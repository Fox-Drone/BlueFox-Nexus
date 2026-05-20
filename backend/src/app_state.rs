use sqlx::PgPool;
use std::sync::Arc;

use crate::core::pipeline::Pipeline;

#[derive(Clone)]
pub struct AppState {
    pub pool: PgPool,
    pub pipeline: Arc<Pipeline>,
}
