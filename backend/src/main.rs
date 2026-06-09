use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use sqlx::migrate::Migrator;

mod api;
mod app_state;
mod config;
mod core;
mod ingestion;
mod models;
mod parsers;
mod rules;
mod storage;

use crate::{
    app_state::AppState, config::Config, core::dispatcher::Dispatcher, core::logging::init_logging,
    core::pipeline::Pipeline, rules::context::RuleContext, storage::postgres,
};

static MIGRATOR: Migrator = sqlx::migrate!("./migrations");

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    dotenvy::dotenv().ok();
    let config = Config::new();

    // 📊 LOGGING INIT (console + file)
    let _log_guard = init_logging(config.log_file_path, config.log_level)?;

    tracing::info!("🚀 Starting Bluefox backend...");

    let pool = postgres::create_pool(
        &config.database_url,
        config.max_db_connections,
        config.db_timeout_secs,
    )
    .await;

    MIGRATOR
        .run(&pool)
        .await
        .map_err(|e| {
            tracing::error!("❌ Migration failed: {:?}", e);
            e
        })?;

    let ctx = RuleContext::new();

    let dispatcher = Dispatcher { pool: pool.clone() };

    let pipeline = Pipeline {
        ctx: ctx.clone(),
        dispatcher,
    };

    let pipeline_syslog = pipeline.clone();
    let pipeline_snmp = pipeline.clone();

    let state = AppState {
        pipeline: Arc::new(pipeline),
        pool: pool.clone(),
    };

    tokio::spawn(async move {
        if let Err(e) =
            ingestion::syslog::start_syslog_listener(pipeline_syslog, config.syslog_port).await
        {
            tracing::error!("[SYSLOG ERROR] {:?}", e);
        }
    });

    tokio::spawn(async move {
        if let Err(e) = ingestion::snmp::start_snmp_listener(
            pipeline_snmp,
            config.snmp_port,
            config.snmp_trap_port,
        )
        .await
        {
            tracing::error!("[SNMP ERROR] {:?}", e);
        }
    });

    // 🌐 CORS
    let cors = CorsLayer::permissive();

    let app = api::routes::create_routes(state).layer(cors);

    let addr: SocketAddr = format!("{}:{}", config.host, config.port).parse()?;
    tracing::info!("[API] Listening on {}", addr);

    let listener = tokio::net::TcpListener::bind(addr).await?;
    axum::serve(listener, app).await?;

    Ok(())
}
