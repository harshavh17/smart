import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class ScheduleValidationResult {
  final bool isValidWindow;
  final String status; // 'Present', 'Late', or 'Invalid'
  final String message;
  final int minutesDifference;

  ScheduleValidationResult({
    required this.isValidWindow,
    required this.status,
    required this.message,
    required this.minutesDifference,
  });
}

class TimeHelper {
  /// Parses standard strings like "9:00 AM", "09:30 PM", "14:00" into TimeOfDay
  static TimeOfDay? parseTimeString(String timeStr) {
    if (timeStr.trim().isEmpty) return null;
    final clean = timeStr.trim();

    try {
      // Try 12-hour format e.g. "9:00 AM", "09:00 AM", "9:00 am"
      final format12 = DateFormat('h:mm a');
      final dt = format12.parseLoose(clean);
      return TimeOfDay(hour: dt.hour, minute: dt.minute);
    } catch (_) {
      try {
        // Try 24-hour format e.g. "09:00", "14:30"
        final format24 = DateFormat('HH:mm');
        final dt = format24.parseLoose(clean);
        return TimeOfDay(hour: dt.hour, minute: dt.minute);
      } catch (_) {
        return null;
      }
    }
  }

  /// Formats TimeOfDay to user friendly "09:00 AM" string
  static String formatTimeOfDay(TimeOfDay time, {bool alwaysUse24HourFormat = false}) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    if (alwaysUse24HourFormat) {
      return DateFormat('HH:mm').format(dt);
    }
    return DateFormat('h:mm a').format(dt);
  }

  /// Formats DateTime to friendly date string
  static String formatDate(DateTime dateTime) {
    return DateFormat('EEE, MMM d, yyyy').format(dateTime);
  }

  /// Formats DateTime to friendly time string
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Formats DateTime to full date and time string
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy • h:mm a').format(dateTime);
  }

  /// Checks if current time is within schedule window (with grace period)
  static ScheduleValidationResult validateAttendanceWindow({
    required String startTimeStr,
    required String endTimeStr,
    DateTime? checkTime,
  }) {
    final now = checkTime ?? DateTime.now();
    final startTod = parseTimeString(startTimeStr);
    final endTod = parseTimeString(endTimeStr);

    if (startTod == null || endTod == null) {
      // Fallback: If time format cannot be parsed, allow attendance with a notice
      return ScheduleValidationResult(
        isValidWindow: true,
        status: AppConstants.statusPresent,
        message: 'Schedule time format unverified. Marked present.',
        minutesDifference: 0,
      );
    }

    final startDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      startTod.hour,
      startTod.minute,
    );

    final endDateTime = DateTime(
      now.year,
      now.month,
      now.day,
      endTod.hour,
      endTod.minute,
    );

    // Allowed window starts early (e.g. 15 mins early) and ends at endDateTime
    final earliestAllowed = startDateTime.subtract(
      const Duration(minutes: AppConstants.classEarlyAllowedMinutes),
    );

    if (now.isBefore(earliestAllowed)) {
      final diff = earliestAllowed.difference(now).inMinutes;
      return ScheduleValidationResult(
        isValidWindow: false,
        status: 'Too Early',
        message: 'Class has not started yet. Window opens in $diff min.',
        minutesDifference: diff,
      );
    }

    if (now.isAfter(endDateTime)) {
      return ScheduleValidationResult(
        isValidWindow: false,
        status: 'Class Ended',
        message: 'Class session has already concluded for today.',
        minutesDifference: now.difference(endDateTime).inMinutes,
      );
    }

    // Check if late (more than grace period past start time)
    final lateThreshold = startDateTime.add(
      const Duration(minutes: AppConstants.classLateGraceMinutes),
    );

    if (now.isAfter(lateThreshold)) {
      return ScheduleValidationResult(
        isValidWindow: true,
        status: AppConstants.statusLate,
        message: 'Marked Late (Attended after ${AppConstants.classLateGraceMinutes} min grace period)',
        minutesDifference: now.difference(startDateTime).inMinutes,
      );
    }

    return ScheduleValidationResult(
      isValidWindow: true,
      status: AppConstants.statusPresent,
      message: 'On Time',
      minutesDifference: 0,
    );
  }
}
