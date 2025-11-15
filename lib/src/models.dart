import 'package:flutter/material.dart';

class TimetableCourse {
  final String title;
  final String? teacher;
  final String? location;
  final int weekday;
  final int startPeriod;
  final int duration;
  final List<int> weeks;
  final String? description;
  final Color? color;

  const TimetableCourse({
    required this.title,
    this.teacher,
    this.location,
    required this.weekday,
    required this.startPeriod,
    required this.duration,
    required this.weeks,
    this.description,
    this.color,
  });

  int get endPeriod => startPeriod + duration - 1;
  bool occursOnWeek(int week) => weeks.contains(week);
}

class TimetableCourseTapDetails {
  final TimetableCourse course;
  final int displayWeek;
  const TimetableCourseTapDetails(this.course, this.displayWeek);
}

const List<Map<String, String>> periodTimes = [
  {'s': '08:00', 'e': '08:50'},
  {'s': '08:55', 'e': '09:45'},
  {'s': '10:15', 'e': '11:05'},
  {'s': '11:10', 'e': '12:00'},
  {'s': '14:00', 'e': '14:50'},
  {'s': '14:55', 'e': '15:45'},
  {'s': '16:15', 'e': '17:05'},
  {'s': '17:10', 'e': '18:00'},
  {'s': '19:00', 'e': '19:50'},
  {'s': '19:55', 'e': '20:45'},
  {'s': '21:00', 'e': '21:50'},
  {'s': '21:55', 'e': '22:45'},
];
