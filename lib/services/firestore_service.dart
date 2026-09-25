import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/student_model.dart';
import '../models/attendance_model.dart';
import '../models/schedule_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ============================================================
  // STUDENTS
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _studentsCol =>
      _firestore.collection(AppConstants.colStudents);

  Future<void> saveStudent(StudentModel student) async {
    await _studentsCol.doc(student.usn.toUpperCase()).set(student.toMap());
  }

  Stream<List<StudentModel>> getStudentsStream() {
    return _studentsCol
        .orderBy('studentName')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromFirestore(doc))
            .toList());
  }

  Future<StudentModel?> getStudentByEmail(String email) async {
    final query = await _studentsCol
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      return StudentModel.fromFirestore(query.docs.first);
    }
    return null;
  }

  Future<StudentModel?> getStudentByUsn(String usn) async {
    final doc = await _studentsCol.doc(usn.trim().toUpperCase()).get();
    if (doc.exists) {
      return StudentModel.fromFirestore(doc);
    }
    return null;
  }

  Future<void> deleteStudent(String usn) async {
    await _studentsCol.doc(usn.toUpperCase()).delete();
  }

  // ============================================================
  // SCHEDULES
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _schedulesCol =>
      _firestore.collection(AppConstants.colSchedules);

  Future<void> addSchedule(ScheduleModel schedule) async {
    if (schedule.id.isNotEmpty) {
      await _schedulesCol.doc(schedule.id).set(schedule.toMap());
    } else {
      await _schedulesCol.add(schedule.toMap());
    }
  }

  Stream<List<ScheduleModel>> getSchedulesStream() {
    return _schedulesCol.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => ScheduleModel.fromFirestore(doc))
        .toList());
  }

  Future<List<ScheduleModel>> getAllSchedules() async {
    final snap = await _schedulesCol.get();
    return snap.docs.map((doc) => ScheduleModel.fromFirestore(doc)).toList();
  }

  Future<void> deleteSchedule(String id) async {
    await _schedulesCol.doc(id).delete();
  }

  // ============================================================
  // ATTENDANCE
  // ============================================================

  CollectionReference<Map<String, dynamic>> get _attendanceCol =>
      _firestore.collection(AppConstants.colAttendance);

  /// Check if student has already marked attendance for this subject/day
  Future<bool> hasAlreadyMarkedToday({
    required String usn,
    String? subjectName,
  }) async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day, 0, 0, 0);
    final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

    Query<Map<String, dynamic>> query = _attendanceCol
        .where('usn', isEqualTo: usn.toUpperCase())
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay));

    if (subjectName != null && subjectName.isNotEmpty) {
      query = query.where('subjectName', isEqualTo: subjectName);
    }

    final snap = await query.limit(1).get();
    return snap.docs.isNotEmpty;
  }

  /// Mark attendance record
  Future<void> markAttendance(AttendanceModel attendance) async {
    await _attendanceCol.add(attendance.toMap());
  }

  /// Stream attendance for a specific student (by email or usn)
  Stream<List<AttendanceModel>> getStudentAttendanceStream({
    String? email,
    String? usn,
  }) {
    Query<Map<String, dynamic>> query = _attendanceCol.orderBy('date', descending: true);

    if (usn != null && usn.isNotEmpty) {
      query = _attendanceCol
          .where('usn', isEqualTo: usn.toUpperCase())
          .orderBy('date', descending: true);
    } else if (email != null && email.isNotEmpty) {
      query = _attendanceCol
          .where('email', isEqualTo: email.toLowerCase())
          .orderBy('date', descending: true);
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => AttendanceModel.fromFirestore(doc))
        .toList());
  }

  /// Stream all attendance records
  Stream<List<AttendanceModel>> getAllAttendanceStream() {
    return _attendanceCol
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromFirestore(doc))
            .toList());
  }

  /// Delete attendance record
  Future<void> deleteAttendance(String id) async {
    await _attendanceCol.doc(id).delete();
  }
}
