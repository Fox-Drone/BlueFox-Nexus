use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    // 🌐 API
    pub host: String,
    pub port: u16,

    // 🗄️ DATABASE
    pub database_url: String,
    pub max_db_connections: u32,
    pub db_timeout_secs: u64,

    // 📡 INGESTION
    pub syslog_port: u16,
    pub snmp_port: u16,
    pub snmp_trap_port: u16,

    // 🧠 RULE ENGINE
    pub rule_worker_threads: usize,

    // 📊 LOGGING
    pub log_file_path: String,
    pub log_level: String,
}

impl Config {
    pub fn new() -> Self {
        Self {
            // 🌐 API
            host: env::var("HOST").unwrap_or("0.0.0.0".to_string()),
            port: env::var("PORT")
                .unwrap_or("3000".to_string())
                .parse()
                .unwrap_or(3000),

            // 🗄️ DATABASE
            database_url: env::var("DATABASE_URL").expect("DATABASE_URL missing"),
            max_db_connections: env::var("MAX_DB_CONNECTIONS")
                .unwrap_or("10".to_string())
                .parse()
                .unwrap_or(10),

            db_timeout_secs: env::var("DB_TIMEOUT_SECS")
                .unwrap_or("5".to_string())
                .parse()
                .unwrap_or(5),

            // 📡 INGESTION
            syslog_port: env::var("SYSLOG_PORT")
                .unwrap_or("5140".to_string())
                .parse()
                .unwrap_or(5140),

            snmp_port: env::var("SNMP_PORT")
                .unwrap_or("161".to_string())
                .parse()
                .unwrap_or(161),

            snmp_trap_port: env::var("SNMP_TRAP_PORT")
                .unwrap_or("162".to_string())
                .parse()
                .unwrap_or(162),

            // 🧠 RULE ENGINE
            rule_worker_threads: env::var("RULE_WORKER_THREADS")
                .unwrap_or("4".to_string())
                .parse()
                .unwrap_or(4),

            // 📊 LOGGING
            log_file_path: env::var("LOG_FILE_PATH").unwrap_or("/var/log/bluefox.log".to_string()),

            log_level: env::var("LOG_LEVEL").unwrap_or("info".to_string()),
        }
    }
}
