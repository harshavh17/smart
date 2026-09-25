# Smart Attendance - AI Face Biometrics & Geofence Radar Web Platform 🎓🌐

An ultra-modern, responsive enterprise web application for smart automated student attendance tracking using **Webcam Face Biometric Verification**, **GPS Geofencing Radar**, and **Dynamic Schedule Management** backed by **Google Firebase**.

---

## 🌟 Key Features

### 👤 Student Web Portal
- **Live In-Browser Face Recognition**: Captures live camera frames using WebRTC with real-time biometric alignment and liveness checks.
- **GPS Classroom Radar & Geofencing**: Computes distance to classroom coordinates using the HTML5 Geolocation API & Haversine formula (e.g. within 150m radius).
- **Attendance Percentage Tracker**: Visual animated percentage ring with automatic alerts for students below the 75% attendance criteria.
- **Dynamic Lecture Scheduling**: Validates attendance against real-time class periods with automatic On-Time vs. Late tagging and duplicate submission guards.
- **Attendance History & Audit Logs**: Review attendance records with photo snapshots and exact GPS timestamps.

### 🛡️ Faculty & Admin Web Console
- **Student Enrollment Manager**: Register students with USN, department, semester, section, and enrolled biometric portrait photos.
- **Interactive Schedule & Geofence Coordinator**: Configure course schedules, room numbers, and set GPS coordinates directly with a single click ("Use My Location").
- **Live Attendance Feed & Search**: Filter logs by Subject, Date, Status (Present/Late), or search by Student Name/USN.
- **Defaulters Dashboard & CSV Export**: Automatically lists students with <75% attendance and provides one-click CSV export of full attendance logs.

---

## 🛠️ Technology Stack
- **Frontend Core**: Semantic HTML5, Vanilla ES6+ JavaScript Modules
- **Design & UI**: Vanilla CSS3 (CSS Variables, Glassmorphism, Micro-animations, Outfit & Inter Typography)
- **Mapping & Visuals**: Leaflet.js Geofence Radar Maps, FontAwesome 6 Pro Icons
- **Backend & Database**: Firebase Authentication, Cloud Firestore, Firebase Storage (with LocalStorage fallback support)
- **Local Dev Server**: Python 3 `http.server` with CORS enabled / `npx serve`

---

## 🚀 Quick Start Guide

### Running Locally with Python:
```bash
python server.py
```
Open your browser at: `http://localhost:8080`

### Running with Node / NPM:
```bash
npm start
```
or
```bash
npx serve -s . -l 8080
```

---

## 📁 Project Structure

```text
smart_attendance/
├── assets/             # Brand logos, icons, favicons
├── css/
│   └── style.css       # Complete responsive enterprise stylesheet
├── js/
│   ├── app.js          # Master event listeners and navigation controller
│   ├── auth.js         # Authentication, user roles, session management
│   ├── student.js      # Student dashboard, webcam face scanner, GPS geofencing
│   ├── admin.js        # Admin console, student management, schedule coordinator
│   └── firebase-config.js # Firebase modular SDK initialization
├── index.html          # Main single-page application entry point
├── server.py           # Python local server with CORS support
├── package.json        # NPM scripts configuration
└── README.md           # Documentation
```

---

## 🔒 Security & Privacy
- Biometric verification compares live webcam captures with registered portraits.
- GPS validation guarantees student is physically within classroom boundaries.
- Duplicate submission guards prevent multiple check-ins for the same class session.
