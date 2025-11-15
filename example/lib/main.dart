import 'package:flutter/material.dart';
import 'package:timetable/timetable.dart';

void main() {
  runApp(const TimetableDemoApp());
}

class TimetableDemoApp extends StatefulWidget {
  const TimetableDemoApp({super.key});

  @override
  State<TimetableDemoApp> createState() => _TimetableDemoAppState();
}

class _TimetableDemoAppState extends State<TimetableDemoApp> {
  bool _useDarkTheme = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ColorTimetable Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
        brightness: _useDarkTheme ? Brightness.dark : Brightness.light,
      ),
      home: DemoHomePage(
        useDarkTheme: _useDarkTheme,
        onThemeChanged: (value) => setState(() => _useDarkTheme = value),
      ),
    );
  }
}

class DemoHomePage extends StatefulWidget {
  const DemoHomePage({super.key, required this.useDarkTheme, required this.onThemeChanged});

  final bool useDarkTheme;
  final ValueChanged<bool> onThemeChanged;

  @override
  State<DemoHomePage> createState() => _DemoHomePageState();
}

class _DemoHomePageState extends State<DemoHomePage> {
  final DateTime _startOfTerm = DateTime(2024, 9, 2);
  int _currentWeekIndex = 0;

  List<TimetableCourse> get _sampleCourses => <TimetableCourse>[
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

  @override
  Widget build(BuildContext context) {
    final ColorTimetableTheme timetableTheme = widget.useDarkTheme
        ? const ColorTimetableTheme.dark()
        : const ColorTimetableTheme();

    return Scaffold(
      backgroundColor: timetableTheme.backgroundColor,
      body: SafeArea(
        top: false,
        bottom: false,
        child: ColorTimetable(
          courses: _sampleCourses,
          startOfTerm: _startOfTerm,
          initialWeekIndex: _currentWeekIndex,
          referenceDate: _startOfTerm.add(Duration(days: _currentWeekIndex * 7)),
          theme: timetableTheme,
          showBuiltinCourseSheet: true,
          initialShowWeekSelector: true,
          onCreateCourse: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('点击添加课程（示例）')),
            );
          },
          onPaletteTap: () => widget.onThemeChanged(!widget.useDarkTheme),
          onWeekChanged: (index) => setState(() => _currentWeekIndex = index),
          onCourseTap: (details) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('当前选择：${details.course.title} (第${details.displayWeek}周)'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
      ),
    );
  }
}
