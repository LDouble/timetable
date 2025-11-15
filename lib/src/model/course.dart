import 'dart:collection';

import 'package:flutter/material.dart';

/// 描述单个课程（节次+周次+展示信息）。
class TimetableCourse {
  TimetableCourse({
    required this.title,
    required this.weekday,
    required this.startPeriod,
    required this.duration,
    required List<int> weeks,
    this.location,
    this.teacher,
    this.description,
    this.color,
    this.extra,
  })  : assert(weekday >= 1 && weekday <= 7, 'weekday expects [1, 7]'),
        assert(startPeriod >= 1, 'startPeriod is 1-based'),
        assert(duration >= 1, 'duration must be positive'),
        weeks = UnmodifiableListView<int>(List<int>.from(weeks)..sort());

  /// 课程名
  final String title;

  /// 授课教师/讲师
  final String? teacher;

  /// 教室/地点
  final String? location;

  /// 额外描述：如课程类型、备注
  final String? description;

  /// 上课星期（1=周一，7=周日）
  final int weekday;

  /// 开始节次（1-based）
  final int startPeriod;

  /// 持续节数
  final int duration;

  /// 开课周：1-based，必须至少包含一周
  final UnmodifiableListView<int> weeks;

  /// 自定义颜色（不提供时将按标题映射默认调色板）
  final Color? color;

  /// 扩展字段，方便业务注入自定义数据
  final Map<String, dynamic>? extra;

  /// 最后一节课的节次（含）
  int get endPeriod => startPeriod + duration - 1;

  /// 判断是否在指定周（1-based）排课
  bool occursOnWeek(int weekIndexOneBased) => weeks.contains(weekIndexOneBased);

  TimetableCourse copyWith({
    String? title,
    String? teacher,
    String? location,
    String? description,
    int? weekday,
    int? startPeriod,
    int? duration,
    List<int>? weeks,
    Color? color,
    Map<String, dynamic>? extra,
  }) {
    return TimetableCourse(
      title: title ?? this.title,
      teacher: teacher ?? this.teacher,
      location: location ?? this.location,
      description: description ?? this.description,
      weekday: weekday ?? this.weekday,
      startPeriod: startPeriod ?? this.startPeriod,
      duration: duration ?? this.duration,
      weeks: weeks ?? this.weeks,
      color: color ?? this.color,
      extra: extra ?? this.extra,
    );
  }
}

/// 每节课对应的时间区间配置。
class CourseTimeSlot {
  const CourseTimeSlot({
    required this.index,
    required this.startLabel,
    required this.endLabel,
  });

  final int index;
  final String startLabel;
  final String endLabel;
}

/// 默认的 10 节课时间配置，与原 ColorTimetable 保持一致。
const List<CourseTimeSlot> kDefaultCourseTimeSlots = <CourseTimeSlot>[
  CourseTimeSlot(index: 1, startLabel: '08:00', endLabel: '08:50'),
  CourseTimeSlot(index: 2, startLabel: '08:55', endLabel: '09:45'),
  CourseTimeSlot(index: 3, startLabel: '10:15', endLabel: '11:05'),
  CourseTimeSlot(index: 4, startLabel: '11:10', endLabel: '12:00'),
  CourseTimeSlot(index: 5, startLabel: '14:00', endLabel: '14:50'),
  CourseTimeSlot(index: 6, startLabel: '14:55', endLabel: '15:45'),
  CourseTimeSlot(index: 7, startLabel: '16:15', endLabel: '17:05'),
  CourseTimeSlot(index: 8, startLabel: '17:10', endLabel: '18:00'),
  CourseTimeSlot(index: 9, startLabel: '19:00', endLabel: '19:50'),
  CourseTimeSlot(index: 10, startLabel: '19:55', endLabel: '20:45'),
];

/// 课程点击时抛出的上下文。
class CourseTapDetails {
  const CourseTapDetails({
    required this.course,
    required this.coursesInSameSlot,
    required this.weekIndex,
    required this.weekdayIndex,
  });

  /// 主卡片对应的课程
  final TimetableCourse course;

  /// 同一时间冲突/重叠的课程（包含 [course] 本身）
  final List<TimetableCourse> coursesInSameSlot;

  /// 当前周（0-based）
  final int weekIndex;

  /// 当前星期索引（0=周一）
  final int weekdayIndex;

  /// 是否存在冲突课程
  bool get hasConflict => coursesInSameSlot.length > 1;

  /// 显示友好的周数（1-based）
  int get displayWeek => weekIndex + 1;

  /// 显示友好的星期（1=周一）
  int get displayWeekday => weekdayIndex + 1;
}

typedef CourseTapCallback = void Function(CourseTapDetails details);
