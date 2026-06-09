use chrono::Utc;
use tokio::net::UdpSocket;
use uuid::Uuid;

use crate::{
    core::pipeline::Pipeline, models::device::Device, models::event::Event, models::metric::Metric,
};

pub async fn start_snmp_listener(
    pipeline: Pipeline,
    snmp_port: u16,
    snmp_trap_port: u16,
) -> Result<(), Box<dyn std::error::Error>> {
    // 📡 Socket polling SNMP
    let polling_socket = UdpSocket::bind(format!("0.0.0.0:{}", snmp_port)).await?;

    // 📡 Socket traps SNMP
    let trap_socket = UdpSocket::bind(format!("0.0.0.0:{}", snmp_trap_port)).await?;

    tracing::info!(
        "[SNMP] Listening on {} (polling) and {} (traps)",
        snmp_port,
        snmp_trap_port
    );

    let mut polling_buf = vec![0u8; 2048];
    let mut trap_buf = vec![0u8; 2048];

    loop {
        tokio::select! {

            // 📊 POLLING → METRICS (+ DEVICE discovery possible)
            result = polling_socket.recv_from(&mut polling_buf) => {
                if let Ok((size, addr)) = result {

                    let _msg = String::from_utf8_lossy(&polling_buf[..size]).to_string();

                    // 📊 Metric SNMP
                    let metric = Metric {
                        id: Uuid::new_v4(),
                        host: addr.ip().to_string(),
                        metric_type: "snmp_poll".to_string(),
                        value: 42.0, // simulation (à remplacer par parsing SNMP réel)
                        timestamp: Utc::now(),
                        source: "snmp".to_string(),
                    };

                    pipeline.process_metric(metric).await;

                    // 🖥️ DEVICE discovery simple (optionnel mais utile)
                    let device = Device {
                        id: Uuid::new_v4(),
                        hostname: addr.ip().to_string(),
                        ip: addr.ip().to_string(),
                        os: None,
                        tags: vec!["snmp".to_string()],
                        is_active: true,
                        last_seen: Some(Utc::now()),
                        metadata: None,
                    };

                    pipeline.process_device(device).await;
                }
            }

            // 🚨 TRAPS → EVENTS
            result = trap_socket.recv_from(&mut trap_buf) => {
                if let Ok((size, addr)) = result {

                    let _msg = String::from_utf8_lossy(&trap_buf[..size]).to_string();

                    let event = Event {
                        id: Uuid::new_v4(),
                        event_type: "snmp_trap".to_string(),
                        source: addr.ip().to_string(),
                        host: addr.ip().to_string(),
                        message: "SNMP trap received".to_string(),
                        severity: "warning".to_string(),
                        tags: vec!["snmp".to_string(), "trap".to_string()],
                        timestamp: Utc::now(),
                    };

                    pipeline.process(event).await;
                }
            }
        }
    }
}
