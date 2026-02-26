---

# IoT Pump Health Monitoring & Control Platform

# IoT Pump Health Monitoring & Control Platform - Smart Industrial Pump Health Management System 🚀

A professional industrial IoT based Pump Monitoring & Protection System built using Flutter.

This application allows real-time monitoring of industrial pump controllers with live status, voltage health, fault detection, runtime tracking, scheduling support, and intelligent alert management.

---

## 📌 Project Overview

IoT Pump Health Monitoring & Control Platform is a real-time IoT monitoring mobile application that connects to remote pump controllers and displays:

* Live voltage & current data
* Pump ON/OFF status
* Phase sequence health
* Voltage health monitoring
* Dry run detection
* Runtime tracking
* Device-wise location mapping
* Scheduling control
* Alerts system
* RSSI-based network health tracking
* Multi-device fleet management

This system is designed for industrial and agricultural automation use cases where reliability, safety, and remote accessibility are critical.

---

## 🏗 Architecture

Flutter Frontend
REST API Backend
Cloud-based IoT Devices (4G Controllers)
Live Polling Architecture (Auto Refresh Mechanism)

### 🔄 Data Flow Architecture

IoT Device → Cloud Server → REST API → Flutter App → UI State Update

* Devices push telemetry data to cloud server.
* Backend APIs process and expose structured JSON responses.
* Flutter app polls APIs at fixed intervals.
* UI automatically refreshes using custom state management.

---

## ⚙️ Features

### 🔹 Dashboard

* Multi-device monitoring
* Online / Offline detection
* Real-time status refresh
* Fault detection indicators
* Device filter (All / Online / Offline / Fault)
* Visual health indicators with color coding

### 🔹 Device Detail Screen

* Live Voltage (R, Y, B Phase)
* Current Monitoring
* Pump status (Running / Stopped)
* Runtime tracking (Daily & Total)
* RSSI Signal strength indicator
* Health badge system (Normal / Fault / Warning)

### 🔹 Fault Detection System

* Phase Sequence Fault
* Voltage Over/Under Protection
* Dry Run Protection
* System Offline Detection
* Smart health status mapping

### 🔹 Scheduling System

* Timer slot configuration
* Scheduled ON/OFF control
* Manual override detection
* Slot-based pump automation

### 🔹 Alerts System

* Real-time alerts screen
* Event-based tracking
* Fault history tracking
* Timestamp-based logs

### 🔹 Authentication System

* Login / Logout functionality
* Remember Me feature
* Secure credential storage
* Persistent session handling

---

## 🛠 Technologies Used

* Flutter (Dart)
* REST API Integration
* HTTP Package
* Secure Storage
* Custom State Management
* Clean Folder Architecture
* Modular Service Layer
* JSON Serialization
* Polling Timer Management

---

## 📂 Project Structure

```
lib/
│
├── core/        # API client & configuration
├── models/      # Data models
├── screens/     # UI Screens
├── services/    # API services
├── state/       # State management
├── widgets/     # Reusable widgets
└── main.dart    # Entry point
```

### 📦 Folder Explanation

* **core/** → Base URL, API configuration, reusable network logic
* **models/** → Structured data classes for API response parsing
* **services/** → Business logic + API calling layer
* **state/** → App-wide state management
* **widgets/** → Reusable UI components
* **screens/** → All main application pages

---

## 🔐 Security

* API configurations separated
* Sensitive keys excluded via `.gitignore`
* Secure storage implementation for authentication
* Encrypted credential handling
* Session-based login persistence
* Controlled logout behavior (Remember Me support retained)

---

## 📊 Performance Considerations

* Optimized polling interval
* Lightweight UI rebuild strategy
* Conditional state updates
* Efficient JSON parsing
* Scalable device list rendering
* Low memory footprint design

---

## 📱 Applications

* Industrial Pump Monitoring
* Agricultural Automation
* Remote Motor Protection
* Smart Water System Control
* IoT Device Fleet Monitoring
* Borewell Automation Systems
* Factory Motor Health Monitoring

---

## 🧠 Real-World Use Case

Example Scenario:

A farmer installs a 4G-based pump controller in a remote agricultural field.
Using IoT Pump Health Monitoring & Control Platform app:

* He can check voltage health remotely.
* Monitor pump runtime.
* Detect dry run conditions.
* Schedule irrigation timing.
* Receive alerts in case of system fault.
* Avoid motor burn damage due to voltage fluctuation.

This reduces manual effort and increases equipment lifespan.

---

## 🚀 Future Improvements

* WebSocket Live Streaming (Remove polling)
* Push Notifications (Firebase)
* Role-based Authentication (Admin/User)
* Advanced Analytics Dashboard
* Cloud Logging & Monitoring
* Dark Mode Support
* Multi-language support
* Exportable Reports (PDF/Excel)
* Device Grouping & Tagging
* Firmware Update Support (OTA)

---

## 🧪 Testing & Quality

* Manual API testing
* Edge case handling (Null, Offline, Fault)
* UI overflow & responsiveness testing
* Voltage threshold validation
* Error handling & fallback UI

---

## 📈 Scalability Vision

The system is designed to:

* Handle 100+ devices per user
* Expand to web dashboard version
* Integrate with enterprise monitoring systems
* Support multiple controller hardware versions

---

## 👨‍💻 Developed By

**Sainath S Mehtre**
MCA Graduate | Flutter & IoT Application Developer
Industrial IoT Application Specialist

---

## ⭐ Why This Project is Important

This project demonstrates:

* Real-world IoT integration
* Industrial-grade monitoring logic
* Fault detection system
* Clean code architecture
* API handling and live refresh management
* Production-ready dashboard design
* Secure authentication flow
* Scalable system design approach

---

## 📸 Screenshots

![Dashboard](assets/screenshots/dashboard.png)
![Device Detail](assets/screenshots/device_detail.png)

---

## 📜 License

This project is for demonstration and portfolio purposes.

---