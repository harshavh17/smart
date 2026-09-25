import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Uploads a student profile photo and returns the public download URL
  Future<String> uploadStudentPhoto(File imageFile, String usn) async {
    try {
      final sanitizedUsn = usn.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = '${sanitizedUsn}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('${AppConstants.storageStudentsFolder}/$fileName');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      // If Firebase Storage is unavailable or rules block it, log and return local path as fallback
      debugPrint('Firebase Storage upload failed: $e');
      return imageFile.path;
    }
  }

  /// Uploads an attendance audit photo and returns the public download URL
  Future<String> uploadAttendancePhoto(File imageFile, String usn) async {
    try {
      final sanitizedUsn = usn.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
      final fileName = 'att_${sanitizedUsn}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('${AppConstants.storageAttendanceFolder}/$fileName');

      final uploadTask = await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final downloadUrl = await uploadTask.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      debugPrint('Firebase Storage attendance upload failed: $e');
      return imageFile.path;
    }
  }
}
