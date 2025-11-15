import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/timetable.dart';

void main() {
  test('TimetableCourse endPeriod is computed correctly', () {
    final course = TimetableCourse(
      title: '线性代数',
      weekday: 1,
      startPeriod: 3,
      duration: 2,
      weeks: [1, 2, 3],
    );
    expect(course.endPeriod, 4);
    expect(course.occursOnWeek(2), isTrue);
    expect(course.occursOnWeek(6), isFalse);
  });

  testWidgets('ColorTimetable renders provided courses', (tester) async {
    final courses = <TimetableCourse>[
      TimetableCourse(
        title: '算法设计',
        teacher: '王老师',
        location: '理科楼A101',
        weekday: 1,
        startPeriod: 1,
        duration: 2,
        weeks: [1],
      ),
      TimetableCourse(
        title: '操作系统',
        teacher: '李老师',
        location: '综合楼302',
        weekday: 3,
        startPeriod: 5,
        duration: 2,
        weeks: [1],
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ColorTimetable(
            courses: courses,
            startOfTerm: DateTime(2024, 9, 2),
            initialWeekIndex: 0,
            referenceDate: DateTime(2024, 9, 2),
            showWeekSelector: false,
            showBuiltinCourseSheet: false,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('算法设计'), findsOneWidget);
    expect(find.text('操作系统'), findsOneWidget);
    expect(find.textContaining('理科楼'), findsOneWidget);
  });
}
