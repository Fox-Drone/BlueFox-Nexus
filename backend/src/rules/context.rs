use crate::models::event::Event;
use chrono::Utc;
use std::collections::HashMap;
use std::sync::{Arc, Mutex};

#[derive(Clone)]
pub struct RuleContext {
    pub events_by_ip: Arc<Mutex<HashMap<String, Vec<Event>>>>,
}

impl RuleContext {
    pub fn new() -> Self {
        Self {
            events_by_ip: Arc::new(Mutex::new(HashMap::new())),
        }
    }

    pub fn add_event(&self, event: Event) {
        let mut map = self.events_by_ip.lock().unwrap();

        map.entry(event.host.clone()).or_insert(vec![]).push(event);
    }

    pub fn get_recent_events(&self, ip: &str) -> Vec<Event> {
        let map = self.events_by_ip.lock().unwrap();

        let now = Utc::now();

        map.get(ip)
            .unwrap_or(&vec![])
            .iter()
            .filter(|e| now.signed_duration_since(e.timestamp).num_minutes() <= 2)
            .cloned()
            .collect()
    }
}
