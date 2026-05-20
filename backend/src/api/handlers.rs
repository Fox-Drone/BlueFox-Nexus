use axum::{
    Json,
    extract::{Query, State},
    http::StatusCode,
};
use serde::Serialize;
use uuid::Uuid;

use crate::{
    api::dto::{AlertsQuery, EventsQuery, IngestEventDto},
    app_state::AppState,
    models::{alert::Alert, event::Event},
    storage::{alerts, events},
};

pub async fn ingest_log(
    State(state): State<AppState>,
    Json(payload): Json<IngestEventDto>,
) -> Json<Event> {
    let event = Event {
        id: Uuid::new_v4(),
        source: payload.source,
        host: payload.host,
        timestamp: payload.timestamp,
        event_type: payload.event_type,
        severity: payload.severity,
        message: payload.message,
        tags: payload.tags,
    };

    let _ = events::insert_event(&state.pool, &event)
        .await
        .expect("DB insert failed");

    let alerts = vec![];

    for alert in &alerts {
        alerts::insert_alert(&state.pool, alert).await.unwrap();
    }

    Json(event)
}

pub async fn get_events(
    State(state): State<AppState>,
    Query(params): Query<EventsQuery>,
) -> Result<Json<Vec<Event>>, StatusCode> {
    let limit = params.limit.unwrap_or(50);
    let offset = params.offset.unwrap_or(0);

    let events = events::get_events(&state.pool, params.host, params.severity, limit, offset)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(events))
}

pub async fn get_alerts(
    State(state): State<AppState>,
    Query(params): Query<AlertsQuery>,
) -> Result<Json<Vec<Alert>>, StatusCode> {
    let limit = params.limit.unwrap_or(50);
    let offset = params.offset.unwrap_or(0);

    let alerts = alerts::get_alerts(&state.pool, params.severity, params.host, limit, offset)
        .await
        .map_err(|_| StatusCode::INTERNAL_SERVER_ERROR)?;

    Ok(Json(alerts))
}

#[derive(Serialize)]
pub struct HealthResponse {
    status: String,
    database: String,
}

pub async fn health(State(state): State<AppState>) -> Json<HealthResponse> {
    let db_ok = sqlx::query("SELECT 1").execute(&state.pool).await.is_ok();

    Json(HealthResponse {
        status: "ok".to_string(),
        database: if db_ok { "up" } else { "down" }.to_string(),
    })
}
