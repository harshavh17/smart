import 'package:flutter_test/flutter_test.dart';
import 'package:smart_attendance/main.dart';

void main() {
  testWidgets('SmartAttendanceApp smoke test', (WidgetTester tester) async {
    // Build app widget
    await tester.pumpWidget(const SmartAttendanceApp());
  });
}
