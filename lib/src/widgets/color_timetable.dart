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
  final TimetableSchedule? schedule;
  final CourseTap? onCourseTap;
  final void Function(int weekday, int startPeriod)? onAddCourseAtSlot;
  final VoidCallback? onCreateCourse;
  final VoidCallback? onPaletteTap;
  final ValueChanged<int>? onWeekChanged;
  final bool showGridLines;
  final bool showNonCurrentWeekCourses;

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
    this.schedule,
    this.onCourseTap,
    this.onAddCourseAtSlot,
    this.onCreateCourse,
    this.onPaletteTap,
    this.onWeekChanged,
    this.showGridLines = false,
    this.showNonCurrentWeekCourses = false,
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
  bool _sheetVisible = false;
  TimetableCourse? _sheetAnchor;
  List<TimetableCourse> _sheetConflicts = const [];
  String _sheetTimeLabel = '';
  late List<TimetableCourse> _courses;
  late TimetableSchedule _schedule;
  bool _addVisible = false;
  int _addWeekday = 1;
  int _addStartPeriod = 1;
  final TextEditingController _addTitleCtrl = TextEditingController();
  final TextEditingController _addLocationCtrl = TextEditingController();
  final TextEditingController _addTeacherCtrl = TextEditingController();
  int _addDuration = 1;
  bool _addForCurrentWeekOnly = true;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TimetableController(initialWeekIndex: widget.initialWeekIndex);
    _theme = widget.theme ?? const ColorTimetableTheme();
    _allocator = CourseColorAllocator(_theme.paletteIndex);
    _originalWeekIndex = _weeksFromStart(widget.startOfTerm, widget.referenceDate).clamp(0, _weekCount - 1);
    _courses = List<TimetableCourse>.from(widget.courses);
    _sortCourses();
    _schedule = widget.schedule ?? defaultSchedule;
  }

  @override
  void didUpdateWidget(covariant ColorTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _theme = widget.theme ?? const ColorTimetableTheme();
      _allocator = CourseColorAllocator(_theme.paletteIndex);
    }
    if (!identical(oldWidget.courses, widget.courses)) {
      _courses = List<TimetableCourse>.from(widget.courses);
      _sortCourses();
    }
    if (oldWidget.schedule != widget.schedule) {
      _schedule = widget.schedule ?? defaultSchedule;
    }
  }

  int get _weekCount {
    int maxWeek = 25;
    for (final c in widget.courses) {
      for (final w in c.weeks) {
        if (w > maxWeek) maxWeek = w;
      }
    }
    return max(maxWeek, widget.initialWeekIndex + 1);
  }

  List<TimetableCourse> _coursesForWeek(int week) {
    return _courses.where((c) => c.occursOnWeek(week)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bg = _theme.backgroundColor;
    final week = _controller.currentWeekIndex + 1;
    final courses = widget.showNonCurrentWeekCourses ? _courses : _coursesForWeek(week);
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
                      schedule: _schedule,
                      currentWeek: week,
                    showInactiveGrey: widget.showNonCurrentWeekCourses,
                    theme: _theme,
                    onLongPressSlot: (w, p) {
                      if (widget.onAddCourseAtSlot != null) {
                        widget.onAddCourseAtSlot!(w, p);
                      } else {
                        _openAddCourseSheet(w, p);
                      }
                    },
                    onTap: (course) {
                      if (widget.showBuiltinCourseSheet) {
                        _showCourseSheet(course, week, courses);
                      } else {
                        widget.onCourseTap?.call(TimetableCourseTapDetails(course, week));
                      }
                    },
                  ),
                ),
                // Built-in Course Action Sheet overlay & sheet
                if (widget.showBuiltinCourseSheet) ...[
                  IgnorePointer(
                    ignoring: !_sheetVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _sheetVisible ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _closeSheet,
                        child: Container(
                          color: Colors.black.withOpacity(0.5),
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: !_sheetVisible,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _sheetVisible ? 1.0 : 0.0,
                      child: Align(
                        alignment: Alignment.center,
                        child: _CourseActionSheet(
                          theme: _theme,
                          allocator: _allocator,
                          timeLabel: _sheetTimeLabel,
                          courseList: _sheetConflicts,
                          onClose: _closeSheet,
                          onPromote: (course) {
                        _promoteCourse(course);
                      },
                          onOpenDetail: (course) {
                            widget.onCourseTap?.call(TimetableCourseTapDetails(course, week));
                          },
                        ),
                      ),
                    ),
                  ),
                ],
                if (_addVisible) ...[
                  IgnorePointer(
                    ignoring: false,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _addVisible ? 1.0 : 0.0,
                      child: Align(
                        alignment: Alignment.center,
                        child: _AddCourseSheet(
                          theme: _theme,
                          schedule: _schedule,
                          weekday: _addWeekday,
                          startPeriod: _addStartPeriod,
                          titleCtrl: _addTitleCtrl,
                          locationCtrl: _addLocationCtrl,
                          teacherCtrl: _addTeacherCtrl,
                          duration: _addDuration,
                          forCurrentWeekOnly: _addForCurrentWeekOnly,
                          onDurationChanged: (d) { setState(() => _addDuration = d); },
                          onForCurrentWeekOnlyChanged: (v) { setState(() => _addForCurrentWeekOnly = v); },
                          onCancel: _closeAddCourseSheet,
                          onSave: _saveNewCourse,
                        ),
                      ),
                    ),
                  ),
                  IgnorePointer(
                    ignoring: false,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: _addVisible ? 1.0 : 0.0,
                      child: GestureDetector(
                        onTap: _closeAddCourseSheet,
                        child: Container(color: Colors.black45),
                      ),
                    ),
                  ),
                ],
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
                      crossAxisCount: _schedule.densityBucketCount,
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
    final int bucketCount = _schedule.densityBucketCount;
    final int total = 5 * bucketCount;
    final arr = List<int>.filled(total, 0);
    for (final c in _courses) {
      if (!c.occursOnWeek(week)) continue;
      if (c.weekday > 5) continue;
      final int base = (c.weekday - 1) * bucketCount;
      final int bucket = max(0, min(bucketCount - 1, ((c.startPeriod - 1) * bucketCount ~/ _schedule.periodCount)));
      arr[base + bucket]++;
      final int spanBuckets = ((c.duration * bucketCount) / _schedule.periodCount).ceil();
      if (spanBuckets > 1) {
        final int bucket2 = min(bucketCount - 1, bucket + 1);
        arr[base + bucket2]++;
      }
    }
    return arr;
  }

  void _showCourseSheet(TimetableCourse course, int displayWeek, List<TimetableCourse> weekCourses) {
    final conflicts = weekCourses.where((c) => c.weekday == course.weekday && c.startPeriod == course.startPeriod).toList();
    final weekTitle = ['一', '二', '三', '四', '五', '六', '日'];
    final timeLabel = '星期${weekTitle[course.weekday - 1]} 第${course.startPeriod}-${course.endPeriod}节';
    setState(() {
      _sheetAnchor = course;
      _sheetConflicts = conflicts;
      _sheetTimeLabel = timeLabel;
      _sheetVisible = true;
    });
  }

  void _closeSheet() {
    if (!_sheetVisible) return;
    setState(() {
      _sheetVisible = false;
      _sheetAnchor = null;
      _sheetConflicts = const [];
      _sheetTimeLabel = '';
    });
  }

  void _promoteCourse(TimetableCourse target) {
    final keyW = target.weekday;
    final keyS = target.startPeriod;
    final List<TimetableCourse> newList = [];
    bool inserted = false;
    bool removed = false;
    for (final c in _courses) {
      if (!removed && c == target) {
        removed = true;
        continue;
      }
      if (c.weekday == keyW && c.startPeriod == keyS && !inserted) {
        newList.add(target);
        inserted = true;
      }
      newList.add(c);
    }
    if (!inserted) {
      newList.add(target);
    }
    setState(() {
      _courses = newList;
      _sortCourses();
    });
  }

  void _sortCourses() {
    _courses.sort((a, b) => a.weekday - b.weekday != 0
        ? a.weekday - b.weekday
        : a.startPeriod - b.startPeriod);
  }

  void _openAddCourseSheet(int weekday, int startPeriod) {
    setState(() {
      _addWeekday = weekday;
      _addStartPeriod = startPeriod;
      _addDuration = 1;
      _addTitleCtrl.text = '';
      _addLocationCtrl.text = '';
      _addTeacherCtrl.text = '';
      _addForCurrentWeekOnly = true;
      _addVisible = true;
    });
  }

  void _closeAddCourseSheet() {
    setState(() {
      _addVisible = false;
    });
  }

  void _saveNewCourse() {
    final String title = _addTitleCtrl.text.trim();
    if (title.isEmpty) return;
    final TimetableCourse course = TimetableCourse(
      title: title,
      teacher: _addTeacherCtrl.text.trim().isEmpty ? null : _addTeacherCtrl.text.trim(),
      location: _addLocationCtrl.text.trim().isEmpty ? null : _addLocationCtrl.text.trim(),
      weekday: _addWeekday,
      startPeriod: _addStartPeriod,
      duration: _addDuration,
      weeks: _addForCurrentWeekOnly ? [(_controller.currentWeekIndex + 1)] : List<int>.generate(25, (i) => i + 1),
    );
    setState(() {
      _courses.add(course);
      _sortCourses();
      _addVisible = false;
      _addTitleCtrl.clear();
      _addLocationCtrl.clear();
      _addTeacherCtrl.clear();
    });
  }
}

class _AddCourseSheet extends StatelessWidget {
  final ColorTimetableTheme theme;
  final TimetableSchedule schedule;
  final int weekday;
  final int startPeriod;
  final TextEditingController titleCtrl;
  final TextEditingController locationCtrl;
  final TextEditingController teacherCtrl;
  final int duration;
  final bool forCurrentWeekOnly;
  final ValueChanged<int> onDurationChanged;
  final ValueChanged<bool> onForCurrentWeekOnlyChanged;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const _AddCourseSheet({
    required this.theme,
    required this.schedule,
    required this.weekday,
    required this.startPeriod,
    required this.titleCtrl,
    required this.locationCtrl,
    required this.teacherCtrl,
    required this.duration,
    required this.forCurrentWeekOnly,
    required this.onDurationChanged,
    required this.onForCurrentWeekOnlyChanged,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final int maxDuration = (schedule.periodCount - startPeriod + 1).clamp(1, schedule.periodCount);
    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('添加课程', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(controller: titleCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '课程名称')),
            const SizedBox(height: 8),
            TextField(controller: locationCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '上课地点')),
            const SizedBox(height: 8),
            TextField(controller: teacherCtrl, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: '教师')),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: Text('星期$weekday 第$startPeriod 节', style: const TextStyle(fontSize: 14))),
                const SizedBox(width: 12),
                DropdownButton<int>(
                  value: duration,
                  items: List<DropdownMenuItem<int>>.generate(maxDuration, (i) => DropdownMenuItem<int>(value: i + 1, child: Text('持续${i + 1}节'))),
                  onChanged: (v) { if (v != null) onDurationChanged(v); },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: const Text('仅当前周')),
                Switch(value: forCurrentWeekOnly, onChanged: onForCurrentWeekOnlyChanged),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: onCancel, child: const Text('取消'))),
                const SizedBox(width: 8),
                Expanded(child: ElevatedButton(onPressed: onSave, child: const Text('保存'))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseActionSheet extends StatelessWidget {
  final ColorTimetableTheme theme;
  final CourseColorAllocator allocator;
  final String timeLabel;
  final List<TimetableCourse> courseList;
  final VoidCallback onClose;
  final void Function(TimetableCourse) onPromote;
  final void Function(TimetableCourse) onOpenDetail;

  const _CourseActionSheet({
    required this.theme,
    required this.allocator,
    required this.timeLabel,
    required this.courseList,
    required this.onClose,
    required this.onPromote,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < courseList.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: courseList[i].color ?? allocator.colorForTitle(courseList[i].title),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Center(
                              child: Text(
                                '课程名称:${courseList[i].title}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              '上课地点:${courseList[i].location ?? '无'}',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '教师:${courseList[i].teacher ?? '无'}',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '时间:${timeLabel}',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '状态: 无',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ],
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: InkWell(
                            onTap: onClose,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text('删除', style: TextStyle(color: Colors.white)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
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
  final TimetableSchedule schedule;
  final int currentWeek;
  final bool showInactiveGrey;
  final ColorTimetableTheme theme;
  final void Function(int weekday, int startPeriod)? onLongPressSlot;

  const _TimetableGrid({
    required this.courses,
    required this.allocator,
    required this.gridLineColor,
    required this.labelColor,
    required this.courseTextColor,
    required this.showGridLines,
    required this.schedule,
    required this.currentWeek,
    required this.showInactiveGrey,
    required this.theme,
    this.onLongPressSlot,
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
        final rowCount = schedule.periodCount;
        final rowHeight = height / rowCount;
        return GestureDetector(
          onLongPressStart: (details) {
            if (onLongPressSlot == null) return;
            final box = context.findRenderObject() as RenderBox?;
            if (box == null) return;
            final local = box.globalToLocal(details.globalPosition);
            if (local.dx <= timeColWidth) return;
            final int col = ((local.dx - timeColWidth) / columnWidth).floor() + 1;
            final int row = (local.dy / rowHeight).floor() + 1;
            if (col < 1 || col > 7 || row < 1 || row > rowCount) return;
            onLongPressSlot!(col, row);
          },
          child: Stack(
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
                  for (int i = 0; i < schedule.periodCount; i++)
                    Expanded(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('${i + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            Text('${schedule.periods[i].s}\n${schedule.periods[i].e}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 9)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            ..._groupedBySlot(courses).map((group) {
              final TimetableCourse course = group.firstWhere(
                (c) => c.occursOnWeek(currentWeek),
                orElse: () => group.first,
              );
              final bool active = course.occursOnWeek(currentWeek);
              final bool hasConflicts = group.length > 1;
              return Positioned(
                left: timeColWidth + (course.weekday - 1) * columnWidth + 4,
                top: (course.startPeriod - 1) * rowHeight + 4,
                width: columnWidth - 8,
                height: course.duration * rowHeight - 8,
                child: GestureDetector(
                  onTap: onTap == null ? null : () => onTap!(course),
                  child: Container(
                    decoration: BoxDecoration(
                      color: active
                          ? (course.color ?? allocator.colorForTitle(course.title))
                          : (showInactiveGrey
                              ? theme.inactiveCourseColor
                              : (course.color ?? allocator.colorForTitle(course.title))),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              Text(course.title,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: Colors.white.withOpacity(active ? 1.0 : 0.9),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600)),
                              if (course.location != null)
                                Text(course.location!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(active ? 1.0 : 0.9), fontSize: 10)),
                            ],
                          ),
                        ),
                        if (hasConflicts)
                          Positioned(
                            top: 4,
                            left: 4,
                            right: 4,
                            child: Container(
                              height: 4,
                              decoration: BoxDecoration(
                                color: theme.conflictBarColor.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
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

  List<List<TimetableCourse>> _groupedBySlot(List<TimetableCourse> list) {
    final Map<String, List<TimetableCourse>> map = {};
    for (final c in list) {
      final key = '${c.weekday}:${c.startPeriod}';
      map.putIfAbsent(key, () => []);
      map[key]!.add(c);
    }
    return map.values.toList();
  }
}
