import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String usn;
  final String studentName;
  final String email;
  final String department;
  final String semester;
  final String section;
  final String collegeName;
  final String photoUrl;
  final DateTime? createdAt;

  StudentModel({
    required this.usn,
    required this.studentName,
    required this.email,
    required this.department,
    required this.semester,
    required this.section,
    required this.collegeName,
    required this.photoUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'usn': usn.toUpperCase(),
      'studentName': studentName,
      'email': email.toLowerCase(),
      'department': department,
      'semester': semester,
      'section': section,
      'collegeName': collegeName,
      'photoUrl': photoUrl,
      'photoPath': photoUrl, // Backward compatibility
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory StudentModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    return StudentModel(
      usn: (data['usn'] ?? doc.id).toString().toUpperCase(),
      studentName: (data['studentName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      department: (data['department'] ?? '').toString(),
      semester: (data['semester'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      collegeName: (data['collegeName'] ?? '').toString(),
      photoUrl: (data['photoUrl'] ?? data['photoPath'] ?? '').toString(),
      createdAt: created,
    );
  }

  factory StudentModel.fromMap(Map<String, dynamic> data, {String? id}) {
    DateTime? created;
    if (data['createdAt'] is Timestamp) {
      created = (data['createdAt'] as Timestamp).toDate();
    }

    return StudentModel(
      usn: (data['usn'] ?? id ?? '').toString().toUpperCase(),
      studentName: (data['studentName'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      department: (data['department'] ?? '').toString(),
      semester: (data['semester'] ?? '').toString(),
      section: (data['section'] ?? '').toString(),
      collegeName: (data['collegeName'] ?? '').toString(),
      photoUrl: (data['photoUrl'] ?? data['photoPath'] ?? '').toString(),
      createdAt: created,
    );
  }
}
