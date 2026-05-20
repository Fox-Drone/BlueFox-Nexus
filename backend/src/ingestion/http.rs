use axum::{Json, extract::State};

use crate::{app_state::AppState, models::event::Event};

pub async fn ingest_event(
    State(state): State<AppState>,
    Json(payload): Json<Event>,
) -> &'static str {
    state.pipeline.process(payload).await;

    "event received"
}
