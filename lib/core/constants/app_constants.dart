class AppConstants {
  static const String appName = 'Smart Attendance';
  static const String appVersion = '1.0.0';

  // Default Campus Geofencing (can be overridden by class schedule location)
  // Default coordinates (e.g. Bangalore / Campus default, configurable in Admin Settings)
  static const double defaultCampusLat = 12.9716;
  static const double defaultCampusLng = 77.5946;
  static const double defaultGeofenceRadiusMeters = 200.0; // 200 meters

  // Attendance Grace Windows
  static const int classEarlyAllowedMinutes = 15; // allowed 15 mins before class start
  static const int classLateGraceMinutes = 15; // marked 'Late' if > 15 mins after class start

  // Face Quality & Detection Thresholds
  static const double minFaceSizeRatio = 0.15;
  static const double minEyeOpenProbability = 0.4;
  
  // Storage paths
  static const String storageStudentsFolder = 'student_profiles';
  static const String storageAttendanceFolder = 'attendance_captures';

  // Firestore Collections
  static const String colStudents = 'students';
  static const String colAttendance = 'attendance';
  static const String colSchedules = 'class_schedules';
  static const String colUsers = 'users';

  // Attendance Statuses
  static const String statusPresent = 'Present';
  static const String statusLate = 'Late';
  static const String statusAbsent = 'Absent';

  // Role Constants
  static const String roleAdmin = 'admin';
  static const String roleStudent = 'student';
}
