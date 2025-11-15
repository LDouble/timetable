import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timetable/timetable.dart';

void main() {
  List<TimetableCourse> sampleCourses() => <TimetableCourse>[
        TimetableCourse(
          title: '计算机网络',
          teacher: '王老师',
          location: '理科楼 A201',
          weekday: 1,
          startPeriod: 1,
          duration: 2,
          weeks: List<int>.generate(12, (i) => i + 1),
        ),
        TimetableCourse(
          title: '数据结构实验',
          teacher: '赵老师',
          location: '计算中心 302',
          weekday: 3,
          startPeriod: 3,
          duration: 3,
          description: '上机实验',
          weeks: List<int>.generate(8, (i) => i + 1),
        ),
        TimetableCourse(
          title: '线性代数',
          teacher: '李老师',
          location: '公共教室 B105',
          weekday: 2,
          startPeriod: 5,
          duration: 2,
          weeks: List<int>.generate(10, (i) => i + 3),
        ),
        TimetableCourse(
          title: '羽毛球选修',
          teacher: '体育部',
          location: '体育馆',
          weekday: 5,
          startPeriod: 7,
          duration: 2,
          weeks: List<int>.generate(6, (i) => i + 5),
        ),
        TimetableCourse(
          title: '软件工程',
          teacher: '陈老师',
          location: '科技楼 501',
          weekday: 1,
          startPeriod: 3,
          duration: 2,
          weeks: List<int>.generate(14, (i) => i + 1),
        ),
        TimetableCourse(
          title: '人工智能导论',
          teacher: '黄老师',
          location: '创新中心 201',
          weekday: 4,
          startPeriod: 1,
          duration: 2,
          weeks: List<int>.generate(12, (i) => i + 1),
        ),
        TimetableCourse(
          title: '移动开发实践',
          teacher: '实践导师',
          location: '实验楼 403',
          weekday: 4,
          startPeriod: 5,
          duration: 4,
          weeks: List<int>.generate(10, (i) => i + 2),
        ),
      ];

  testWidgets('ColorTimetable golden light', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final theme = const ColorTimetableTheme();
    final courses = sampleCourses();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ColorTimetable(
              courses: courses,
              startOfTerm: DateTime(2024, 9, 2),
              initialWeekIndex: 0,
              referenceDate: DateTime(2024, 9, 2),
              theme: theme,
              showBuiltinCourseSheet: false,
              initialShowWeekSelector: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ColorTimetable),
      matchesGoldenFile('goldens/timetable_light.png'),
    );
  });

  testWidgets('ColorTimetable golden dark', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final theme = const ColorTimetableTheme.dark();
    final courses = sampleCourses();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: ColorTimetable(
              courses: courses,
              startOfTerm: DateTime(2024, 9, 2),
              initialWeekIndex: 0,
              referenceDate: DateTime(2024, 9, 2),
              theme: theme,
              showBuiltinCourseSheet: false,
              initialShowWeekSelector: true,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(ColorTimetable),
      matchesGoldenFile('goldens/timetable_dark.png'),
    );
  });
}