# BlueFox-Nexus Design Document

## 1. Project Overview

BlueFox-Nexus is a lightweight SIEM (Security Information and Event Management) and observability platform written in Rust.

It is designed for **internal enterprise deployment (SI environments)**, providing unified visibility across:

- System logs (syslog)
- SNMP data (polling + traps)
- Security events
- Metrics and telemetry
- Network device discovery

### Goal

Provide a **high-performance, low-overhead security and observability layer** that can be integrated into enterprise SI architectures as a backend system component.

---

## 2. Deployment Model

BlueFox-Nexus is designed for:

- Internal enterprise systems (SI / SOC environments)
- Private cloud infrastructure
- On-premise deployments
- Hybrid architectures

It is not designed as a SaaS platform or external hosted service.

---

## 3. Technical Stack

### Backend

- **Language**: Rust
- **Framework**: Axum (REST API)
- **Async Runtime**: Tokio
- **Database**: PostgreSQL (sqlx)
- **Serialization**: Serde
- **Logging**: Tracing + file appender

### Frontend

- **Language**: TypeScript
- **Framework**: React
- **Build Tool (recommended)**: Vite
- **UI Approach**: Component-based dashboard architecture (SOC/SIEM-style interface)

### Communication

- REST API (JSON over HTTP)
- Future extension: WebSockets (real-time streaming)

---

## 4. Core Components

- `/ingestion` → Data collection (syslog, SNMP, traps)
- `/core/pipeline` → Event normalization and processing
- `/core/dispatcher` → Persistence layer (PostgreSQL)
- `/rules` → Detection and correlation engine (future)
- `/api` → REST API (Axum)
- `/frontend` → React + TypeScript dashboard

---

## 5. System Architecture

The system is built around a **pipeline-based event processing architecture**.

---

### A. Ingestion Layer (`backend/src/ingestion`)

Responsible for collecting external data sources:

- **Syslog Listener**
  - UDP syslog ingestion
  - Parsing via syslog parser
  - Conversion into normalized Event model

- **SNMP Listener**
  - UDP polling mechanism
  - UDP trap receiver
  - Generates:
    - Metrics
    - Events
    - Device discovery signals

---

### B. Core Pipeline (`backend/src/core/pipeline`)

Central processing layer of the system.

Responsibilities:

- Receives:
  - Events
  - Metrics
  - Device information

- Normalizes and forwards data to:
  - Dispatcher (persistence layer)
  - Rule engine (future correlation engine)

Designed for **high-throughput asynchronous processing**.

---

### C. Dispatcher (`backend/src/core/dispatcher`)

Persistence and routing layer.

Responsibilities:

- Stores events in PostgreSQL
- Stores alerts (generated or incoming)
- Stores metrics (current + planned expansion)
- Stores discovered devices

Acts as a **central persistence abstraction layer**.

---

### D. Rule Engine (`backend/src/rules`)

Planned component for security correlation.

Capabilities:

- Event evaluation
- Metric-based anomaly detection
- Alert generation
- Multi-threaded rule execution (`rule_worker_threads`)

Future evolution:
- correlation engine (SIEM-style rules)
- detection pipelines

---

### E. API Layer (`backend/src/api`)

Axum-based REST API exposing system data.

Endpoints:

- `/events` → event logs
- `/alerts` → security alerts
- `/metrics` → system metrics
- `/devices` → discovered hosts
- `/health` → system status

Features:

- Pagination
- Filtering (severity, host, type)
- Sorting (planned enhancement)

---

### F. Frontend (`frontend/`)

Frontend is a **React + TypeScript dashboard application** designed for SOC / SIEM-style operations.

It provides a centralized interface for security and observability workflows.

#### Modules:

- Global SIEM overview dashboard
- Event explorer (log search and filtering)
- Alerts management interface
- Device inventory view
- Metrics visualization dashboards (charts, time-series)

#### Design principles:

- Data-heavy UI optimized for large log volumes
- Component-based architecture
- Real-time capable (WebSocket-ready)
- Enterprise dashboard ergonomics (SOC operator oriented)

---

## 6. Data Model

### Event
Normalized representation of system or network activity (syslog, SNMP, agents).

### Metric
Numeric telemetry data (CPU, network, SNMP polling values).

### Alert
Security or operational alert generated from rule engine or event conditions.

### Device
Discovered network device (based on SNMP and network discovery logic).

---

## 7. Data Flow

Syslog / SNMP / Agents  
↓  
Ingestion Layer  
↓  
Core Pipeline  
↓  
Dispatcher + Rule Engine  
↓  
PostgreSQL Storage  
↓  
REST API Layer  
↓  
Frontend Dashboard (React + TypeScript)

---

## 8. Integration in Enterprise Systems

BlueFox-Nexus is designed to be integrated as a **backend observability and security component** inside enterprise SI architectures.

Typical integrations:

- Internal APIs (SI systems)
- SOC monitoring stacks
- Automation pipelines
- Network monitoring infrastructure
- Security event aggregation systems

It operates as a **system infrastructure component**, not as an end-user SaaS product.

---

## 9. MVP Scope (Current Version)

### Already implemented:

- Syslog ingestion
- SNMP polling + traps
- Event pipeline
- Metrics generation
- Device discovery (basic)
- PostgreSQL storage layer
- Alert system (basic)
- Structured logging (tracing)
- REST API with pagination & filtering

### Core capabilities:

- Real-time ingestion
- Central event normalization
- Basic alerting pipeline
- API-driven architecture
- Backend-first SIEM foundation

---

## 10. Future Improvements

### Security & Access
- Authentication (JWT / OAuth2)
- Role-based access control (RBAC)

### Real-time
- WebSocket streaming for live events
- Live dashboard updates

### Detection
- Advanced correlation engine
- ML-based anomaly detection (optional extension)
- Rule DSL (declarative detection rules)

### Scalability
- Distributed agents
- Horizontal scaling ingestion nodes
- Message queue integration (Kafka / NATS optional)

### Observability
- Metrics export (Prometheus compatible)
- Advanced tracing pipeline

---

## 11. Design Principles

- High performance (Rust-first design)
- Low overhead ingestion
- Modular pipeline architecture
- Enterprise integration first
- Backend-centric design (SIEM core)
- Extensible rule engine
- Frontend decoupled (React + TypeScript dashboard)

---

## 12. Non-Goals

- SaaS hosting platform
- Public multi-tenant service
- End-user consumer product
- Heavy frontend dependency

---

## 13. Security Model

- Designed for internal enterprise trust boundaries
- No external user exposure by default
- Intended for controlled SI environments
- Can be deployed in isolated networks
