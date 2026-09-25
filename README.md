# Smart Attendance System 🎓📍📸

An AI-powered Flutter application that automates student attendance tracking using **Facial Biometric Verification**, **GPS Geofencing**, and **Real-Time Class Scheduling** backed by **Google Firebase**.

---

## 🌟 Key Features

### 👤 Student Portal
- **AI Face Biometric Verification**: Live face detection and anti-spoofing checks powered by Google ML Kit.
- **GPS Campus Geofencing**: Computes real-time GPS distance to classroom/campus coordinates to verify physical presence.
- **Dynamic Class Schedules**: Attendance window validation with early allowance and grace periods (On-Time vs. Late tracking).
- **Attendance History & Analytics**: Real-time percentage tracker with low-attendance warnings (< 75% threshold).
- **Cloud Audit Logs**: Timestamped attendance photos securely uploaded to Firebase Storage.

### 🛡️ Admin & Faculty Portal
- **Student Enrollment**: Register students with USN, department, section, and enrolled biometric portrait photos.
- **Class Scheduling & Geofencing**: Configure class timings, room numbers, and custom GPS coordinates with adjustable radius thresholds.
- **Real-Time Attendance Monitoring**: Search and filter attendance logs by student, USN, status (Present/Late), and date.
- **Analytics & Shortage Defaulters Report**: Automatic detection of students below 75% attendance with one-click **CSV Report Export**.

---

## 🏗️ Architecture & Folder Structure

```text
lib/
├── core/
│   ├── constants/       # AppColors, AppConstants, geofence & status definitions
│   ├── theme/           # Modern Material 3 light theme & styling
│   └── utils/           # LocationHelper (GPS & Geofencing) & TimeHelper (schedule validation)
├── models/              # StudentModel, AttendanceModel, ScheduleModel
├── services/            # AuthService, FirestoreService, StorageService, FaceDetectorService
├── screens/
│   ├── auth/            # RoleSelection, StudentLogin, AdminLogin
│   ├── student/         # StudentDashboard, MarkAttendance, AttendanceHistory
│   └── admin/           # AdminDashboard, AdminStudents, AddStudent, AddSchedule, ViewSchedules, AdminAnalytics
├── widgets/             # CustomButton, CustomTextField, StatBadge, EmptyStateWidget
├── firebase_options.dart # Firebase configuration
└── main.dart            # Clean application entrypoint
```

---

## 🚀 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.13.0 or higher)
- Firebase Project configured for Android, iOS, or Web

### Setup & Run
1. **Clone the repository:**
   ```bash
   git clone https://github.com/harshavh17/smart.git
   cd smart
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on connected device / emulator:**
   ```bash
   flutter run
   ```

---

## 🔒 Security & Best Practices
- **Cloud Storage**: Photos are stored in Firebase Storage (`student_profiles/` and `attendance_captures/`) rather than local file paths.
- **Anti-Spoofing / Liveness**: Validates eye openness and single face presence before attendance submission.
- **Duplicate Prevention**: Rejects duplicate attendance submissions for the same student, subject, and day.
