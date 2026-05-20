use axum::{
    Router,
    routing::{get, post},
};

use crate::{
    api::handlers::{get_alerts, get_events, health, ingest_log},
    app_state::AppState,
    ingestion::http::ingest_event,
};

pub fn create_routes(state: AppState) -> Router {
    Router::new()
        .route("/ingest/log", post(ingest_log))
        .route("/events", get(get_events))
        .route("/alerts", get(get_alerts))
        .route("/ingest", post(ingest_event))
        .route("/health", get(health))
        .with_state(state)
}
