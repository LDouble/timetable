import 'package:flutter/material.dart';

/// 控制颜色、间距、阴影等视觉元素，最大程度复刻 ColorTimetable。
class ColorTimetableTheme {
  const ColorTimetableTheme({
    this.backgroundColor = const Color(0xFFF6F7FB),
    this.surfaceColor = Colors.white,
    this.headerColor = Colors.white,
    this.timeColumnColor = const Color(0xFFF0F1F6),
    this.weekSelectorBackground = const Color(0xFFF3F4F6),
    this.weekSelectorHighlightColor = const Color(0xFF5F8BFF),
    this.weekSelectorInactiveColor = const Color(0xFF5F6573),
    this.weekSelectorOriginalWeekColor = const Color(0xFFA6AEC3),
    this.headerShadowColor = const Color(0x14000000),
    this.timelineTextColor = const Color(0xFF1F2430),
    this.headerTextColor = const Color(0xFF1C1F27),
    this.secondaryTextColor = const Color(0xFF6B7280),
    this.accentColor = const Color(0xFF12A595),
    this.gridLineColor = const Color(0xFFE0E6F1),
    this.returnButtonTextColor = Colors.white,
    this.conflictIndicatorColor = const Color(0xCCFFFFFF),
    this.slotHeight = 88,
    this.timeColumnWidth = 72,
    this.rowSpacing = 8,
    this.columnSpacing = 8,
    this.weekSelectorHeight = 96,
    this.gridPadding = const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
    this.cardRadius = const BorderRadius.all(Radius.circular(16)),
    this.cardElevation = 10,
    this.courseColors = const <Color>[
      Color(0xFFFFDC72),
      Color(0xFFCE7CF4),
      Color(0xFFFF7171),
      Color(0xFF66CC99),
      Color(0xFFFF9966),
      Color(0xFF66CCCC),
      Color(0xFF6699CC),
      Color(0xFF99CC99),
      Color(0xFF669966),
      Color(0xFF66CCFF),
      Color(0xFF99CC66),
      Color(0xFFFF9999),
      Color(0xFF81CC74),
    ],
    this.courseTitleStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    ),
    this.courseMetaStyle = const TextStyle(
      fontSize: 11,
      color: Colors.white,
    ),
    this.weekdayStyle = const TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    this.timelineIndexStyle = const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
    this.timelineTimeStyle = const TextStyle(
      fontSize: 10,
    ),
  });

  /// 深色主题
  const ColorTimetableTheme.dark()
      : this(
          backgroundColor: const Color(0xFF121826),
          surfaceColor: const Color(0xFF1E2435),
          headerColor: const Color(0xFF1E2435),
          timeColumnColor: const Color(0xFF272E41),
          weekSelectorBackground: const Color(0xFF202536),
          weekSelectorHighlightColor: const Color(0xFF4D7CFF),
          weekSelectorInactiveColor: const Color(0xFFABB3CE),
          weekSelectorOriginalWeekColor: const Color(0xFF6E7692),
          headerShadowColor: const Color(0x66000000),
          timelineTextColor: Colors.white,
          headerTextColor: Colors.white,
          secondaryTextColor: const Color(0xFFADB3C8),
          accentColor: const Color(0xFF4D7CFF),
          gridLineColor: const Color(0xFF2E3346),
          returnButtonTextColor: Colors.white,
          conflictIndicatorColor: const Color(0xCCFFFFFF),
          courseTitleStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          courseMetaStyle: const TextStyle(
            fontSize: 11,
            color: Colors.white,
          ),
        );

  final Color backgroundColor;
  final Color surfaceColor;
  final Color headerColor;
  final Color timeColumnColor;
  final Color weekSelectorBackground;
  final Color weekSelectorHighlightColor;
  final Color weekSelectorInactiveColor;
  final Color weekSelectorOriginalWeekColor;
  final Color headerShadowColor;
  final Color timelineTextColor;
  final Color headerTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color gridLineColor;
  final Color returnButtonTextColor;
  final Color conflictIndicatorColor;

  final double slotHeight;
  final double timeColumnWidth;
  final double rowSpacing;
  final double columnSpacing;
  final double weekSelectorHeight;
  final double cardElevation;
  final BorderRadius cardRadius;
  final EdgeInsetsGeometry gridPadding;
  final List<Color> courseColors;

  final TextStyle courseTitleStyle;
  final TextStyle courseMetaStyle;
  final TextStyle weekdayStyle;
  final TextStyle timelineIndexStyle;
  final TextStyle timelineTimeStyle;

  ColorTimetableTheme copyWith({
    Color? backgroundColor,
    Color? surfaceColor,
    Color? headerColor,
    Color? timeColumnColor,
    Color? weekSelectorBackground,
    Color? weekSelectorHighlightColor,
    Color? weekSelectorInactiveColor,
    Color? weekSelectorOriginalWeekColor,
    Color? headerShadowColor,
    Color? timelineTextColor,
    Color? headerTextColor,
    Color? secondaryTextColor,
    Color? accentColor,
    Color? gridLineColor,
    Color? returnButtonTextColor,
    Color? conflictIndicatorColor,
    double? slotHeight,
    double? timeColumnWidth,
    double? rowSpacing,
    double? columnSpacing,
    double? weekSelectorHeight,
    double? cardElevation,
    BorderRadius? cardRadius,
    EdgeInsetsGeometry? gridPadding,
    List<Color>? courseColors,
    TextStyle? courseTitleStyle,
    TextStyle? courseMetaStyle,
    TextStyle? weekdayStyle,
    TextStyle? timelineIndexStyle,
    TextStyle? timelineTimeStyle,
  }) {
    return ColorTimetableTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      headerColor: headerColor ?? this.headerColor,
      timeColumnColor: timeColumnColor ?? this.timeColumnColor,
      weekSelectorBackground: weekSelectorBackground ?? this.weekSelectorBackground,
      weekSelectorHighlightColor: weekSelectorHighlightColor ?? this.weekSelectorHighlightColor,
      weekSelectorInactiveColor: weekSelectorInactiveColor ?? this.weekSelectorInactiveColor,
      weekSelectorOriginalWeekColor:
          weekSelectorOriginalWeekColor ?? this.weekSelectorOriginalWeekColor,
      headerShadowColor: headerShadowColor ?? this.headerShadowColor,
      timelineTextColor: timelineTextColor ?? this.timelineTextColor,
      headerTextColor: headerTextColor ?? this.headerTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      accentColor: accentColor ?? this.accentColor,
      gridLineColor: gridLineColor ?? this.gridLineColor,
      returnButtonTextColor: returnButtonTextColor ?? this.returnButtonTextColor,
      conflictIndicatorColor: conflictIndicatorColor ?? this.conflictIndicatorColor,
      slotHeight: slotHeight ?? this.slotHeight,
      timeColumnWidth: timeColumnWidth ?? this.timeColumnWidth,
      rowSpacing: rowSpacing ?? this.rowSpacing,
      columnSpacing: columnSpacing ?? this.columnSpacing,
      weekSelectorHeight: weekSelectorHeight ?? this.weekSelectorHeight,
      cardElevation: cardElevation ?? this.cardElevation,
      cardRadius: cardRadius ?? this.cardRadius,
      gridPadding: gridPadding ?? this.gridPadding,
      courseColors: courseColors ?? this.courseColors,
      courseTitleStyle: courseTitleStyle ?? this.courseTitleStyle,
      courseMetaStyle: courseMetaStyle ?? this.courseMetaStyle,
      weekdayStyle: weekdayStyle ?? this.weekdayStyle,
      timelineIndexStyle: timelineIndexStyle ?? this.timelineIndexStyle,
      timelineTimeStyle: timelineTimeStyle ?? this.timelineTimeStyle,
    );
  }
}
