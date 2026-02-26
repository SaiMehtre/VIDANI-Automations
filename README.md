# vidani_automations

# VIDANI Automations - Smart Pump Monitoring System 🚀

A professional industrial IoT based Pump Monitoring & Protection System built using Flutter.

This application allows real-time monitoring of industrial pump controllers with live status, voltage health, fault detection, runtime tracking, and scheduling support.

---

## 📌 Project Overview

VIDANI Automations is a real-time IoT monitoring mobile application that connects to remote pump controllers and displays:

- Live voltage & current data
- Pump ON/OFF status
- Phase sequence health
- Voltage health monitoring
- Dry run detection
- Runtime tracking
- Device-wise location mapping
- Scheduling control
- Alerts system

This system is designed for industrial and agricultural automation use cases.

---

## 🏗 Architecture

Flutter Frontend  
REST API Backend  
Cloud-based IoT Devices (4G Controllers)  
Live polling architecture  

---

## ⚙️ Features

### 🔹 Dashboard
- Multi-device monitoring
- Online / Offline detection
- Real-time status refresh
- Fault detection indicators

### 🔹 Device Detail Screen
- Live Voltage (R, Y, B)
- Current Monitoring
- Pump status
- Runtime tracking
- RSSI Signal strength

### 🔹 Fault Detection
- Phase Sequence Fault
- Voltage Fault
- Dry Run Protection
- Health Indicators

### 🔹 Scheduling System
- Timer slot configuration
- Manual override detection

### 🔹 Alerts System
- Real-time alerts screen
- Event-based tracking

---

## 🛠 Technologies Used

- Flutter (Dart)
- REST API Integration
- HTTP Package
- State Management (Custom State)
- Clean Folder Architecture
- Modular Service Layer

---

## 📂 Project Structure


lib/
│
├── core/ # API client & configuration
├── models/ # Data models
├── screens/ # UI Screens
├── services/ # API services
├── state/ # State management
├── widgets/ # Reusable widgets
└── main.dart # Entry point


---

## 🔐 Security

- API configurations separated
- Sensitive keys excluded via .gitignore
- Secure storage implementation for authentication

---

## 📱 Applications

- Industrial Pump Monitoring
- Agricultural Automation
- Remote Motor Protection
- Smart Water System Control
- IoT Device Fleet Monitoring

---

## 🚀 Future Improvements

- WebSocket Live Streaming (Remove polling)
- Push Notifications
- Role-based Authentication
- Analytics Dashboard
- Cloud Logging
- Dark Mode Support

---

## 👨‍💻 Developed By

Sainath S Mehtre  
MCA Graduate | Flutter & IoT Application Developer  

---

## ⭐ Why This Project is Important

This project demonstrates:

- Real-world IoT integration
- Industrial-grade monitoring logic
- Fault detection system
- Clean code architecture
- API handling and live refresh management
- Production-ready dashboard design

---

## 📜 License

This project is for demonstration and portfolio purposes.

## 📸 Screenshots

![Dashboard](assets/screenshots/dashboard.png)
![Device Detail](assets/screenshots/device_detail.png)