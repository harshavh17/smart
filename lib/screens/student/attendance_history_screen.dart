import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_helper.dart';
import '../../core/utils/location_helper.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/empty_state.dart';

class AttendanceHistoryScreen extends StatelessWidget {
  final StudentModel? student;

  const AttendanceHistoryScreen({super.key, this.student});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirestoreService firestoreService = FirestoreService();
    final user = authService.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Attendance History'),
      ),
      body: StreamBuilder<List<AttendanceModel>>(
        stream: firestoreService.getStudentAttendanceStream(
          email: user?.email,
          usn: student?.usn,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading history: ${snapshot.error}',
                style: const TextStyle(color: AppColors.error),
              ),
            );
          }

          final records = snapshot.data ?? [];

          if (records.isEmpty) {
            return const EmptyStateWidget(
              icon: Icons.history_toggle_off_rounded,
              title: 'No Attendance Records Yet',
              message: 'Your attendance history will appear here once you mark attendance for classes.',
            );
          }

          final presentCount = records.where((r) => r.status == 'Present').length;
          final lateCount = records.where((r) => r.status == 'Late').length;
          final totalCount = records.length;
          final percentage = totalCount > 0 ? ((presentCount + lateCount) / totalCount * 100).toStringAsFixed(1) : '0';

          return CustomScrollView(
            slivers: [
              // Summary Banner Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.2),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Overall Attendance',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '$percentage%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: double.parse(percentage) >= 75.0
                                    ? Colors.white.withOpacity(0.25)
                                    : AppColors.error,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                double.parse(percentage) >= 75.0 ? 'Eligible (≥ 75%)' : 'Shortage Alert (< 75%)',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(color: Colors.white24, height: 1),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatColumn('Total Classes', '$totalCount'),
                            _buildStatColumn('On-Time', '$presentCount'),
                            _buildStatColumn('Late', '$lateCount'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title Section
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Attendance Logs',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),

              // List of Attendance Cards
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final record = records[index];
                      return _buildAttendanceCard(context, record);
                    },
                    childCount: records.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatColumn(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceCard(BuildContext context, AttendanceModel record) {
    final photoUrl = record.photoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo thumbnail or Avatar
          GestureDetector(
            onTap: () {
              if (photoUrl.isNotEmpty) {
                _showPhotoDialog(context, photoUrl, record.studentName);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 54,
                height: 54,
                color: AppColors.primaryLight.withOpacity(0.15),
                child: (photoUrl.isNotEmpty && (photoUrl.startsWith('http') || photoUrl.startsWith('https')))
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.face_rounded, color: AppColors.primary),
                      )
                    : const Icon(Icons.face_rounded, color: AppColors.primary, size: 28),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.subjectName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (record.status == 'Present')
                      StatBadge.present()
                    else if (record.status == 'Late')
                      StatBadge.late()
                    else
                      StatBadge.absent(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  TimeHelper.formatDateTime(record.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    StatBadge.geofenced(isInside: record.isWithinGeofence),
                    const SizedBox(width: 8),
                    if (record.distanceMeters > 0)
                      Text(
                        '(${LocationHelper.formatDistance(record.distanceMeters)})',
                        style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPhotoDialog(BuildContext context, String photoUrl, String studentName) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: (photoUrl.startsWith('http') || photoUrl.startsWith('https'))
                  ? Image.network(photoUrl, fit: BoxFit.cover, height: 280, width: double.infinity)
                  : Container(
                      height: 200,
                      color: AppColors.background,
                      child: const Center(child: Icon(Icons.broken_image, size: 48)),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Audit Photo: $studentName',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
