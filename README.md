# 🦊 BlueFox-Nexus

**BlueFox-Nexus** is a high-performance Security Information and Event Management (SIEM) and observability platform written in **Rust**, designed for **enterprise internal security infrastructures (SI / SOC environments)**.

It provides a unified backend pipeline for collecting, processing, and analyzing security events, metrics, and network data.

---

## 🎯 Goals

BlueFox-Nexus aims to simplify enterprise security and observability by providing a unified platform that can:

- Collect and normalize logs from multiple sources (syslog, SNMP, agents)
- Process real-time security events and telemetry
- Aggregate system and network metrics
- Perform basic device discovery
- Provide a centralized REST API for security data
- Support rule-based detection and future correlation engine

---

## 🧱 System Architecture

The full system architecture, components, and data flow are described in detail here:

👉 [`DESIGN.md`](./DESIGN.md)

---

### Core Components

- `/ingestion` → Data collection (syslog, SNMP, traps)
- `/core/pipeline` → Event normalization and processing
- `/core/dispatcher` → Persistence layer (PostgreSQL)
- `/rules` → Detection and correlation engine (future)
- `/api` → REST API (Axum)
- `/frontend` → React + TypeScript dashboard

---

## 🚀 MVP (Current Version)

The current version includes:

- Syslog ingestion (UDP)
- SNMP polling and trap handling
- Event processing pipeline
- Metrics generation
- Basic device discovery
- PostgreSQL storage layer
- Basic alerting system
- REST API with filtering and pagination
- Structured logging (tracing)

---

## 🧠 Design Principles

- High-performance systems programming (Rust-first)
- Low-latency event ingestion
- Modular pipeline architecture
- Backend-first SIEM design
- Enterprise integration focus (SI / SOC environments)
- Clear separation between backend engine and frontend dashboard
- Scalable and extensible design

---

## 🔐 Security Model

BlueFox-Nexus is designed for **internal enterprise environments only**:

- No public multi-tenant SaaS model
- No external exposure by default
- Designed for controlled SI / SOC infrastructures
- Minimal attack surface
- Strong separation between ingestion, processing, storage, and UI layers
- Audit-friendly architecture

---

## 🧩 Extensibility

The platform is designed to support future expansion:

- Advanced detection rule engine
- Distributed agents (Windows / Linux)
- Real-time WebSocket streaming
- SIEM/SOAR integrations
- Plugin-based architecture (parsers, rules, connectors)
- Horizontal scaling ingestion nodes

---

## 📡 Data Sources

### Currently supported

- Syslog (UDP ingestion)
- SNMP polling
- SNMP traps

### Planned

- Windows Event Logs
- Linux audit logs
- Cloud telemetry (AWS / Azure / GCP)
- Network flow data (NetFlow / IPFIX)

---

## 📊 Data Model

- **Event** → normalized system/security activity
- **Metric** → numeric telemetry (CPU, network, SNMP data)
- **Alert** → detection output from rule engine
- **Device** → discovered network asset

---

## 📚 Inspiration

BlueFox-Nexus is inspired by modern SIEM and observability platforms such as Kibana, Splunk, and Grafana.

It is designed as:

- a **Rust-native SIEM core engine**
- a **modular backend processing pipeline**
- a **frontend React + TypeScript SOC dashboard**
- a **deployable enterprise security infrastructure component**

It is not a SaaS product, but an **internal security platform component**.

---

## 📜 License

This project is licensed under the **Business Source License (BSL 1.1)** with additional commercial use clarification defined in the LICENSE file..

- License Change Date: 2030-01-01  
- Change License: Apache License 2.0

For full details, see the [`LICENSE`](./LICENSE) file.
