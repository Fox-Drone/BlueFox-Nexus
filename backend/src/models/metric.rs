use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use serde_json::Value;
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Metric {
    pub id: Uuid,
    pub host: String,
    pub metric_type: String,
    pub value: f64,
    pub source: String,
    pub labels: Option<Value>,
    pub timestamp: DateTime<Utc>,
}
