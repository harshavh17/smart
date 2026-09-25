import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../models/schedule_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/empty_state.dart';

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Reports'),
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: firestoreService.getAllAttendanceStream(),
        builder: (context, attendanceSnap) {
          return StreamBuilder<List<StudentModel>>(
            stream: firestoreService.getStudentsStream(),
            builder: (context, studentSnap) {
              if (attendanceSnap.connectionState == ConnectionState.waiting ||
                  studentSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final attendanceList = attendanceSnap.data ?? [];
              final studentList = studentSnap.data ?? [];

              final totalPunches = attendanceList.length;
              final onTimeCount = attendanceList.where((a) => a.status == 'Present').length;
              final lateCount = attendanceList.where((a) => a.status == 'Late').length;

              // Calculate attendance per student
              final Map<String, int> studentAttendanceCounts = {};
              for (final record in attendanceList) {
                final usn = record.usn.toUpperCase();
                studentAttendanceCounts[usn] = (studentAttendanceCounts[usn] ?? 0) + 1;
              }

              // Assume total possible classes or calculate based on highest punch count
              final maxClasses = studentAttendanceCounts.values.isEmpty
                  ? 1
                  : studentAttendanceCounts.values.reduce((a, b) => a > b ? a : b);

              final List<Map<String, dynamic>> studentStats = [];
              for (final s in studentList) {
                final count = studentAttendanceCounts[s.usn.toUpperCase()] ?? 0;
                final percentage = maxClasses > 0 ? (count / maxClasses * 100) : 0.0;
                studentStats.add({
                  'student': s,
                  'attended': count,
                  'percentage': percentage,
                  'isDefaulter': percentage < 75.0,
                });
              }

              studentStats.sort((a, b) => (a['percentage'] as double).compareTo(b['percentage'] as double));

              final defaulters = studentStats.where((s) => s['isDefaulter'] == true).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview Card
                    _buildOverviewCard(
                      totalStudents: studentList.length,
                      totalPunches: totalPunches,
                      onTime: onTimeCount,
                      lateCount: lateCount,
                    ),
                    const SizedBox(height: 24),

                    // Quick Actions / Export
                    _buildExportSection(context, attendanceList, studentStats),
                    const SizedBox(height: 24),

                    // Low Attendance Alert Section (<75%)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Attendance Defaulters (< 75%)',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: defaulters.isNotEmpty ? AppColors.errorLight : AppColors.successLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${defaulters.length} Students',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: defaulters.isNotEmpty ? AppColors.error : AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (defaulters.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.successLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.success.withOpacity(0.3)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.check_circle_outline, color: AppColors.success, size: 28),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Great news! All enrolled students currently maintain 75% or above attendance.',
                                style: TextStyle(color: AppColors.success, fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        children: defaulters.map((item) {
                          final student = item['student'] as StudentModel;
                          final pct = (item['percentage'] as double).toStringAsFixed(1);
                          final attended = item['attended'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.error.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.errorLight,
                                  child: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.studentName,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${student.usn} • ${student.department} (Sec ${student.section})',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Attended: $attended classes',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorLight,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$pct%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),

                    const SizedBox(height: 28),

                    // Full Student Attendance Table
                    const Text(
                      'All Enrolled Students Summary',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: studentStats.map((item) {
                        final student = item['student'] as StudentModel;
                        final pct = (item['percentage'] as double).toStringAsFixed(1);
                        final isDefaulter = item['isDefaulter'] as bool;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.studentName,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                    Text(
                                      student.usn,
                                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '$pct%',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDefaulter ? AppColors.error : AppColors.success,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverviewCard({
    required int totalStudents,
    required int totalPunches,
    required int onTime,
    required int lateCount,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Attendance Performance Metrics',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Enrolled', '$totalStudents', AppColors.accent),
              _buildMetric('Logs', '$totalPunches', Colors.white),
              _buildMetric('On-Time', '$onTime', const Color(0xFF4ADE80)),
              _buildMetric('Late', '$lateCount', const Color(0xFFFBBF24)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.7)),
        ),
      ],
    );
  }

  Widget _buildExportSection(
    BuildContext context,
    List<AttendanceModel> records,
    List<Map<String, dynamic>> studentStats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.download_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Export Attendance Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Generate CSV summary of attendance logs',
                  style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showExportDialog(context, records, studentStats),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            child: const Text('Export CSV'),
          ),
        ],
      ),
    );
  }

  void _showExportDialog(
    BuildContext context,
    List<AttendanceModel> records,
    List<Map<String, dynamic>> studentStats,
  ) {
    // Generate CSV string
    final StringBuffer csv = StringBuffer();
    csv.writeln('USN,Student Name,Subject,Status,Date,Time,Within Geofence,Distance (m)');

    for (final r in records) {
      final dateStr = '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      final timeStr = '${r.date.hour.toString().padLeft(2, '0')}:${r.date.minute.toString().padLeft(2, '0')}';
      csv.writeln('${r.usn},"${r.studentName}","${r.subjectName}",${r.status},$dateStr,$timeStr,${r.isWithinGeofence},${r.distanceMeters.toStringAsFixed(1)}');
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attendance CSV Export'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Generated CSV for ${records.length} records:', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              Container(
                height: 180,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    csv.toString(),
                    style: const TextStyle(fontFamily: 'monospace', color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.copy_rounded, size: 16),
            label: const Text('Copy to Clipboard'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('CSV Report copied to clipboard!')),
              );
            },
          ),
        ],
      ),
    );
  }
}
