use crate::models::event::Event;
use chrono::Utc;
use uuid::Uuid;

pub fn parse_syslog(raw: String, host: String) -> Event {
    let lower = raw.to_lowercase();

    let (event_type, severity) = if lower.contains("failed") {
        ("auth", "Warning")
    } else if lower.contains("error") {
        ("system", "High")
    } else if lower.contains("critical") {
        ("system", "Critical")
    } else {
        ("generic", "Info")
    };

    Event {
        id: Uuid::new_v4(),
        source: "syslog".to_string(),
        host,
        timestamp: Utc::now(),
        event_type: event_type.to_string(),
        severity: severity.to_string(),
        message: raw,
        tags: vec!["syslog".to_string()],
    }
}
