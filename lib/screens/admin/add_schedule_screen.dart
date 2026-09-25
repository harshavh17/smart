import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/time_helper.dart';
import '../../core/utils/location_helper.dart';
import '../../models/schedule_model.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddScheduleScreen extends StatefulWidget {
  const AddScheduleScreen({super.key});

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectNameController = TextEditingController();
  final _subjectCodeController = TextEditingController();
  final _deptController = TextEditingController();
  final _semController = TextEditingController();
  final _secController = TextEditingController();
  final _roomController = TextEditingController();
  final _latController = TextEditingController(text: AppConstants.defaultCampusLat.toString());
  final _lngController = TextEditingController(text: AppConstants.defaultCampusLng.toString());
  final _radiusController = TextEditingController(text: AppConstants.defaultGeofenceRadiusMeters.toStringAsFixed(0));

  final FirestoreService _firestoreService = FirestoreService();

  TimeOfDay _startTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 10, minute: 0);
  String _selectedDay = 'All Days';
  bool _isSaving = false;
  bool _isAcquiringLocation = false;

  final List<String> _daysOfWeek = [
    'All Days',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  @override
  void dispose() {
    _subjectNameController.dispose();
    _subjectCodeController.dispose();
    _deptController.dispose();
    _semController.dispose();
    _secController.dispose();
    _roomController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _radiusController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _acquireCurrentLocation() async {
    setState(() => _isAcquiringLocation = true);

    final res = await LocationHelper.getCurrentLocation();
    if (res.isSuccess && res.position != null) {
      setState(() {
        _latController.text = res.position!.latitude.toStringAsFixed(6);
        _lngController.text = res.position!.longitude.toStringAsFixed(6);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Classroom coordinates set to current location!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res.errorMessage ?? 'Failed to get location'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    if (mounted) {
      setState(() => _isAcquiringLocation = false);
    }
  }

  Future<void> _saveSchedule() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final schedule = ScheduleModel(
        id: '',
        subjectName: _subjectNameController.text.trim(),
        subjectCode: _subjectCodeController.text.trim().toUpperCase(),
        department: _deptController.text.trim().toUpperCase(),
        semester: _semController.text.trim(),
        section: _secController.text.trim().toUpperCase(),
        roomNumber: _roomController.text.trim().isEmpty ? 'Room 101' : _roomController.text.trim(),
        startTime: TimeHelper.formatTimeOfDay(_startTime),
        endTime: TimeHelper.formatTimeOfDay(_endTime),
        dayOfWeek: _selectedDay,
        latitude: double.tryParse(_latController.text.trim()) ?? AppConstants.defaultCampusLat,
        longitude: double.tryParse(_lngController.text.trim()) ?? AppConstants.defaultCampusLng,
        radiusMeters: double.tryParse(_radiusController.text.trim()) ?? AppConstants.defaultGeofenceRadiusMeters,
        createdAt: DateTime.now(),
      );

      await _firestoreService.addSchedule(schedule);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Class schedule added successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save schedule: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Class Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Basic Subject Details
              CustomTextField(
                controller: _subjectNameController,
                label: 'Subject / Course Name',
                hint: 'e.g. Data Structures & Algorithms',
                prefixIcon: Icons.menu_book_rounded,
                validator: (v) => v?.trim().isEmpty == true ? 'Enter subject name' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _subjectCodeController,
                      label: 'Subject Code',
                      hint: 'e.g. 21CS32',
                      prefixIcon: Icons.code_rounded,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _roomController,
                      label: 'Room / Lab',
                      hint: 'e.g. LH-204',
                      prefixIcon: Icons.meeting_room_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _deptController,
                      label: 'Department',
                      hint: 'e.g. CSE',
                      prefixIcon: Icons.apartment_rounded,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _secController,
                      label: 'Section',
                      hint: 'e.g. A',
                      prefixIcon: Icons.group_outlined,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Timing Section
              const Text(
                'Class Timing & Window',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildTimePickerTile(
                      label: 'Start Time',
                      time: _startTime,
                      onTap: () => _pickTime(isStart: true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTimePickerTile(
                      label: 'End Time',
                      time: _endTime,
                      onTap: () => _pickTime(isStart: false),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Classroom Geofence Coordinates
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Campus / Room Geofence',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  TextButton.icon(
                    onPressed: _isAcquiringLocation ? null : _acquireCurrentLocation,
                    icon: _isAcquiringLocation
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.my_location, size: 16),
                    label: const Text('Use Current GPS'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _latController,
                      label: 'Latitude',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _lngController,
                      label: 'Longitude',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.location_on_outlined,
                      validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _radiusController,
                label: 'Allowed Radius (Meters)',
                hint: 'e.g. 150',
                keyboardType: TextInputType.number,
                prefixIcon: Icons.radar_rounded,
                validator: (v) => double.tryParse(v ?? '') == null ? 'Enter valid radius' : null,
              ),

              const SizedBox(height: 32),

              CustomButton(
                text: 'Save Class Schedule',
                isLoading: _isSaving,
                icon: Icons.save_rounded,
                onPressed: _saveSchedule,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimePickerTile({
    required String label,
    required TimeOfDay time,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  TimeHelper.formatTimeOfDay(time),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
