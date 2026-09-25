import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String id;
  final String userId;
  final String email;
  final String usn;
  final String studentName;
  final String subjectName;
  final String status; // 'Present', 'Late', 'Absent'
  final bool faceDetected;
  final String photoUrl;
  final double latitude;
  final double longitude;
  final bool isWithinGeofence;
  final double distanceMeters;
  final DateTime date;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.email,
    required this.usn,
    required this.studentName,
    required this.subjectName,
    required this.status,
    required this.faceDetected,
    required this.photoUrl,
    required this.latitude,
    required this.longitude,
    required this.isWithinGeofence,
    required this.distanceMeters,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'email': email.toLowerCase(),
      'usn': usn.toUpperCase(),
      'studentName': studentName,
      'subjectName': subjectName,
      'status': status,
      'faceDetected': faceDetected,
      'photoUrl': photoUrl,
      'photoPath': photoUrl, // Backward compatibility
      'latitude': latitude,
      'longitude': longitude,
      'isWithinGeofence': isWithinGeofence,
      'distanceMeters': distanceMeters,
      'date': Timestamp.fromDate(date),
    };
  }

  factory AttendanceModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parsedDate = DateTime.now();
    if (data['date'] is Timestamp) {
      parsedDate = (data['date'] as Timestamp).toDate();
    }

    return AttendanceModel(
      id: doc.id,
      userId: (data['userId'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      usn: (data['usn'] ?? '').toString().toUpperCase(),
      studentName: (data['studentName'] ?? '').toString(),
      subjectName: (data['subjectName'] ?? 'General Session').toString(),
      status: (data['status'] ?? 'Present').toString(),
      faceDetected: data['faceDetected'] == true,
      photoUrl: (data['photoUrl'] ?? data['photoPath'] ?? '').toString(),
      latitude: (data['latitude'] is num) ? (data['latitude'] as num).toDouble() : 0.0,
      longitude: (data['longitude'] is num) ? (data['longitude'] as num).toDouble() : 0.0,
      isWithinGeofence: data['isWithinGeofence'] ?? true,
      distanceMeters: (data['distanceMeters'] is num) ? (data['distanceMeters'] as num).toDouble() : 0.0,
      date: parsedDate,
    );
  }
}
