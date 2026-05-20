use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize, sqlx::FromRow)]
pub struct Alert {
    pub id: Uuid,
    pub event_id: Option<Uuid>,
    pub alert_type: String,
    pub severity: String,
    pub message: String,
    pub timestamp: DateTime<Utc>,
    pub host: String,
}
