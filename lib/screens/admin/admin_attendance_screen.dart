import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/time_helper.dart';
import '../../core/utils/location_helper.dart';
import '../../models/attendance_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/stat_badge.dart';
import '../../widgets/empty_state.dart';

class AdminAttendanceScreen extends StatefulWidget {
  const AdminAttendanceScreen({super.key});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All'; // 'All', 'Present', 'Late'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance Records'),
      ),
      body: Column(
        children: [
          // Filter Chips & Search
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by USN, Student Name, or Subject...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) {
                    setState(() => _searchQuery = val.trim().toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildFilterChip('All'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Present'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Late'),
                  ],
                ),
              ],
            ),
          ),

          // Attendance Stream List
          Expanded(
            child: StreamBuilder<List<AttendanceModel>>(
              stream: _firestoreService.getAllAttendanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)),
                  );
                }

                final allRecords = snapshot.data ?? [];
                final filtered = allRecords.where((r) {
                  final matchesFilter = _selectedFilter == 'All' || r.status == _selectedFilter;
                  if (!matchesFilter) return false;

                  if (_searchQuery.isEmpty) return true;

                  return r.studentName.toLowerCase().contains(_searchQuery) ||
                      r.usn.toLowerCase().contains(_searchQuery) ||
                      r.subjectName.toLowerCase().contains(_searchQuery);
                }).toList();

                if (filtered.isEmpty) {
                  return EmptyStateWidget(
                    icon: Icons.event_note_rounded,
                    title: _searchQuery.isEmpty ? 'No Attendance Records Found' : 'No Records Match Search',
                    message: 'Student attendance logs and biometric verification records will appear here.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final record = filtered[index];
                    return _buildRecordTile(record);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _selectedFilter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _selectedFilter = label);
        }
      },
    );
  }

  Widget _buildRecordTile(AttendanceModel record) {
    final photoUrl = record.photoUrl;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Photo
          GestureDetector(
            onTap: () {
              if (photoUrl.isNotEmpty) {
                _showPhotoDialog(photoUrl, record.studentName, record.usn);
              }
            },
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 52,
                height: 52,
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
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        record.studentName,
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
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        record.usn,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        record.subjectName,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  TimeHelper.formatDateTime(record.date),
                  style: const TextStyle(fontSize: 11, color: AppColors.textLight),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    StatBadge.geofenced(isInside: record.isWithinGeofence),
                    const SizedBox(width: 6),
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

  void _showPhotoDialog(String photoUrl, String name, String usn) {
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
                  ? Image.network(photoUrl, fit: BoxFit.cover, height: 300, width: double.infinity)
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(usn, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    ],
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
