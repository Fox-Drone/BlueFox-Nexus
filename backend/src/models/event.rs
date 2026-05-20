use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Event {
    pub id: Uuid,
    pub source: String,
    pub host: String,
    pub timestamp: DateTime<Utc>,
    pub event_type: String,
    pub severity: String,
    pub message: String,
    pub tags: Vec<String>,
}
