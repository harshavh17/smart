import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';

class ScheduleModel {
  final String id;
  final String subjectName;
  final String subjectCode;
  final String department;
  final String semester;
  final String section;
  final String startTime; // e.g. "09:00 AM"
  final String endTime;   // e.g. "10:00 AM"
  final String dayOfWeek; // e.g. "Monday", "All Days"
  final String roomNumber;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final DateTime? createdAt;

  ScheduleModel({
    required this.id,
    required this.subjectName,
    required this.subjectCode,
    required this.department,
    required this.semester,
    required this.section,
    required this.startTime,
    required this.endTime,
    this.dayOfWeek = 'All Days',
    this.roomNumber = 'Main Hall',
    this.latitude = AppConstants.defaultCampusLat,
    this.longitude = AppConstants.defaultCampusLng,
    this.radiusMeters = AppConstants.defaultGeofenceRadiusMeters,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'subjectCode': subjectCode.toUpperCase(),
      'department': department,
      'semester': semester,
      'section': section,
      'startTime': startTime,
      'endTime': endTime,
      'dayOfWeek': dayOfWeek,
      'roomNumber': roomNumber,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory ScheduleModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    return ScheduleModel(
      id: doc.id,
      subjectName: (data['subjectName'] ?? '').toString(),
      subjectCode: (data['subjectCode'] ?? '').toString(),
      department: (data['department'] ?? '').toString(),
      semester: (data['semester'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      startTime: (data['startTime'] ?? '').toString(),
      endTime: (data['endTime'] ?? '').toString(),
      dayOfWeek: (data['dayOfWeek'] ?? 'All Days').toString(),
      roomNumber: (data['roomNumber'] ?? 'Main Hall').toString(),
      latitude: (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : AppConstants.defaultCampusLat,
      longitude: (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : AppConstants.defaultCampusLng,
      radiusMeters: (data['radiusMeters'] is num) ? (data['radiusMeters'] as num).toDouble() : AppConstants.defaultGeofenceRadiusMeters,
      createdAt: created,
    );
  }
}
