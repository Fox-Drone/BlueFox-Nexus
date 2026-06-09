use serde::{Deserialize, Serialize};
use serde_json::Value;
use chrono::{DateTime, Utc};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Device {
    pub id: Uuid,
    pub hostname: String,
    pub ip: String,
    pub os: Option<String>,
    pub tags: Vec<String>,
    pub is_active: bool,
    pub last_seen: Option<DateTime<Utc>>,
    pub metadata: Option<Value>,
}
