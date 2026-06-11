# BlueFox Design Document

## 1. Overview

BlueFox is a high-performance Security Information and Event Management (SIEM) and observability platform written in Rust.

It is designed for internal enterprise security infrastructures (SI / SOC environments), providing centralized visibility across logs, metrics, and network activity.

The platform serves as a modular foundation for data collection, monitoring, detection, and analysis, while remaining extensible for future security and observability capabilities.

---

## 2. System Purpose

The system provides a unified platform for:

- Collecting logs, metrics, and infrastructure telemetry
- Normalizing incoming events into a consistent format
- Processing and storing operational and security data
- Managing devices, events, metrics, and alerts
- Exposing collected information through a centralized API
- Providing a foundation for future correlation, detection, and analysis capabilities

---

## 3. Deployment Model

BlueFox is designed for:

- Internal security and monitoring systems (SI / SOC environments)
- On-premise infrastructure
- Private or self-hosted environments
- Hybrid setups combining local and remote components

---

## 4. Technical Stack

### Backend

- **Language**: Rust
- **Framework**: Axum (REST API)
- **Runtime**: Tokio (asynchronous execution)
- **Database**: PostgreSQL (sqlx)
- **Serialization**: Serde
- **Observability**: Tracing

### Frontend

- **Language**: TypeScript
- **Framework**: React
- **Build Tool**: Vite
- **UI**: Security-focused dashboard interface

### Communication Layer
- REST API over HTTP (JSON)
- Planned: real-time event streaming for live updates

---

## 5. High-Level Architecture

The system is built around a **pipeline-based event processing model**.

### Global Flow

Internet / LAN
       │
     Nginx
       │
 ┌─────┴─────┐
 │ Frontend  │
 │ (Vite)    │
 └─────┬─────┘
       │
    /api/*
       │
 ┌─────▼─────┐
 │ Backend   │
 │ Rust      │
 │ Axum      │
 └─────┬─────┘
       │
 PostgreSQL

### Core Flow

Syslog / SNMP / Agents  
↓  
Ingestion Layer  
↓  
Processing Pipeline  
↓  
Persistence Layer  
↓  
Detection Engine (future)  
↓  
API Layer  
↓  
Frontend Dashboard

---

## 6. Core Architecture Layers

### 6.1 Ingestion Layer

Responsible for collecting raw data from infrastructure sources:

- Syslog streams (UDP)
- SNMP polling and traps
- Network and device signals

Transforms raw inputs into structured security events and metrics.

---

### 6.2 Processing Pipeline

Central event processing layer responsible for:

- Normalizing incoming data
- Enriching events with contextual information
- Routing data to persistence and detection components
- Ensuring asynchronous and high-throughput processing

---

### 6.3 Persistence Layer

Responsible for long-term storage of:

- Security events
- Metrics and telemetry
- Alerts
- Discovered devices

Backed by a relational database designed for query and filtering performance.

---

### 6.4 Detection Engine (Future)

Planned component for security correlation and analysis:

- Rule-based detection
- Anomaly detection
- Event correlation across multiple sources
- Alert generation

Future evolution toward AI-assisted analysis is considered.

---

### 6.5 API Layer

Provides a unified REST interface to all system data.

Exposes:

- Security events
- Alerts
- Metrics
- Devices
- System health

Supports filtering, pagination, and structured querying.

---

### 6.6 Frontend Dashboard

A SOC-oriented interface providing:

- Real-time security overview
- Event exploration and filtering
- Alert management
- Device inventory
- Metrics visualization

Designed for high-density data analysis and operational monitoring.

---

## 7. Data Model

- **Event** → normalized security or system activity
- **Metric** → time-series or numeric telemetry
- **Alert** → detection output or anomaly signal
- **Device** → discovered infrastructure asset

---

## 8. MVP Scope

Current implementation includes:

- Syslog ingestion
- SNMP polling and traps
- Event processing pipeline
- Basic metrics generation
- Device discovery (basic)
- Persistent storage layer
- Basic alerting capabilities
- REST API with filtering and pagination
- Structured logging and tracing

---

## 9. Future Evolution

### Security & Access
- Authentication and authorization (RBAC)

### Real-time Capabilities
- WebSocket streaming
- Live event dashboards

### Detection & Intelligence
- Advanced correlation engine
- Rule DSL for detections
- AI-assisted anomaly detection

### Scalability
- Distributed ingestion nodes
- Horizontal scaling support
- Message queue integration (optional)

### Observability
- External metrics export (Prometheus-compatible)
- Enhanced tracing pipeline

---

## 10. Design Principles

- Modular and extensible architecture
- Backend-focused system design
- Separation between frontend and backend components
- Security and observability as core concerns
- Designed for internal and controlled environments
- Flexible foundation for future detection and analysis features
