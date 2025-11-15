import 'dart:math';
import 'package:flutter/material.dart';
import '../models.dart';
import '../controller.dart';
import '../theme.dart';

typedef CourseTap = void Function(TimetableCourseTapDetails details);

const double _timeColumnFraction = 0.08;

class ColorTimetable extends StatefulWidget {
  final List<TimetableCourse> courses;
  final DateTime startOfTerm;
  final int initialWeekIndex;
  final DateTime referenceDate;
  final bool showWeekSelector;
  final bool showBuiltinCourseSheet;
  final ColorTimetableTheme? theme;
  final TimetableController? controller;
  final CourseTap? onCourseTap;
  final VoidCallback? onCreateCourse;
  final VoidCallback? onPaletteTap;
  final ValueChanged<int>? onWeekChanged;
  final bool showGridLines;

  const ColorTimetable({
    super.key,
    required this.courses,
    required this.startOfTerm,
    required this.initialWeekIndex,
    required this.referenceDate,
    bool? initialShowWeekSelector,
    bool showWeekSelector = true,
    this.showBuiltinCourseSheet = true,
    this.theme,
    this.controller,
    this.onCourseTap,
    this.onCreateCourse,
    this.onPaletteTap,
    this.onWeekChanged,
    this.showGridLines = false,
  }) : showWeekSelector = initialShowWeekSelector ?? showWeekSelector;

  @override
  State<ColorTimetable> createState() => _ColorTimetableState();
}

class _ColorTimetableState extends State<ColorTimetable> {
  late TimetableController _controller;
  late ColorTimetableTheme _theme;
  late CourseColorAllocator _allocator;
  double _dragDx = 0;
  late int _originalWeekIndex;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TimetableController(initialWeekIndex: widget.initialWeekIndex);
    _theme = widget.theme ?? const ColorTimetableTheme();
    _allocator = CourseColorAllocator(_theme.paletteIndex);
    _originalWeekIndex = _weeksFromStart(widget.startOfTerm, widget.referenceDate).clamp(0, _weekCount - 1);
  }

  @override
  void didUpdateWidget(covariant ColorTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _theme = widget.theme ?? const ColorTimetableTheme();
      _allocator = CourseColorAllocator(_theme.paletteIndex);
    }
  }

  int get _weekCount {
    int maxWeek = 20;
    for (final c in widget.courses) {
      for (final w in c.weeks) {
        if (w > maxWeek) maxWeek = w;
      }
    }
    return max(maxWeek, widget.initialWeekIndex + 1);
  }

  List<TimetableCourse> _coursesForWeek(int week) {
    return widget.courses.where((c) => c.occursOnWeek(week)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _theme.backgroundColor;
    final week = _controller.currentWeekIndex + 1;
    final courses = _coursesForWeek(week);
    return Column(
      children: [
        if (widget.showWeekSelector) _buildWeekSelector(),
        _buildHeader(),
        Expanded(
          child: GestureDetector(
            onHorizontalDragStart: (_) {
              _dragDx = 0;
            },
            onHorizontalDragUpdate: (details) {
              _dragDx += details.delta.dx;
            },
            onHorizontalDragEnd: (_) {
              var idx = _controller.currentWeekIndex;
              if (_dragDx > 50) {
                if (idx > 0) idx--;
              } else if (_dragDx < -50) {
                if (idx < _weekCount - 1) idx++;
              }
              if (idx != _controller.currentWeekIndex) {
                setState(() => _controller.setWeekIndex(idx));
                widget.onWeekChanged?.call(idx);
              }
              _dragDx = 0;
            },
            child: Stack(
              children: [
                Container(
                  color: bg,
                  child: _TimetableGrid(
                    courses: courses,
                    allocator: _allocator,
                    gridLineColor: _theme.gridLineColor,
                    labelColor: _theme.labelColor,
                    courseTextColor: _theme.courseTextColor,
                    showGridLines: widget.showGridLines,
                    onTap: widget.onCourseTap == null
                        ? null
                        : (course) => widget.onCourseTap!(TimetableCourseTapDetails(course, week)),
                  ),
                ),
                Positioned(
                  right: _controller.currentWeekIndex != _originalWeekIndex ? 0 : -200,
                  top: MediaQuery.of(context).size.height * 0.4,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      color: const Color(0xFF42A5F5),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(999),
                        bottomLeft: Radius.circular(999),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _controller.setWeekIndex(_originalWeekIndex));
                        widget.onWeekChanged?.call(_originalWeekIndex);
                      },
                      child: const Text(
                        '返回本周',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    final date = widget.startOfTerm.add(Duration(days: _controller.currentWeekIndex * 7));
    final month = date.month;
    final days = List<int>.generate(7, (i) => date.add(Duration(days: i)).day);
    final weekTitle = ['一', '二', '三', '四', '五', '六', '日'];
    final todayWeekday = DateTime.now().weekday % 7;
    final highlight = widget.startOfTerm.isBefore(DateTime.now()) &&
        _controller.currentWeekIndex == _weeksFromStart(widget.startOfTerm, DateTime.now()) &&
        todayWeekday - 1 >= 0;
    final width = MediaQuery.of(context).size.width;
    final monthWidth = width * _timeColumnFraction;
    return Container(
      height: 40,
      decoration: BoxDecoration(color: _theme.backgroundColor),
      child: Row(
        children: [
          SizedBox(
            width: monthWidth,
            child: Center(
              child: Text('$month月', style: TextStyle(color: _theme.labelColor, fontWeight: FontWeight.w500)),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                for (int i = 0; i < 7; i++)
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(
                          top: const BorderSide(color: Colors.transparent, width: 0),
                          bottom: BorderSide(
                            color: (highlight && i == todayWeekday - 1)
                                ? _theme.selectedBorderColor
                                : Colors.transparent,
                            width: (highlight && i == todayWeekday - 1) ? 4 : 0,
                          ),
                        ),
                        color: highlight && i == todayWeekday - 1
                            ? _theme.weekHighlightColor.withOpacity(0.25)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(weekTitle[i], style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          Text('${days[i]}', style: const TextStyle(fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _weeksFromStart(DateTime start, DateTime now) {
    final days = now.difference(DateTime(start.year, start.month, start.day)).inDays;
    if (days < 0) return 0;
    return days ~/ 7;
  }

  Widget _buildWeekSelector() {
    final current = _controller.currentWeekIndex;
    return SizedBox(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _weekCount,
        itemBuilder: (context, index) {
          final selected = index == current;
          final date = widget.startOfTerm.add(Duration(days: index * 7));
          final density = _buildWeekDensity(index + 1);
          return GestureDetector(
            onTap: () {
              setState(() => _controller.setWeekIndex(index));
              widget.onWeekChanged?.call(index);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                children: [
                  Text('第${index + 1}周', style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: GridView.count(
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 5,
                      children: [
                        for (final v in density)
                          Container(
                            margin: const EdgeInsets.all(1),
                            decoration: BoxDecoration(
                              color: v > 0
                                  ? const Color(0xFF42A5F5)
                                  : const Color(0xFFE0E0E0),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<int> _buildWeekDensity(int week) {
    final arr = List<int>.filled(25, 0);
    for (final c in widget.courses) {
      if (!c.occursOnWeek(week)) continue;
      if (c.weekday > 5) continue;
      final base = (c.weekday - 1) * 5;
      final bucket = max(0, min(4, (c.startPeriod - 1) ~/ 2));
      arr[base + bucket]++;
      if (c.duration > 2) {
        final bucket2 = min(4, bucket + 1);
        arr[base + bucket2]++;
      }
    }
    return arr;
  }
}

class _TimetableGrid extends StatelessWidget {
  final List<TimetableCourse> courses;
  final CourseColorAllocator allocator;
  final Color gridLineColor;
  final Color labelColor;
  final Color courseTextColor;
  final void Function(TimetableCourse)? onTap;
  final bool showGridLines;

  const _TimetableGrid({
    required this.courses,
    required this.allocator,
    required this.gridLineColor,
    required this.labelColor,
    required this.courseTextColor,
    required this.showGridLines,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final timeColWidth = width * _timeColumnFraction;
        final columnWidth = (width - timeColWidth) / 7;
        final rowCount = periodTimes.length;
        final rowHeight = height / rowCount;
        return Stack(
          children: [
            if (showGridLines)
              for (int r = 0; r <= rowCount; r++)
                Positioned(
                  left: 0,
                  right: 0,
                  top: r * rowHeight,
                  height: 1,
                  child: Container(color: gridLineColor),
                ),
            if (showGridLines)
              for (int c = 0; c <= 7; c++)
                Positioned(
                  left: timeColWidth + c * columnWidth,
                  top: 0,
                  width: 1,
                  bottom: 0,
                  child: Container(color: gridLineColor),
                ),
            Positioned(
              left: 0,
              top: 0,
              width: timeColWidth,
              bottom: 0,
              child: Column(
                children: [
                  for (int i = 0; i < periodTimes.length; i++)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            Text('${periodTimes[i]['s']}\n${periodTimes[i]['e']}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            for (final course in _dedupe(courses))
              Positioned(
                left: timeColWidth + (course.weekday - 1) * columnWidth + 4,
                top: (course.startPeriod - 1) * rowHeight + 4,
                width: columnWidth - 8,
                height: course.duration * rowHeight - 8,
                child: GestureDetector(
                  onTap: onTap == null ? null : () => onTap!(course),
                  child: Container(
                    decoration: BoxDecoration(
                      color: course.color ?? allocator.colorForTitle(course.title),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text(course.title,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          if (course.location != null)
                            Text(course.location!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  List<TimetableCourse> _dedupe(List<TimetableCourse> list) {
    final result = <TimetableCourse>[];
    for (final item in list) {
      if (result.isEmpty) {
        result.add(item);
      } else {
        final last = result.last;
        if (last.weekday == item.weekday && last.startPeriod == item.startPeriod) {
          continue;
        }
        result.add(item);
      }
    }
    return result;
  }
}