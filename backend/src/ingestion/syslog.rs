use tokio::net::UdpSocket;

use crate::{core::pipeline::Pipeline, parsers::syslog as parser};

pub async fn start_syslog_listener(pipeline: Pipeline, port: u16) -> std::io::Result<()> {
    let socket = UdpSocket::bind(format!("0.0.0.0:{}", port)).await?;
    tracing::info!("[SYSLOG] Listening on 0.0.0.0:{}", port);

    let mut buf = vec![0u8; 2048];

    loop {
        let (size, addr) = socket.recv_from(&mut buf).await?;

        let message = String::from_utf8_lossy(&buf[..size]).to_string();

        // 🧾 Parse syslog message → Event
        let event = parser::parse_syslog(message, addr.ip().to_string());

        // 🚀 PIPELINE (core SIEM)
        pipeline.process(event).await;
    }
}
