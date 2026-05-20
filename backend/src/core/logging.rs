use std::path::Path;
use tracing_appender::non_blocking;
use tracing_appender::non_blocking::WorkerGuard;
use tracing_appender::rolling;
use tracing_subscriber::fmt;

pub fn init_logging(
    log_file_path: String,
    log_level: String,
) -> Result<WorkerGuard, Box<dyn std::error::Error>> {
    let path = Path::new(&log_file_path);

    // 📁 dossier parent
    let parent = path.parent().unwrap_or_else(|| Path::new("."));

    let file_name = path
        .file_name()
        .unwrap_or_else(|| std::ffi::OsStr::new("bluefox.log"));

    // 📄 file appender (logs fichier)
    let file_appender = rolling::never(parent, file_name);

    let (non_blocking, guard) = non_blocking(file_appender);

    let level = match log_level.as_str() {
        "debug" => tracing::Level::DEBUG,
        "warn" => tracing::Level::WARN,
        "error" => tracing::Level::ERROR,
        _ => tracing::Level::INFO,
    };

    // 📊 format + niveau
    let subscriber = fmt()
        .with_max_level(level)
        .with_writer(non_blocking)
        .finish();

    tracing::subscriber::set_global_default(subscriber)?;

    Ok(guard)
}
