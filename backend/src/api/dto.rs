use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct IngestEventDto {
    pub source: String,
    pub host: String,
    pub event_type: String,
    pub severity: String,
    pub message: String,
    pub tags: Vec<String>,
    pub timestamp: DateTime<Utc>,
}

#[derive(Deserialize)]
pub struct EventsQuery {
    pub host: Option<String>,
    pub severity: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}

#[derive(Deserialize)]
pub struct AlertsQuery {
    pub host: Option<String>,
    pub severity: Option<String>,
    pub limit: Option<i64>,
    pub offset: Option<i64>,
}
