use crate::{
    models::alert::Alert,
    models::device::Device,
    models::event::Event,
    models::metric::Metric,
    storage::{alerts, devices, events, metric},
};

use sqlx::PgPool;

#[derive(Clone)]
pub struct Dispatcher {
    pub pool: PgPool,
}

impl Dispatcher {
    pub async fn handle(&self, event: Event, alerts: Vec<Alert>) {
        // 1. store event
        let _ = events::insert_event(&self.pool, &event).await;

        // 2. store alerts
        for alert in alerts {
            let _ = alerts::insert_alert(&self.pool, &alert).await;
        }
    }

    // 📊 METRICS (SNMP / monitoring)
    pub async fn handle_metric(&self, metric: Metric) {
        let _ = metric::insert_metric(&self.pool, &metric).await;
    }

    // 🖥️ DEVICES (CMDB / inventory)
    pub async fn handle_device(&self, device: Device) {
        let _ = devices::insert_device(&self.pool, &device).await;
    }
}
