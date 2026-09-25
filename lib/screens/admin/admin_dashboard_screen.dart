import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../models/attendance_model.dart';
import '../../models/schedule_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../auth/role_selection_screen.dart';
import 'admin_students_screen.dart';
import 'admin_attendance_screen.dart';
import 'view_schedules_screen.dart';
import 'admin_analytics_screen.dart';
import 'add_student_screen.dart';
import 'add_schedule_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService authService = AuthService();
    final FirestoreService firestoreService = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Admin Logout'),
                  content: const Text('Do you want to log out of the admin console?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Logout'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await authService.signOut();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Admin Welcome Card
            Container(
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
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.security_rounded, color: AppColors.accent, size: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Administration Console',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'AI Attendance & Biometric Control',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Live Stat Counters Stream
            _buildLiveMetrics(firestoreService),
            const SizedBox(height: 24),

            // Section: Management Portals
            const Text(
              'Management Modules',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 14),

            // 1. Manage Students
            _buildAdminMenuTile(
              context,
              title: 'Student Database',
              subtitle: 'Enroll students, upload face profiles & view directory',
              icon: Icons.people_alt_rounded,
              color: AppColors.primary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminStudentsScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // 2. Attendance Records
            _buildAdminMenuTile(
              context,
              title: 'Attendance Records & Logs',
              subtitle: 'Real-time logs, audit photos, search & filter',
              icon: Icons.fact_check_rounded,
              color: const Color(0xFF0F766E),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAttendanceScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // 3. Class Schedules & Geofencing
            _buildAdminMenuTile(
              context,
              title: 'Class Schedules & Geofencing',
              subtitle: 'Configure class timings, GPS coordinates & radius',
              icon: Icons.schedule_rounded,
              color: const Color(0xFFC2410C),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewSchedulesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),

            // 4. Analytics & Reports
            _buildAdminMenuTile(
              context,
              title: 'Analytics & Shortage Reports',
              subtitle: 'Defaulters list (<75%), subject breakdown & export',
              icon: Icons.bar_chart_rounded,
              color: const Color(0xFF7C3AED),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminAnalyticsScreen()),
                );
              },
            ),

            const SizedBox(height: 24),

            // Quick Create Shortcuts
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddStudentScreen()),
                      );
                    },
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add Student'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AddScheduleScreen()),
                      );
                    },
                    icon: const Icon(Icons.add_alarm_rounded, size: 18),
                    label: const Text('Add Schedule'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMetrics(FirestoreService service) {
    return Row(
      children: [
        // Students Count
        Expanded(
          child: StreamBuilder<List<StudentModel>>(
            stream: service.getStudentsStream(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return _buildCounterCard(
                title: 'Students',
                count: '$count',
                icon: Icons.people_outline_rounded,
                color: AppColors.primary,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // Attendance Count
        Expanded(
          child: StreamBuilder<List<AttendanceModel>>(
            stream: service.getAllAttendanceStream(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return _buildCounterCard(
                title: 'Attendance',
                count: '$count',
                icon: Icons.how_to_reg_rounded,
                color: AppColors.success,
              );
            },
          ),
        ),
        const SizedBox(width: 12),
        // Schedules Count
        Expanded(
          child: StreamBuilder<List<ScheduleModel>>(
            stream: service.getSchedulesStream(),
            builder: (context, snap) {
              final count = snap.data?.length ?? 0;
              return _buildCounterCard(
                title: 'Schedules',
                count: '$count',
                icon: Icons.calendar_today_rounded,
                color: const Color(0xFFC2410C),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCounterCard({
    required String title,
    required String count,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            count,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminMenuTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: AppColors.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
