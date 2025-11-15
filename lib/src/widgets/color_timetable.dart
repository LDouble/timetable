import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../model/course.dart';
import '../theme/color_timetable_theme.dart';

const List<String> kDefaultWeekdayLabels = <String>['一', '二', '三', '四', '五', '六', '日'];

/// Flutter 版本的 ColorTimetable 主组件。
class ColorTimetable extends StatefulWidget {
  const ColorTimetable({
    super.key,
    required this.courses,
    required this.startOfTerm,
    this.weekCount = 20,
    this.timeSlots = kDefaultCourseTimeSlots,
    this.theme = const ColorTimetableTheme(),
    this.weekdayLabels = kDefaultWeekdayLabels,
    this.initialWeekIndex,
    this.referenceDate,
    this.onWeekChanged,
    this.onCourseTap,
    this.showWeekSelector = true,
    this.showReturnToCurrentWeekButton = true,
    this.highlightToday = true,
    this.showBuiltinCourseSheet = true,
    this.returnToCurrentWeekLabel = '返回本周',
    this.scrollPhysics,
    this.initialShowWeekSelector = false,
    this.onCreateCourse,
    this.onPaletteTap,
    this.onMoreTap,
  })  : assert(weekCount > 0, 'weekCount must be greater than zero'),
        assert(timeSlots.length > 1, 'timeSlots should cover at least two entries'),
        assert(weekdayLabels.length == 7, 'weekdayLabels必须包含7个元素');

  final List<TimetableCourse> courses;
  final DateTime startOfTerm;
  final int weekCount;
  final List<CourseTimeSlot> timeSlots;
  final ColorTimetableTheme theme;
  final List<String> weekdayLabels;
  final int? initialWeekIndex;
  final DateTime? referenceDate;
  final ValueChanged<int>? onWeekChanged;
  final CourseTapCallback? onCourseTap;
  final bool showWeekSelector;
  final bool showReturnToCurrentWeekButton;
  final bool highlightToday;
  final bool showBuiltinCourseSheet;
  final String returnToCurrentWeekLabel;
  final ScrollPhysics? scrollPhysics;
  final bool initialShowWeekSelector;
  final VoidCallback? onCreateCourse;
  final VoidCallback? onPaletteTap;
  final VoidCallback? onMoreTap;

  @override
  State<ColorTimetable> createState() => _ColorTimetableState();
}

class _ColorTimetableState extends State<ColorTimetable> {
  late int _currentWeekIndex;
  late int _originalWeekIndex;
  late int _originalWeekdayIndex;
  bool _hasSemesterStarted = false;
  bool _showWeekPanel = false;

  Map<String, Color> _colorCache = <String, Color>{};
  List<GlobalKey> _weekItemKeys = <GlobalKey>[];

  @override
  void initState() {
    super.initState();
    _syncWeekKeys();
    _initializeWeekInformation();
    _resetColorCache();
    _showWeekPanel = widget.initialShowWeekSelector;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCurrentWeekVisible());
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = widget.theme;
    final padding = MediaQuery.of(context).padding;
    return Container(
      padding: EdgeInsets.only(top: padding.top + 2, left: 16, right: 16, bottom: 12),
      decoration: BoxDecoration(
        color: theme.topBarColor,
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 20, offset: Offset(0, 4)),
        ],
      ),
      child: SizedBox(
        height: 46,
        child: Row(
          children: [
            SizedBox(
              width: 56,
              child: _TopBarIconButton(
                icon: Icons.add_rounded,
                color: theme.topBarIconColor,
                onTap: widget.onCreateCourse,
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: widget.showWeekSelector ? _toggleWeekPanel : null,
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '第${_currentWeekIndex + 1}周${_hasSemesterStarted ? '' : ' (未开学)'}',
                      style: TextStyle(
                        color: theme.topBarForegroundColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _showWeekPanel ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: theme.topBarForegroundColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(
              width: 90,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _TopBarIconButton(
                    icon: Icons.color_lens_outlined,
                    color: theme.topBarIconColor,
                    onTap: widget.onPaletteTap,
                  ),
                  const SizedBox(width: 4),
                  _TopBarIconButton(
                    icon: Icons.more_horiz,
                    color: theme.topBarIconColor,
                    onTap: widget.onMoreTap,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant ColorTimetable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weekCount != widget.weekCount) {
      _syncWeekKeys();
      _currentWeekIndex = _clampWeekIndex(_currentWeekIndex);
      _originalWeekIndex = _clampWeekIndex(_originalWeekIndex);
    }
    if (oldWidget.startOfTerm != widget.startOfTerm || oldWidget.referenceDate != widget.referenceDate) {
      _initializeWeekInformation();
    }
    if (!listEquals(oldWidget.courses, widget.courses) || oldWidget.theme.courseColors != widget.theme.courseColors) {
      _resetColorCache();
    }
    if (oldWidget.initialShowWeekSelector != widget.initialShowWeekSelector) {
      _showWeekPanel = widget.initialShowWeekSelector;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final height = widget.timeSlots.length * theme.slotHeight + (widget.timeSlots.length - 1) * theme.rowSpacing;
    final weekHeatmap = _buildWeekHeatmap();
    final groupedCourses = _buildCourseGroups();

    return ColoredBox(
      color: theme.backgroundColor,
      child: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: Stack(
              children: [
                _buildTimetableBody(context, theme, height, weekHeatmap, groupedCourses),
                if (widget.showReturnToCurrentWeekButton) _buildReturnButtonOverlay(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _initializeWeekInformation() {
    final DateTime reference = widget.referenceDate ?? DateTime.now();
    final DateTime normalizedStart = _normalizeDate(widget.startOfTerm);
    final DateTime normalizedRef = _normalizeDate(reference);
    final int diffDays = normalizedRef.difference(normalizedStart).inDays;
    _hasSemesterStarted = diffDays >= 0;
    final int computedWeek = diffDays >= 0 ? diffDays ~/ 7 : 0;
    _originalWeekIndex = _clampWeekIndex(computedWeek);
    _currentWeekIndex = _clampWeekIndex(widget.initialWeekIndex ?? _originalWeekIndex);
    _originalWeekdayIndex = _weekDayToIndex(normalizedRef.weekday);
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureCurrentWeekVisible());
  }

  void _resetColorCache() {
    _colorCache = <String, Color>{};
    for (final course in widget.courses) {
      _resolveCourseColor(course);
    }
  }

  void _syncWeekKeys() {
    _weekItemKeys = List<GlobalKey>.generate(widget.weekCount, (index) => GlobalKey(debugLabel: 'week-$index'));
  }

  void _ensureCurrentWeekVisible() {
    if (!widget.showWeekSelector || _weekItemKeys.isEmpty) return;
    final key = _weekItemKeys[_currentWeekIndex];
    final context = key.currentContext;
    if (context == null) return;
    Scrollable.ensureVisible(
      context,
      alignment: 0.5,
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
    );
  }

  int _clampWeekIndex(int value) => value.clamp(0, widget.weekCount - 1);

  void _toggleWeekPanel() {
    if (!widget.showWeekSelector) return;
    setState(() => _showWeekPanel = !_showWeekPanel);
  }

  DateTime _normalizeDate(DateTime date) => DateTime(date.year, date.month, date.day);

  int _weekDayToIndex(int weekday) => weekday == DateTime.sunday ? 6 : weekday - 1;

  Color _resolveCourseColor(TimetableCourse course) {
    if (course.color != null) {
      return course.color!;
    }
    return _colorCache.putIfAbsent(
      course.title,
      () => widget.theme.courseColors[_colorCache.length % widget.theme.courseColors.length],
    );
  }

  List<List<List<int>>> _buildWeekHeatmap() {
    final heatmap = List<List<List<int>>>.generate(
      widget.weekCount,
      (_) => List<List<int>>.generate(7, (_) => List<int>.filled(5, 0)),
    );

    for (final course in widget.courses) {
      final int dayIndex = (course.weekday - 1).clamp(0, 6);
      final int bucketIndex = ((course.startPeriod - 1) / 2).floor().clamp(0, 4);
      for (final week in course.weeks) {
        if (week < 1 || week > widget.weekCount) continue;
        final dayArray = heatmap[week - 1][dayIndex];
        dayArray[bucketIndex] = dayArray[bucketIndex] + 1;
        if (course.duration > 2 && bucketIndex + 1 < dayArray.length) {
          dayArray[bucketIndex + 1] = dayArray[bucketIndex + 1] + 1;
        }
      }
    }
    return heatmap;
  }

  List<_CourseGroup> _buildCourseGroups() {
    final List<TimetableCourse> visible = widget.courses
        .where((course) => course.occursOnWeek(_currentWeekIndex + 1))
        .toList()
      ..sort((a, b) => a.weekday - b.weekday == 0 ? a.startPeriod - b.startPeriod : a.weekday - b.weekday);

    final Map<String, List<TimetableCourse>> grouped = <String, List<TimetableCourse>>{};
    for (final course in visible) {
      final key = '${course.weekday}-${course.startPeriod}';
      grouped.putIfAbsent(key, () => <TimetableCourse>[]).add(course);
    }

    return grouped.values
        .map((list) => _CourseGroup(list: list, color: _resolveCourseColor(list.first)))
        .toList()
      ..sort(
        (a, b) => a.primary.weekday - b.primary.weekday == 0
            ? a.primary.startPeriod - b.primary.startPeriod
            : a.primary.weekday - b.primary.weekday,
      );
  }

  Widget _buildWeekSelector(List<List<List<int>>> heatmap) {
    final theme = widget.theme;
    return SizedBox(
      height: theme.weekSelectorHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: widget.weekCount,
        itemBuilder: (context, index) {
          final bool isCurrent = index == _currentWeekIndex;
          final bool isOriginal = index == _originalWeekIndex;
          final Color cardColor = isCurrent
              ? theme.weekSelectorHighlightColor.withValues(alpha: 0.18)
              : theme.weekSelectorBackground;
          final Color borderColor = isCurrent ? theme.weekSelectorHighlightColor : Colors.transparent;
          final Color titleColor = isCurrent
              ? Colors.white
              : isOriginal
                  ? theme.weekSelectorOriginalWeekColor
                  : theme.weekSelectorInactiveColor;
          final List<int> dots = <int>[];
          for (int day = 0; day < 5; day++) {
            dots.addAll(heatmap[index][day]);
          }

          return Container(
            key: _weekItemKeys[index],
            width: 120,
            margin: const EdgeInsets.only(right: 10),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => _changeWeek(index),
                child: Ink(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor, width: 1.3),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '第${index + 1}周',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: titleColor),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            mainAxisSpacing: 3,
                            crossAxisSpacing: 3,
                          ),
                          itemCount: dots.length,
                          itemBuilder: (context, dotIndex) {
                            final bool active = dots[dotIndex] > 0;
                            return DecoratedBox(
                              decoration: BoxDecoration(
                                color: active
                                    ? theme.weekSelectorHighlightColor
                                    : theme.weekSelectorInactiveColor.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    final theme = widget.theme;
    final List<int> dates = _weekDatesFor(_currentWeekIndex);
    final int month = _weekBaseDate(_currentWeekIndex).month;
    final double gap = theme.columnSpacing;
    return Container(
      decoration: BoxDecoration(
        color: theme.headerColor,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(color: theme.headerShadowColor, blurRadius: 30, offset: const Offset(0, 18)),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth - gap * 7;
          final double unit = availableWidth / (7 + 0.7);
          final double timeWidth = unit * 0.7;
          final double dayWidth = unit;
          return Row(
            children: [
              SizedBox(
                width: timeWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$month月', style: theme.weekdayStyle.copyWith(fontSize: 18, color: theme.headerTextColor)),
                    const SizedBox(height: 6),
                    Text('Week ${_currentWeekIndex + 1}', style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
                  ],
                ),
              ),
              SizedBox(width: gap),
              Expanded(
                child: Row(
                  children: List.generate(7, (index) {
                    final bool highlight = widget.highlightToday &&
                        _hasSemesterStarted &&
                        _currentWeekIndex == _originalWeekIndex &&
                        index == _originalWeekdayIndex;
                    return Padding(
                      padding: EdgeInsets.only(right: index == 6 ? 0 : gap),
                      child: SizedBox(
                        width: dayWidth,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('周${widget.weekdayLabels[index]}', style: theme.weekdayStyle.copyWith(color: theme.headerTextColor)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color: highlight ? theme.weekSelectorHighlightColor : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: highlight ? theme.weekSelectorHighlightColor : theme.gridLineColor.withValues(alpha: 0.4),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                '${dates[index]}',
                                style: theme.timelineTimeStyle.copyWith(
                                  color: highlight ? Colors.white : theme.secondaryTextColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTimetableBody(
    BuildContext context,
    ColorTimetableTheme theme,
    double totalHeight,
    List<List<List<int>>> heatmap,
    List<_CourseGroup> groups,
  ) {
    final double headerBaseHeight = 128;
    final double weekPanelHeight =
        widget.showWeekSelector && _showWeekPanel ? theme.weekSelectorHeight + 16 : 0;
    final double headerHeight = headerBaseHeight + weekPanelHeight;
    final mediaQuery = MediaQuery.of(context);

    return Stack(
      children: [
        Positioned.fill(
          child: SingleChildScrollView(
            physics: widget.scrollPhysics ?? const BouncingScrollPhysics(),
            padding: EdgeInsets.only(
              top: headerHeight + 12,
              bottom: mediaQuery.padding.bottom + 24,
            ),
            child: Padding(
              padding: theme.gridPadding,
              child: _buildGridSurface(totalHeight, groups),
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _buildPinnedHeader(heatmap),
        ),
      ],
    );
  }

  Widget _buildPinnedHeader(List<List<List<int>>> heatmap) {
    final theme = widget.theme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.backgroundColor,
        boxShadow: [
          BoxShadow(color: theme.headerShadowColor, blurRadius: 20, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showWeekSelector)
            AnimatedCrossFade(
              crossFadeState: _showWeekPanel ? CrossFadeState.showFirst : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 250),
              firstCurve: Curves.easeOutCubic,
              secondCurve: Curves.easeOutCubic,
              sizeCurve: Curves.easeOutCubic,
              firstChild: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _buildWeekSelector(heatmap),
              ),
              secondChild: const SizedBox(height: 0),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: _buildHeader(),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnButtonOverlay() {
    final bool show = widget.showReturnToCurrentWeekButton && _currentWeekIndex != _originalWeekIndex;
    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: AnimatedSlide(
            offset: show ? Offset.zero : const Offset(1.3, 0),
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutCubic,
            child: AnimatedOpacity(
              opacity: show ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                  onTap: () => _changeWeek(_originalWeekIndex),
                  child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: widget.theme.accentColor,
                      borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
                    ),
                    child: Text(
                      widget.returnToCurrentWeekLabel,
                      style: TextStyle(
                        color: widget.theme.returnButtonTextColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGridSurface(double totalHeight, List<_CourseGroup> groups) {
    final theme = widget.theme;
    final rowCount = widget.timeSlots.length;
    final Map<int, List<_CourseGroup>> groupedByDay = <int, List<_CourseGroup>>{};
    for (final group in groups) {
      groupedByDay.putIfAbsent(group.primary.weekday - 1, () => <_CourseGroup>[]).add(group);
    }

    final double gap = theme.columnSpacing;
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: theme.headerShadowColor, blurRadius: 35, offset: const Offset(0, 20))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double availableWidth = constraints.maxWidth - gap * 7;
          final double unit = availableWidth / (7 + 0.7);
          final double timeWidth = unit * 0.7;
          final double dayWidth = unit;

          final List<Widget> rowChildren = <Widget>[
            SizedBox(
              width: timeWidth,
              child: Column(
                children: List.generate(widget.timeSlots.length, (index) {
                  final slot = widget.timeSlots[index];
                  return Container(
                    height: theme.slotHeight,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${slot.index}', style: theme.timelineIndexStyle.copyWith(color: theme.timelineTextColor)),
                        const SizedBox(height: 6),
                        Text('${slot.startLabel}\n${slot.endLabel}',
                            textAlign: TextAlign.center,
                            style: theme.timelineTimeStyle.copyWith(color: theme.secondaryTextColor, height: 1.2)),
                      ],
                    ),
                  );
                }),
              ),
            ),
          ];

          for (int day = 0; day < 7; day++) {
            rowChildren.add(SizedBox(width: gap));
            rowChildren.add(
              SizedBox(
                width: dayWidth,
                child: _DayColumn(
                  slotCount: rowCount,
                  groups: groupedByDay[day] ?? <_CourseGroup>[],
                  slotHeight: theme.slotHeight,
                  rowSpacing: theme.rowSpacing,
                  theme: theme,
                  onCourseTap: _handleCourseTap,
                ),
              ),
            );
          }

          return SizedBox(
            height: totalHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: rowChildren,
            ),
          );
        },
      ),
    );
  }

  void _handleCourseTap(_CourseGroup group) {
    final details = CourseTapDetails(
      course: group.primary,
      coursesInSameSlot: group.courses,
      weekIndex: _currentWeekIndex,
      weekdayIndex: group.primary.weekday - 1,
    );
    widget.onCourseTap?.call(details);
    if (!widget.showBuiltinCourseSheet || !mounted) return;
    final time = _courseTimeLabel(group.primary);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: widget.theme.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return _CourseSheet(
          title: time,
          courses: group.courses,
          weekdayLabels: widget.weekdayLabels,
          theme: widget.theme,
          courseColor: group.color,
          weekLabel: '第${_currentWeekIndex + 1}周',
        );
      },
    );
  }

  String _courseTimeLabel(TimetableCourse course) {
    final String weekdayLabel = widget.weekdayLabels[(course.weekday - 1).clamp(0, 6)];
    return '星期$weekdayLabel 第${course.startPeriod}-${course.endPeriod}节';
  }

  void _changeWeek(int index) {
    final next = _clampWeekIndex(index);
    if (next == _currentWeekIndex) return;
    setState(() => _currentWeekIndex = next);
    widget.onWeekChanged?.call(next);
    _ensureCurrentWeekVisible();
  }

  DateTime _weekBaseDate(int weekIndex) => widget.startOfTerm.add(Duration(days: weekIndex * 7));

  List<int> _weekDatesFor(int weekIndex) {
    final DateTime start = _weekBaseDate(weekIndex);
    return List<int>.generate(7, (index) => start.add(Duration(days: index)).day);
  }
}

class _CourseGroup {
  _CourseGroup({required List<TimetableCourse> list, required this.color}) : courses = List<TimetableCourse>.unmodifiable(list);

  final List<TimetableCourse> courses;
  final Color color;

  TimetableCourse get primary => courses.first;
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({
    required this.slotCount,
    required this.groups,
    required this.slotHeight,
    required this.rowSpacing,
    required this.theme,
    required this.onCourseTap,
  });

  final int slotCount;
  final List<_CourseGroup> groups;
  final double slotHeight;
  final double rowSpacing;
  final ColorTimetableTheme theme;
  final ValueChanged<_CourseGroup> onCourseTap;

  @override
  Widget build(BuildContext context) {
    final double totalHeight = slotCount * slotHeight + (slotCount - 1) * rowSpacing;
    return SizedBox(
      height: totalHeight,
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SlotBackgroundPainter(
                slotCount: slotCount,
                slotHeight: slotHeight,
                rowSpacing: rowSpacing,
                theme: theme,
              ),
            ),
          ),
          for (final group in groups)
            _CourseCard(
              group: group,
              slotHeight: slotHeight,
              rowSpacing: rowSpacing,
              slotCount: slotCount,
              theme: theme,
              onTap: () => onCourseTap(group),
            ),
        ],
      ),
    );
  }
}

class _SlotBackgroundPainter extends CustomPainter {
  const _SlotBackgroundPainter({
    required this.slotCount,
    required this.slotHeight,
    required this.rowSpacing,
    required this.theme,
  });

  final int slotCount;
  final double slotHeight;
  final double rowSpacing;
  final ColorTimetableTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = theme.gridLineColor.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    for (int i = 0; i < slotCount; i++) {
      final double top = i * (slotHeight + rowSpacing);
      final Rect rect = Rect.fromLTWH(0, top, size.width, slotHeight);
      final RRect rrect = RRect.fromRectAndRadius(rect, const Radius.circular(18));
      canvas.drawRRect(rrect, fill);
      canvas.drawRRect(rrect.deflate(0.3), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant _SlotBackgroundPainter oldDelegate) {
    return slotCount != oldDelegate.slotCount ||
        slotHeight != oldDelegate.slotHeight ||
        rowSpacing != oldDelegate.rowSpacing ||
        theme.gridLineColor != oldDelegate.theme.gridLineColor;
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.group,
    required this.slotHeight,
    required this.rowSpacing,
    required this.slotCount,
    required this.theme,
    required this.onTap,
  });

  final _CourseGroup group;
  final double slotHeight;
  final double rowSpacing;
  final int slotCount;
  final ColorTimetableTheme theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final TimetableCourse course = group.primary;
    final int startIndex = math.min(math.max(course.startPeriod - 1, 0), slotCount - 1);
    final int endIndex = math.min(course.endPeriod - 1, slotCount - 1);
    final int slotSpan = math.max(1, endIndex - startIndex + 1);
    final double top = startIndex * (slotHeight + rowSpacing);
    final double height = slotSpan * slotHeight + math.max(0, slotSpan - 1) * rowSpacing;

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: theme.cardRadius,
              child: Ink(
                decoration: BoxDecoration(
                  color: group.color,
                  borderRadius: theme.cardRadius,
                  border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: theme.cardElevation,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: theme.courseTitleStyle,
                    ),
                    const SizedBox(height: 4),
                    if ((course.location ?? '').isNotEmpty)
                      _CourseMetaItem(
                        icon: Icons.location_on_outlined,
                        text: course.location!,
                        style: theme.courseMetaStyle,
                      ),
                    if ((course.description ?? '').isNotEmpty)
                      _CourseMetaItem(
                        icon: Icons.info_outline,
                        text: course.description!,
                        style: theme.courseMetaStyle,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (group.courses.length > 1)
            Positioned(
              top: 6,
              left: 16,
              right: 16,
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: theme.conflictIndicatorColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CourseMetaItem extends StatelessWidget {
  const _CourseMetaItem({required this.icon, required this.text, required this.style});

  final IconData icon;
  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: style.color),
          const SizedBox(height: 2),
          Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CourseSheet extends StatelessWidget {
  const _CourseSheet({
    required this.title,
    required this.courses,
    required this.weekdayLabels,
    required this.theme,
    required this.courseColor,
    required this.weekLabel,
  });

  final String title;
  final List<TimetableCourse> courses;
  final List<String> weekdayLabels;
  final ColorTimetableTheme theme;
  final Color courseColor;
  final String weekLabel;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 46,
            height: 4,
            decoration: BoxDecoration(
              color: theme.secondaryTextColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(weekLabel, style: TextStyle(color: theme.secondaryTextColor, fontSize: 12)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...courses.map((course) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.backgroundColor,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: courseColor.withValues(alpha: 0.3), width: 1.2),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          height: 24,
                          width: 4,
                          decoration: BoxDecoration(color: courseColor, borderRadius: BorderRadius.circular(999)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(course.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _SheetMetaRow(icon: Icons.alarm, label: _buildTimeLabel(course)),
                    if ((course.location ?? '').isNotEmpty)
                      _SheetMetaRow(icon: Icons.location_on_outlined, label: course.location!),
                    if ((course.teacher ?? '').isNotEmpty)
                      _SheetMetaRow(icon: Icons.person_outline, label: course.teacher!),
                    if ((course.description ?? '').isNotEmpty)
                      _SheetMetaRow(icon: Icons.info_outline, label: course.description!),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.accentColor,
                    foregroundColor: theme.returnButtonTextColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _buildTimeLabel(TimetableCourse course) {
    final weekday = weekdayLabels[(course.weekday - 1).clamp(0, 6)];
    return '星期$weekday 第${course.startPeriod}-${course.endPeriod}节';
  }
}

class _SheetMetaRow extends StatelessWidget {
  const _SheetMetaRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBarIconButton extends StatelessWidget {
  const _TopBarIconButton({required this.icon, required this.color, this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }
}
