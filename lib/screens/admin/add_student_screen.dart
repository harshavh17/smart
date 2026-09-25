import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../models/student_model.dart';
import '../../services/firestore_service.dart';
import '../../services/storage_service.dart';
import '../../services/face_detector_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usnController = TextEditingController();
  final _emailController = TextEditingController();
  final _deptController = TextEditingController();
  final _semController = TextEditingController();
  final _secController = TextEditingController();
  final _collegeController = TextEditingController();

  final ImagePicker _picker = ImagePicker();
  final FirestoreService _firestoreService = FirestoreService();
  final StorageService _storageService = StorageService();

  File? _studentImage;
  bool _isSaving = false;
  String _uploadStatus = '';

  @override
  void dispose() {
    _nameController.dispose();
    _usnController.dispose();
    _emailController.dispose();
    _deptController.dispose();
    _semController.dispose();
    _secController.dispose();
    _collegeController.dispose();
    super.dispose();
  }

  Future<void> _pickStudentPhoto(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (image != null) {
        // Verify that the face is detectable in the profile photo
        final faceResult = await FaceDetectorService.processImage(image);
        if (!faceResult.isValid) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(faceResult.errorMessage ?? 'Please upload a clear face portrait.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }

        setState(() {
          _studentImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    if (_studentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or select the student\'s face photo'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _uploadStatus = 'Uploading student photo to Firebase Storage...';
    });

    try {
      final usn = _usnController.text.trim().toUpperCase();

      // 1. Upload student photo to Firebase Storage
      final photoUrl = await _storageService.uploadStudentPhoto(
        _studentImage!,
        usn,
      );

      setState(() => _uploadStatus = 'Saving student details to database...');

      // 2. Save student in Firestore
      final student = StudentModel(
        usn: usn,
        studentName: _nameController.text.trim(),
        email: _emailController.text.trim().toLowerCase(),
        department: _deptController.text.trim(),
        semester: _semController.text.trim(),
        section: _secController.text.trim().toUpperCase(),
        collegeName: _collegeController.text.trim(),
        photoUrl: photoUrl,
        createdAt: DateTime.now(),
      );

      await _firestoreService.saveStudent(student);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Student $usn registered successfully!'),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save student: $e'),
            backgroundColor: AppColors.error,
          ),
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
        title: const Text('Add New Student'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo Upload Card
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: _studentImage != null
                            ? Image.file(_studentImage!, fit: BoxFit.cover)
                            : const Icon(
                                Icons.person_add_alt_1_rounded,
                                size: 54,
                                color: AppColors.primary,
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () => _showPhotoSourceSheet(),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Student Face Portrait',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Form fields
              CustomTextField(
                controller: _nameController,
                label: 'Student Full Name',
                hint: 'e.g. Rahul Sharma',
                prefixIcon: Icons.person_outline_rounded,
                textCapitalization: TextCapitalization.words,
                validator: (v) => v?.trim().isEmpty == true ? 'Enter student name' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _usnController,
                label: 'University Seat Number (USN / ID)',
                hint: 'e.g. 1RV21CS042',
                prefixIcon: Icons.badge_outlined,
                textCapitalization: TextCapitalization.characters,
                validator: (v) => v?.trim().isEmpty == true ? 'Enter USN' : null,
              ),
              const SizedBox(height: 14),

              CustomTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'e.g. rahul@college.edu',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                validator: (v) => (v == null || !v.contains('@')) ? 'Enter valid email' : null,
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _deptController,
                      label: 'Department',
                      hint: 'e.g. CSE, ISE',
                      prefixIcon: Icons.apartment_rounded,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _semController,
                      label: 'Semester',
                      hint: 'e.g. 6',
                      keyboardType: TextInputType.number,
                      prefixIcon: Icons.layers_outlined,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _secController,
                      label: 'Section',
                      hint: 'e.g. A, B',
                      prefixIcon: Icons.group_outlined,
                      textCapitalization: TextCapitalization.characters,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      controller: _collegeController,
                      label: 'College Name',
                      hint: 'e.g. RV College',
                      prefixIcon: Icons.account_balance_outlined,
                      validator: (v) => v?.trim().isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),

              if (_isSaving && _uploadStatus.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  _uploadStatus,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w500),
                ),
              ],

              const SizedBox(height: 28),

              CustomButton(
                text: 'Register & Enroll Student',
                isLoading: _isSaving,
                icon: Icons.check_circle_outline_rounded,
                onPressed: _saveStudent,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Upload Student Face Photo',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStudentPhoto(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: AppColors.primary),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickStudentPhoto(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
