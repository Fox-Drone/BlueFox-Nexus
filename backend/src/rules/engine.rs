use crate::{
    models::alert::Alert, models::event::Event, rules::anomaly::AnomalyRule,
    rules::brute_force::BruteForceRule, rules::context::RuleContext,
};
use chrono::Utc;
use uuid::Uuid;

pub fn process_event(event: &Event, ctx: &RuleContext) -> Vec<Alert> {
    let mut alerts = vec![];

    let mut bf = BruteForceRule::new();

    if let Some(alert) = bf.process(event) {
        alerts.push(alert);
    }

    let mut anomaly = AnomalyRule::new();

    if let Some(alert) = anomaly.process(event) {
        alerts.push(alert);
    }

    // 🔥 récupérer historique IP
    let recent = ctx.get_recent_events(&event.host);

    // 🔴 RULE 1 : brute force avancé
    let failed_count = recent
        .iter()
        .filter(|e| e.message.to_lowercase().contains("failed"))
        .count();

    if failed_count >= 5 {
        alerts.push(Alert {
            id: Uuid::new_v4(),
            event_id: Some(event.id),
            rule_name: Some("brute_force".to_string()),
            alert_type: "brute_force".to_string(),
            severity: "High".to_string(),
            message: "Multiple failed logins detected".to_string(),
            status: "new".to_string(),
            created_at: Utc::now(),
            host: event.host.clone(),
        });
    }

    // 🟠 RULE 2 : login + sudo chain (simple version)
    let has_login = recent.iter().any(|e| e.message.contains("login"));
    let has_sudo = recent.iter().any(|e| e.message.contains("sudo"));

    if has_login && has_sudo {
        alerts.push(Alert {
            id: Uuid::new_v4(),
            event_id: Some(event.id),
            rule_name: Some("privilege_escalation".to_string()),
            alert_type: "privilege_escalation".to_string(),
            severity: "Critical".to_string(),
            message: "Suspicious privilege escalation chain".to_string(),
            status: "new".to_string(),
            created_at: Utc::now(),
            host: event.host.clone(),
        });
    }

    alerts
}
