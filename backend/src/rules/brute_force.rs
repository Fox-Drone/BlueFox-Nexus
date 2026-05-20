use chrono::Utc;
use std::collections::HashMap;
use uuid::Uuid;

use crate::{models::alert::Alert, models::event::Event};

#[derive(Default)]
pub struct BruteForceRule {
    pub attempts: HashMap<String, u32>,
}

impl BruteForceRule {
    pub fn new() -> Self {
        Self {
            attempts: HashMap::new(),
        }
    }

    pub fn process(&mut self, event: &Event) -> Option<Alert> {
        if event.event_type != "login_failed" {
            return None;
        }

        let counter = self.attempts.entry(event.source.clone()).or_insert(0);

        *counter += 1;

        if *counter >= 5 {
            return Some(Alert {
                id: Uuid::new_v4(),

                // event_id est Option<Uuid>
                event_id: None,

                alert_type: "brute_force".to_string(),

                message: format!(
                    "Brute force detected from {} ({} attempts)",
                    event.source, counter
                ),

                host: event.source.clone(),

                severity: "high".to_string(),

                timestamp: Utc::now(),
            });
        }

        None
    }
}
