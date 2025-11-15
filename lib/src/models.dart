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

class PeriodLabel {
  final String s;
  final String e;
  const PeriodLabel(this.s, this.e);
}

class TimetableSchedule {
  final List<PeriodLabel> periods;
  final int densityBucketCount;
  const TimetableSchedule({required this.periods, this.densityBucketCount = 5});
  int get periodCount => periods.length;
}

const List<PeriodLabel> _defaultPeriodLabels = <PeriodLabel>[
  PeriodLabel('08:00', '08:50'),
  PeriodLabel('08:55', '09:45'),
  PeriodLabel('10:15', '11:05'),
  PeriodLabel('11:10', '12:00'),
  PeriodLabel('14:00', '14:50'),
  PeriodLabel('14:55', '15:45'),
  PeriodLabel('16:15', '17:05'),
  PeriodLabel('17:10', '18:00'),
  PeriodLabel('19:00', '19:50'),
  PeriodLabel('19:55', '20:45'),
  PeriodLabel('21:00', '21:50'),
  PeriodLabel('21:55', '22:45'),
];

const TimetableSchedule defaultSchedule = TimetableSchedule(periods: _defaultPeriodLabels, densityBucketCount: 5);
