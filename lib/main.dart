import 'dart:io';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Attendance',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1565C0),
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F7FB),
      ),
      home: const RoleSelectionPage(),
    );
  }
}

// ============================================================
// ROLE SELECTION PAGE
// ============================================================

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
            ],
          ),
        ),

        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),

              child: Column(
                children: [
                  const SizedBox(height: 40),

                  // APP ICON
                  Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      size: 60,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(height: 25),

                  const Text(
                    'SMART ATTENDANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Face Recognition • Live Location',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 50),

                  // STUDENT LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const LoginPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.person,
                        size: 30,
                      ),
                      label: const Text(
                        'STUDENT LOGIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor:
                        const Color(0xFF1565C0),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ADMIN LOGIN
                  SizedBox(
                    width: double.infinity,
                    height: 65,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                            const AdminLoginPage(),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.admin_panel_settings,
                        size: 30,
                      ),
                      label: const Text(
                        'ADMIN LOGIN',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white,
                          width: 2,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  const Text(
                    'Select your login type',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// LOGIN PAGE
// ============================================================

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});


  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter email and password'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      print('login success');
      print('opening dashboard');
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const StudentDashboard(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed';

      if (e.code == 'user-not-found') {
        message = 'No account found with this email';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password';
      } else if (e.code == 'invalid-credential') {
        message = 'Invalid email or password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1565C0),
              Color(0xFF42A5F5),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // APP ICON
                  Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.face_retouching_natural,
                      size: 55,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // APP NAME
                  const Text(
                    'SMART ATTENDANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Face Recognition • Live Location',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),

                  const SizedBox(height: 35),

                  // LOGIN CARD
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Column(
                      children: [
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Student Login',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Login to mark your attendance',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // EMAIL
                        TextField(
                          controller: emailController,
                          keyboardType:
                          TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: const Icon(
                              Icons.email_outlined,
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 18),

                        // PASSWORD
                        TextField(
                          controller: passwordController,
                          obscureText: hidePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(
                              Icons.lock_outline,
                            ),
                            suffixIcon: IconButton(
                              onPressed: () {
                                setState(() {
                                  hidePassword =
                                  !hidePassword;
                                });
                              },
                              icon: Icon(
                                hidePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(15),
                            ),
                          ),
                        ),

                        const SizedBox(height: 25),

                        // LOGIN BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 55,
                          child: ElevatedButton(
                            onPressed:
                            isLoading ? null : login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                              const Color(0xFF1565C0),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(15),
                              ),
                            ),
                            child: isLoading
                                ? const SizedBox(
                              width: 25,
                              height: 25,
                              child:
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                                : const Text(
                              'LOGIN',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// STUDENT DASHBOARD
// ============================================================

class StudentDashboard extends StatelessWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      // APP BAR
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Smart Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
          actions: [
      IconButton(
      icon: const Icon(Icons.more_vert),
      onPressed: () {
        showMenu(
          context: context,
          position: const RelativeRect.fromLTRB(
            300,
            80,
            10,
            0,
          ),
          items: [
            PopupMenuItem(
              child: const Text('Attendance History'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AttendanceHistoryPage(),
                  ),
                );
              },
            ),
          ],
        );
      },
    ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),

      // BODY
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome back 👋',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              user?.email ?? 'Student',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            // DASHBOARD HEADER
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF42A5F5),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.person,
                      size: 40,
                      color: Color(0xFF1565C0),
                    ),
                  ),

                  SizedBox(width: 18),

                  Expanded(
                    child: Text(
                      'Attendance Dashboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 15),

            // MARK ATTENDANCE
            _actionCard(
              context,
              icon: Icons.face_retouching_natural,
              title: 'Mark Attendance',
              subtitle:
              'Capture face and mark present',
              color: const Color(0xFF1565C0),
              onTap: () async {
                final picker = ImagePicker();

                final photo = await picker.pickImage(
                  source: ImageSource.camera,
                );

                if (photo == null) return;

                if (!context.mounted) return;

                _markAttendance(context, photo);
              },
            ),

            const SizedBox(height: 15),

            // LIVE LOCATION
            _actionCard(
              context,
              icon: Icons.location_on,
              title: 'Live Location',
              subtitle:
              'Check your current location',
              color: const Color(0xFF00897B),
              onTap: () async {
                await _getLocation(context);
              },
            ),

            const SizedBox(height: 15),

            // HISTORY
            _actionCard(
              context,
              icon: Icons.history,
              title: 'Attendance History',
              subtitle:
              'View your previous attendance',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AttendanceHistoryPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 25),

            // SECURITY CARD
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.verified_user,
                    color: Colors.green,
                    size: 30,
                  ),

                  SizedBox(width: 15),

                  Expanded(
                    child: Text(
                      'Your attendance is securely stored.',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // LOGOUT
            Center(
              child: TextButton.icon(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();

                  if (!context.mounted) return;

                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                      const LoginPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // GET LOCATION
  // ==========================================================

  Future<void> _getLocation(
      BuildContext context,
      ) async {
    bool serviceEnabled =
    await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please turn on location services',
          ),
        ),
      );
      return;
    }

    LocationPermission permission =
    await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
      await Geolocator.requestPermission();
    }

    if (permission ==
        LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Location permission denied',
          ),
        ),
      );
      return;
    }

    try {
      final position =
      await Geolocator.getCurrentPosition();

      // Classroom location
      const double classroomLat = 12.734404;
      const double classroomLng = 77.293375;

      double distance = Geolocator.distanceBetween(
        classroomLat,
        classroomLng,
        position.latitude,
        position.longitude,
      );

      if (distance > 50) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'You are not inside the classroom area',
            ),
          ),
        );
        return;
      }

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: Color(0xFF00897B),
                ),
                SizedBox(width: 10),
                Text('Your Location'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'Latitude',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                Text(
                  position.latitude.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 15),

                const Text(
                  'Longitude',
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                Text(
                  position.longitude.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get location: $e',
          ),
        ),
      );
    }
  }

  // ==========================================================
  // MARK ATTENDANCE
  // ==========================================================
  Future<void> _markAttendance(
      BuildContext context,
      XFile photo,
      ) async {
    try {
      // Convert camera photo into ML Kit input image
      final inputImage = InputImage.fromFilePath(photo.path);

      // Create face detector
      final faceDetector = FaceDetector(
        options: FaceDetectorOptions(
          enableContours: false,
          enableLandmarks: false,
          enableClassification: false,
          enableTracking: false,
          minFaceSize: 0.15,
          performanceMode: FaceDetectorMode.accurate,
        ),
      );

      // Detect faces
      final faces = await faceDetector.processImage(inputImage);

      // Close detector
      await faceDetector.close();

      if (!context.mounted) return;

      // No face found
      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'No face detected. Please take a clear face photo.',
            ),
          ),
        );
        return;
      }

      // Face found - show confirmation
      showDialog(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Row(
              children: [
                Icon(
                  Icons.face,
                  color: Color(0xFF1565C0),
                ),
                SizedBox(width: 10),
                Text('Face Detected'),
              ],
            ),
            content: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                File(photo.path),
                height: 250,
                fit: BoxFit.cover,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(dialogContext);

                  try {
                    final user =
                        FirebaseAuth.instance.currentUser;

                    // Check location service
                    final serviceEnabled =
                    await Geolocator.isLocationServiceEnabled();

                    if (!serviceEnabled) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please turn on location services.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Check location permission
                    LocationPermission permission =
                    await Geolocator.checkPermission();

                    if (permission == LocationPermission.denied) {
                      permission =
                      await Geolocator.requestPermission();
                    }

                    if (permission ==
                        LocationPermission.denied ||
                        permission ==
                            LocationPermission.deniedForever) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Location permission denied.',
                          ),
                        ),
                      );
                      return;
                    }

                    // Get current location
                    final position =
                    await Geolocator.getCurrentPosition();

final schedules = await FirebaseFirestore.instance
.collection('class_schedules')
.get();
                    final now = DateTime.now();

                    final currentHour = now.hour;

                    bool classRunning = true;

                    for (final doc in schedules.docs) {
                      final data = doc.data();

                      final startTime = data['startTime'] ?? '';
                      final endTime = data['endTime'] ?? '';

                      if (startTime == '9:00 AM' &&
                          endTime == '10:00 AM') {

                        if (currentHour >= 9 &&
                            currentHour < 10) {
                          classRunning = true;
                        }
                      }
                    }

                    if (!classRunning) {
                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Attendance allowed only during class time',
                          ),
                        ),
                      );
                      return;
                    }
if (schedules.docs.isEmpty) {
if (!context.mounted) return;

ScaffoldMessenger.of(context).showSnackBar(
const SnackBar(
content: Text('No class schedule found'),
),
);
return;
}


                    // Save attendance
                    await FirebaseFirestore.instance
                        .collection('attendance')
                        .add({
                      'userId': user?.uid,
                      'email': user?.email,
                      'date': Timestamp.now(),
                      'status': 'Present',
                      'faceDetected': true,
                      'photoPath': photo.path,
                      'latitude': position.latitude,
                      'longitude': position.longitude,
                    });

                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Face verified. Attendance marked successfully!',
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!context.mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to mark attendance: $e',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Mark Present'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Face detection failed: $e',
          ),
        ),
      );
    }
  }


  // ==========================================================
  // ACTION CARD
  // ==========================================================

  Widget _actionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return InkWell(
      borderRadius:
      BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
          BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color:
                color.withValues(alpha: 0.12),
                borderRadius:
                BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios,
              size: 17,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ATTENDANCE HISTORY
// ============================================================

class AttendanceHistoryPage
    extends StatelessWidget {
  const AttendanceHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user =
        FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor:
      const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor:
        const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Attendance History',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .where(
          'userId',
          isEqualTo: user?.uid,
        )
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding:
                const EdgeInsets.all(20),
                child: Text(
                  'Error: ${snapshot.error}',
                  textAlign:
                  TextAlign.center,
                ),
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 70,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'No attendance records yet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Mark attendance to see it here.',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final records =
              snapshot.data!.docs;

          return ListView.builder(
            padding:
            const EdgeInsets.all(16),
            itemCount: records.length,

            itemBuilder:
                (context, index) {
              final data =
              records[index].data()
              as Map<String, dynamic>;

              final timestamp =
              data['date'] as Timestamp?;

              final date =
              timestamp?.toDate();

              return Card(
                margin:
                const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  leading: const Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 35,
                  ),

                  title: Text(
                    data['status'] ??
                        'Present',
                    style:
                    const TextStyle(
                      fontWeight:
                      FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    date == null
                        ? 'Date not available'
                        : '${date.day}/${date.month}/${date.year} '
                        '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  ),

                  trailing: const Icon(
                    Icons.verified,
                    color: Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ============================================================
// ADMIN LOGIN PAGE
// ============================================================

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> adminLogin() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter admin email and password'),
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      final user = FirebaseAuth.instance.currentUser;

      // Only this email is allowed as admin
      if (user?.email != 'admin@gmail.com') {
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access denied. Admin account only.'),
          ),
        );

        return;
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AdminDashboard(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Admin login failed';

      if (e.code == 'invalid-credential') {
        message = 'Invalid admin email or password';
      } else if (e.code == 'invalid-email') {
        message = 'Invalid email address';
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Login',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 45,
                  backgroundColor: Color(0xFFE3F2FD),
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 50,
                    color: Color(0xFF1565C0),
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Admin Login',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'Login to access administrator features',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 30),

                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Admin Email',
                    prefixIcon: const Icon(
                      Icons.email_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextField(
                  controller: passwordController,
                  obscureText: hidePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(
                      Icons.lock_outline,
                    ),
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          hidePassword = !hidePassword;
                        });
                      },
                      icon: Icon(
                        hidePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : adminLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(
                      color: Colors.white,
                    )
                        : const Text(
                      'ADMIN LOGIN',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
// ============================================================
// ADMIN DASHBOARD
// ============================================================

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Admin Dashboard',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();

              if (!context.mounted) return;

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
              );
            },
          ),
        ],
      ),

        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Admin Panel',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Manage and monitor student attendance',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),

            const SizedBox(height: 25),

            _adminCard(
              context,
              Icons.location_on,
              'Live Locations',
              'View attendance locations',
              const Color(0xFF6A1B9A),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AdminAttendancePage(),
                  ),
                );
              },
            ),
            const SizedBox(height: 15),

            _adminCard(
              context,
              Icons.schedule,
              'Class Schedule',
              'Add and manage class timings',
              const Color(0xFFFF9800),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddSchedulePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _adminCard(
              context,
              Icons.calendar_month,
              'View Schedules',
              'View all saved schedules',
              const Color(0xFF4CAF50),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ViewSchedulesPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),
            _adminCard(
              context,
              Icons.people,
              'Students',
              'View registered students',
              const Color(0xFF1565C0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AdminStudentsPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _adminCard(
              context,
              Icons.fact_check,
              'Attendance Records',
              'View all attendance records',
              const Color(0xFF00897B),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                    const AdminAttendancePage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            _adminCard(
              context,
              Icons.location_on,
              'Live Locations',
              'View attendance locations',
              const Color(0xFF6A1B9A),
            ),
          ],
        ),
      ),
        ),
    );
  }

  Widget _adminCard(
      BuildContext context,
      IconData icon,
      String title,
      String subtitle,
      Color color, {
        VoidCallback? onTap,
      }) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(
              icon,
              color: color,
              size: 30,
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.arrow_forward_ios,
            size: 17,
            color: Colors.grey,
          ),
        ],
      ),
        ),
    );
  }
}

// ============================================================
// ADMIN ATTENDANCE RECORDS
// ============================================================

class AdminAttendancePage extends StatelessWidget {
  const AdminAttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'All Attendance Records',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No attendance records found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final records = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,

            itemBuilder: (context, index) {
              final data =
              records[index].data()
              as Map<String, dynamic>;

              final timestamp =
              data['date'] as Timestamp?;

              final date =
              timestamp?.toDate();

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor:
                    Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),

                  title: Text(
                    data['email'] ?? 'Unknown student',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: Text(
                    date == null
                        ? 'Date not available'
                        : '${date.day}/${date.month}/${date.year} '
                        '${date.hour}:${date.minute.toString().padLeft(2, '0')}',
                  ),

                  trailing: const Text(
                    'Present',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ============================================================
// ADMIN STUDENTS PAGE
// ============================================================

class AdminStudentsPage extends StatelessWidget {
  const AdminStudentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Registered Students',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('attendance')
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData ||
              snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No students found',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            );
          }

          final records = snapshot.data!.docs;

          // Get unique student emails
          final Set<String> students = {};

          for (final record in records) {
            final data =
            record.data() as Map<String, dynamic>;

            final email = data['email'];

            if (email != null) {
              students.add(email.toString());
            }
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: students.length,

            itemBuilder: (context, index) {
              final email = students.elementAt(index);

              return Card(
                margin: const EdgeInsets.only(
                  bottom: 12,
                ),

                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F5E9),
                    child: Icon(
                      Icons.check,
                      color: Colors.green,
                    ),
                  ),

                  title: Text(
                    email,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  subtitle: const Text(
                    'Registered student',
                  ),

                  trailing: const Icon(
                    Icons.verified_user,
                    color: Colors.green,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
// ============================================================
// ADD STUDENT PAGE
// ============================================================

class AddStudentPage extends StatefulWidget {
  const AddStudentPage({super.key});

  @override
  State<AddStudentPage> createState() => _AddStudentPageState();
}

class _AddStudentPageState extends State<AddStudentPage> {
  final nameController = TextEditingController();
  final usnController = TextEditingController();
  final emailController = TextEditingController();
  final departmentController = TextEditingController();
  final semesterController = TextEditingController();
  final sectionController = TextEditingController();
  final collegeController = TextEditingController();

  bool isSaving = false;

  File? studentImage;
  final ImagePicker picker = ImagePicker();

  Future<void> captureStudentPhoto() async {
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
    );

    if (image != null) {
      setState(() {
        studentImage = File(image.path);
      });
    }
  }


  Future<void> saveStudent() async {
    if (nameController.text.trim().isEmpty ||
        usnController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        departmentController.text.trim().isEmpty ||
        semesterController.text.trim().isEmpty ||
        sectionController.text.trim().isEmpty ||
        collegeController.text.trim().isEmpty ||
        studentImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all student details'),
        ),
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    print('step 1');

    try {

      print('step 2');

      await FirebaseFirestore.instance
          .collection('students')
          .doc(usnController.text.trim().toUpperCase())
          .set({
        'studentName': nameController.text.trim(),
        'usn': usnController.text.trim().toUpperCase(),
        'email': emailController.text.trim(),
        'department': departmentController.text.trim(),
        'semester': semesterController.text.trim(),
        'section': sectionController.text.trim(),
        'collegeName': collegeController.text.trim(),
        'photoPath': studentImage?.path ?? '',
        'createdAt': Timestamp.now(),
      });

      print('step 3');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Student added successfully'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add student: $e'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Widget studentField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    usnController.dispose();
    emailController.dispose();
    departmentController.dispose();
    semesterController.dispose();
    sectionController.dispose();
    collegeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text(
          'Add Student',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFFE3F2FD),
              child: Icon(
                Icons.person_add,
                size: 50,
                color: Color(0xFF1565C0),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Student Details',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 25),

            studentField(
              controller: nameController,
              label: 'Student Name',
              icon: Icons.person,
            ),

            studentField(
              controller: usnController,
              label: 'USN',
              icon: Icons.badge,
            ),

            studentField(
              controller: emailController,
              label: 'Email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),

            studentField(
              controller: departmentController,
              label: 'Department',
              icon: Icons.school,
            ),

            studentField(
              controller: semesterController,
              label: 'Semester',
              icon: Icons.menu_book,
              keyboardType: TextInputType.number,
            ),

            studentField(
              controller: sectionController,
              label: 'Section',
              icon: Icons.class_,
            ),

            studentField(
              controller: collegeController,
              label: 'College Name',
              icon: Icons.account_balance,
            ),
            const SizedBox(height: 15),

            studentImage != null
                ? ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.file(
                studentImage!,
                height: 180,
                width: 180,
                fit: BoxFit.cover,
              ),
            )
                : const CircleAvatar(
              radius: 60,
              child: Icon(
                Icons.person,
                size: 60,
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: captureStudentPhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('CAPTURE STUDENT PHOTO'),
              ),
            ),

            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : saveStudent,
                icon: const Icon(Icons.save),
                label: isSaving
                    ? const CircularProgressIndicator(
                  color: Colors.white,
                )
                    : const Text(
                  'SAVE STUDENT',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class AddSchedulePage extends StatefulWidget {
  const AddSchedulePage({super.key});

  @override
  State<AddSchedulePage> createState() => _AddSchedulePageState();
}

class _AddSchedulePageState extends State<AddSchedulePage> {
  final TextEditingController subjectController = TextEditingController();
  final TextEditingController semesterController = TextEditingController();
  final TextEditingController sectionController = TextEditingController();
  final TextEditingController facultyController = TextEditingController();
  final TextEditingController roomController = TextEditingController();

  String? selectedDay;
  TimeOfDay? startTime;
  TimeOfDay? endTime;

  final List<String> days = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Future<void> selectStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        startTime = picked;
      });
    }
  }

  Future<void> selectEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (picked != null) {
      setState(() {
        endTime = picked;
      });
    }
  }

  Future<void> saveSchedule() async {
    if (subjectController.text.trim().isEmpty ||
        semesterController.text.trim().isEmpty ||
        sectionController.text.trim().isEmpty ||
        facultyController.text.trim().isEmpty ||
        roomController.text.trim().isEmpty ||
        selectedDay == null ||
        startTime == null ||
        endTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('class_schedules')
          .add({
        'subject': subjectController.text.trim(),
        'semester': semesterController.text.trim(),
        'section': sectionController.text.trim(),
        'faculty': facultyController.text.trim(),
        'room': roomController.text.trim(),
        'day': selectedDay,
        'startTime': startTime!.format(context),
        'endTime': endTime!.format(context),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule saved successfully'),
        ),
      );

      subjectController.clear();
      semesterController.clear();
      sectionController.clear();
      facultyController.clear();
      roomController.clear();

      setState(() {
        selectedDay = null;
        startTime = null;
        endTime = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Widget customField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    subjectController.dispose();
    semesterController.dispose();
    sectionController.dispose();
    facultyController.dispose();
    roomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        title: const Text('Class Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            customField(
              controller: subjectController,
              label: 'Subject',
              icon: Icons.book,
            ),
            customField(
              controller: semesterController,
              label: 'Semester',
              icon: Icons.school,
            ),
            customField(
              controller: sectionController,
              label: 'Section',
              icon: Icons.class_,
            ),
            customField(
              controller: facultyController,
              label: 'Faculty',
              icon: Icons.person,
            ),
            customField(
              controller: roomController,
              label: 'Room Number',
              icon: Icons.meeting_room,
            ),

            DropdownButtonFormField<String>(
              initialValue: selectedDay,
              decoration: const InputDecoration(
                labelText: 'Day',
                border: OutlineInputBorder(),
              ),
              items: days.map((day) {
                return DropdownMenuItem(
                  value: day,
                  child: Text(day),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedDay = value;
                });
              },
            ),

            const SizedBox(height: 15),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(),
              ),
              title: Text(
                startTime == null
                    ? 'Select Start Time'
                    : startTime!.format(context),
              ),
              trailing: const Icon(Icons.access_time),
              onTap: selectStartTime,
            ),

            const SizedBox(height: 15),

            ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
                side: const BorderSide(),
              ),
              title: Text(
                endTime == null
                    ? 'Select End Time'
                    : endTime!.format(context),
              ),
              trailing: const Icon(Icons.access_time_filled),
              onTap: selectEndTime,
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await saveSchedule();
                },
                icon: const Icon(Icons.save),
                label: const Text(
                  'SAVE SCHEDULE',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ViewSchedulesPage extends StatelessWidget {
  const ViewSchedulesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Schedules'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('class_schedules')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text('No schedules found'),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data =
              docs[index].data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  title: Text(data['subject'] ?? ''),
                  subtitle: Text(
                    'Semester: ${data['semester']}\n'
                        'Section: ${data['section']}\n'
                        'Day: ${data['day']}\n'
                        '${data['startTime']} - ${data['endTime']}\n'
                        'Faculty: ${data['faculty']}\n'
                        'Room: ${data['room']}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}