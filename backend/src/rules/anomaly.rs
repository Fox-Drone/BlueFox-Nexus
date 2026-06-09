use std::collections::HashMap;

use chrono::{DateTime, Utc};

use crate::{models::alert::Alert, models::event::Event};
use uuid::Uuid;

pub struct AnomalyRule {
    pub event_count: HashMap<String, u32>,
    pub last_reset: HashMap<String, DateTime<Utc>>,
}

impl AnomalyRule {
    pub fn new() -> Self {
        Self {
            event_count: HashMap::new(),
            last_reset: HashMap::new(),
        }
    }

    pub fn process(&mut self, event: &Event) -> Option<Alert> {
        let now = Utc::now();
        let host = event.source.clone();

        // init reset time
        let reset_time = self.last_reset.entry(host.clone()).or_insert(now);

        // reset window every 60 sec
        if (now - *reset_time).num_seconds() > 60 {
            self.event_count.insert(host.clone(), 0);
            self.last_reset.insert(host.clone(), now);
        }

        let counter = self.event_count.entry(host.clone()).or_insert(0);
        *counter += 1;

        // 🚨 seuil anomalie
        if *counter > 50 {
            return Some(Alert {
                id: Uuid::new_v4(),
                event_id: None,
                rule_name: Some("anomaly".to_string()),
                alert_type: "anomaly".to_string(),
                message: format!("Anomaly detected: {} events from {} in 60s", counter, host),
                host,
                severity: "medium".to_string(),
                status: "new".to_string(),
                created_at: now,
            });
        }

        None
    }
}
