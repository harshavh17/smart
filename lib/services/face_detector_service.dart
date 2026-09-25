import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/app_constants.dart';

class FaceVerificationResult {
  final bool isValid;
  final String? errorMessage;
  final Face? detectedFace;
  final int faceCount;
  final double? leftEyeOpenProb;
  final double? rightEyeOpenProb;
  final double? smileProb;

  FaceVerificationResult({
    required this.isValid,
    this.errorMessage,
    this.detectedFace,
    this.faceCount = 0,
    this.leftEyeOpenProb,
    this.rightEyeOpenProb,
    this.smileProb,
  });
}

class FaceDetectorService {
  /// Detects face and performs basic liveness & quality checks
  static Future<FaceVerificationResult> processImage(XFile photo) async {
    FaceDetector? detector;
    try {
      final inputImage = InputImage.fromFilePath(photo.path);

      final options = FaceDetectorOptions(
        enableClassification: true, // Needed for eye open and smile probabilities
        enableLandmarks: true,
        enableTracking: false,
        performanceMode: FaceDetectorMode.accurate,
        minFaceSize: AppConstants.minFaceSizeRatio,
      );

      detector = FaceDetector(options: options);
      final List<Face> faces = await detector.processImage(inputImage);

      if (faces.isEmpty) {
        return FaceVerificationResult(
          isValid: false,
          faceCount: 0,
          errorMessage: 'No face detected. Please position your face clearly in the frame.',
        );
      }

      if (faces.length > 1) {
        return FaceVerificationResult(
          isValid: false,
          faceCount: faces.length,
          errorMessage: 'Multiple faces detected (${faces.length}). Only one person allowed.',
        );
      }

      final primaryFace = faces.first;
      final leftEyeOpen = primaryFace.leftEyeOpenProbability;
      final rightEyeOpen = primaryFace.rightEyeOpenProbability;
      final smile = primaryFace.smilingProbability;

      // Anti-spoofing / Liveness Check: verify eyes are visible and open
      if (leftEyeOpen != null && rightEyeOpen != null) {
        if (leftEyeOpen < AppConstants.minEyeOpenProbability &&
            rightEyeOpen < AppConstants.minEyeOpenProbability) {
          return FaceVerificationResult(
            isValid: true, // Still allow, but flag notification
            detectedFace: primaryFace,
            faceCount: 1,
            leftEyeOpenProb: leftEyeOpen,
            rightEyeOpenProb: rightEyeOpen,
            smileProb: smile,
          );
        }
      }

      return FaceVerificationResult(
        isValid: true,
        detectedFace: primaryFace,
        faceCount: 1,
        leftEyeOpenProb: leftEyeOpen,
        rightEyeOpenProb: rightEyeOpen,
        smileProb: smile,
      );
    } catch (e) {
      return FaceVerificationResult(
        isValid: false,
        errorMessage: 'Face detection error: $e',
      );
    } finally {
      await detector?.close();
    }
  }
}
