import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/location_helper.dart';
import '../../core/utils/time_helper.dart';
import '../../models/student_model.dart';
import '../../models/schedule_model.dart';
import '../../models/attendance_model.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/face_detector_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/stat_badge.dart';

class MarkAttendanceScreen extends StatefulWidget {
  final StudentModel? student;

  const MarkAttendanceScreen({super.key, this.student});

  @override
  State<MarkAttendanceScreen> createState() => _MarkAttendanceScreenState();
}

class _MarkAttendanceScreenState extends State<MarkAttendanceScreen> {
  final ImagePicker _picker = ImagePicker();
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  List<ScheduleModel> _schedules = [];
  ScheduleModel? _selectedSchedule;
  bool _isLoadingSchedules = true;

  File? _capturedImage;
  bool _isProcessing = false;
  String _statusText = 'Select your class and capture your face to verify';

  Position? _currentPosition;
  double _distanceToClassroom = 0.0;
  bool _isInsideGeofence = false;

  @override
  void initState() {
    super.initState();
    _loadSchedules();
  }

  Future<void> _loadSchedules() async {
    try {
      final schedules = await _firestoreService.getAllSchedules();
      ScheduleModel? autoSelected;

      // Find if there is an active class right now
      for (final s in schedules) {
        final val = TimeHelper.validateAttendanceWindow(
          startTimeStr: s.startTime,
          endTimeStr: s.endTime,
        );
        if (val.isValidWindow) {
          autoSelected = s;
          break;
        }
      }

      if (mounted) {
        setState(() {
          _schedules = schedules;
          _selectedSchedule = autoSelected ?? (schedules.isNotEmpty ? schedules.first : null);
          _isLoadingSchedules = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingSchedules = false);
      }
    }
  }

  Future<void> _captureAndVerify() async {
    if (_selectedSchedule == null && _schedules.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a subject / class schedule'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _statusText = 'Opening Camera...';
    });

    try {
      // 1. Capture photo with front camera
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
      );

      if (photo == null) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Capture cancelled. Tap button to try again.';
        });
        return;
      }

      setState(() {
        _capturedImage = File(photo.path);
        _statusText = 'Detecting and verifying face with AI...';
      });

      // 2. Face Detection & Liveness Check
      final faceResult = await FaceDetectorService.processImage(photo);

      if (!faceResult.isValid) {
        if (!mounted) return;
        _showErrorDialog(
          title: 'Face Verification Failed',
          message: faceResult.errorMessage ?? 'No valid face detected. Make sure your face is clearly visible.',
        );
        setState(() {
          _isProcessing = false;
          _statusText = 'Face not detected. Please try again in good lighting.';
        });
        return;
      }

      // 3. Location & Campus Geofencing Check
      setState(() => _statusText = 'Verifying campus GPS location...');
      final locationResult = await LocationHelper.getCurrentLocation();

      if (!locationResult.isSuccess || locationResult.position == null) {
        if (!mounted) return;
        _showErrorDialog(
          title: 'Location Error',
          message: locationResult.errorMessage ?? 'Unable to acquire GPS location.',
        );
        setState(() {
          _isProcessing = false;
          _statusText = 'Location check failed. Please ensure GPS is turned on.';
        });
        return;
      }

      final pos = locationResult.position!;
      _currentPosition = pos;

      // Target geofence from schedule (or default campus)
      final targetLat = _selectedSchedule?.latitude ?? AppConstants.defaultCampusLat;
      final targetLng = _selectedSchedule?.longitude ?? AppConstants.defaultCampusLng;
      final allowedRadius = _selectedSchedule?.radiusMeters ?? AppConstants.defaultGeofenceRadiusMeters;

      _distanceToClassroom = LocationHelper.calculateDistanceInMeters(
        userLat: pos.latitude,
        userLng: pos.longitude,
        targetLat: targetLat,
        targetLng: targetLng,
      );

      _isInsideGeofence = _distanceToClassroom <= allowedRadius;

      // 4. Time Window Check
      ScheduleValidationResult timeValidation = ScheduleValidationResult(
        isValidWindow: true,
        status: AppConstants.statusPresent,
        message: 'On Time',
        minutesDifference: 0,
      );

      if (_selectedSchedule != null) {
        timeValidation = TimeHelper.validateAttendanceWindow(
          startTimeStr: _selectedSchedule!.startTime,
          endTimeStr: _selectedSchedule!.endTime,
        );

        if (!timeValidation.isValidWindow) {
          if (!mounted) return;
          _showErrorDialog(
            title: 'Outside Class Schedule',
            message: '${timeValidation.message}\nClass time: ${_selectedSchedule!.startTime} - ${_selectedSchedule!.endTime}',
          );
          setState(() {
            _isProcessing = false;
            _statusText = 'Class is not currently active.';
          });
          return;
        }
      }

      // 5. Duplicate Check
      final user = _authService.currentUser;
      final usn = widget.student?.usn ?? user?.email?.split('@').first ?? 'STUDENT';
      final subject = _selectedSchedule?.subjectName ?? 'General Session';

      final alreadyMarked = await _firestoreService.hasAlreadyMarkedToday(
        usn: usn,
        subjectName: subject,
      );

      if (alreadyMarked) {
        if (!mounted) return;
        _showErrorDialog(
          title: 'Already Marked',
          message: 'You have already marked attendance for $subject today.',
        );
        setState(() {
          _isProcessing = false;
          _statusText = 'Attendance already recorded for today.';
        });
        return;
      }

      // 6. Show Confirmation Dialog before saving
      if (!mounted) return;
      _showConfirmationDialog(
        photo: photo,
        usn: usn,
        subject: subject,
        timeStatus: timeValidation.status,
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          title: 'Verification Error',
          message: 'An unexpected error occurred: $e',
        );
        setState(() {
          _isProcessing = false;
          _statusText = 'Verification failed: $e';
        });
      }
    }
  }

  void _showConfirmationDialog({
    required XFile photo,
    required String usn,
    required String subject,
    required String timeStatus,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.verified_rounded, color: AppColors.success),
            SizedBox(width: 8),
            Text('Face & Location Verified'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.file(
                File(photo.path),
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
            _buildDialogRow('Subject:', subject),
            _buildDialogRow('Student USN:', usn),
            _buildDialogRow('Status:', timeStatus),
            _buildDialogRow('Campus Distance:', LocationHelper.formatDistance(_distanceToClassroom)),
            const SizedBox(height: 8),
            if (!_isInsideGeofence)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warningLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Note: Distance exceeds standard campus radius.',
                        style: TextStyle(fontSize: 11, color: AppColors.warning),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _isProcessing = false;
                _statusText = 'Cancelled. Tap below to capture again.';
              });
            },
            child: const Text('Retake'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await _submitAttendance(
                photo: photo,
                usn: usn,
                subject: subject,
                status: timeStatus,
              );
            },
            child: const Text('Confirm & Submit'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  Future<void> _submitAttendance({
    required XFile photo,
    required String usn,
    required String subject,
    required String status,
  }) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'Uploading photo to secure cloud storage...';
    });

    try {
      final user = _authService.currentUser;

      // Upload photo to Firebase Storage
      final photoUrl = await _storageService.uploadAttendancePhoto(
        File(photo.path),
        usn,
      );

      setState(() => _statusText = 'Recording attendance in database...');

      final record = AttendanceModel(
        id: '',
        userId: user?.uid ?? '',
        email: user?.email ?? widget.student?.email ?? '',
        usn: usn,
        studentName: widget.student?.studentName ?? user?.email?.split('@').first ?? 'Student',
        subjectName: subject,
        status: status,
        faceDetected: true,
        photoUrl: photoUrl,
        latitude: _currentPosition?.latitude ?? 0.0,
        longitude: _currentPosition?.longitude ?? 0.0,
        isWithinGeofence: _isInsideGeofence,
        distanceMeters: _distanceToClassroom,
        date: DateTime.now(),
      );

      await _firestoreService.markAttendance(record);

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 60),
          title: const Text('Attendance Recorded!'),
          content: Text(
            'Your attendance for $subject has been verified and saved successfully with status: $status.',
            textAlign: TextAlign.center,
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx); // Close dialog
                Navigator.pop(context); // Go back to dashboard
              },
              child: const Text('Back to Dashboard'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(
          title: 'Submission Failed',
          message: 'Could not record attendance: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _statusText = 'Ready for attendance';
        });
      }
    }
  }

  void _showErrorDialog({required String title, required String message}) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 48),
        title: Text(title),
        content: Text(message),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mark Attendance'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Subject Selection Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Class / Subject',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (_isLoadingSchedules)
                      const LinearProgressIndicator()
                    else if (_schedules.isEmpty)
                      const Text(
                        'No class schedules created by admin. Defaulting to General Session.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      )
                    else
                      DropdownButtonFormField<ScheduleModel>(
                        value: _selectedSchedule,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        ),
                        items: _schedules.map((schedule) {
                          return DropdownMenuItem(
                            value: schedule,
                            child: Text(
                              '${schedule.subjectName} (${schedule.startTime} - ${schedule.endTime})',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() => _selectedSchedule = val);
                        },
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Camera Preview / Frame Guide
              Container(
                height: 320,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _capturedImage != null ? AppColors.success : AppColors.primary.withOpacity(0.3),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: _capturedImage != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_capturedImage!, fit: BoxFit.cover),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.2),
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.6),
                                  ],
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 16,
                              left: 16,
                              right: 16,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  StatBadge.present(),
                                  const SizedBox(width: 8),
                                  if (_distanceToClassroom > 0)
                                    StatBadge.geofenced(isInside: _isInsideGeofence),
                                ],
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 140,
                                height: 180,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.primary.withOpacity(0.5),
                                    width: 2.5,
                                  ),
                                  borderRadius: BorderRadius.circular(100),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.face_retouching_natural_rounded,
                                    size: 64,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Align face within oval',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Ensure bright lighting and open eyes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              // Status indicator
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.infoLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    if (_isProcessing)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(Icons.info_rounded, color: AppColors.info, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Capture Button
              CustomButton(
                text: _isProcessing ? 'Verifying...' : (_capturedImage == null ? 'Capture & Mark Attendance' : 'Retake Face Photo'),
                isLoading: _isProcessing,
                icon: Icons.camera_alt_rounded,
                onPressed: _isProcessing ? null : _captureAndVerify,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
