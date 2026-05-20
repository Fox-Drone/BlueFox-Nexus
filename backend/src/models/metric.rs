use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Metric {
    pub id: Uuid,
    pub host: String,
    pub metric_type: String,
    pub value: f64,
    pub timestamp: DateTime<Utc>,
    pub source: String,
}
