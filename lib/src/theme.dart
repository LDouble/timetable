import 'package:flutter/material.dart';

class ColorTimetableTheme {
  final Color backgroundColor;
  final Color gridLineColor;
  final Color labelColor;
  final Color courseTextColor;
  final Color selectedBorderColor;
  final Color weekHighlightColor;
  final int paletteIndex;
  final Color inactiveCourseColor;
  final Color conflictBarColor;

  const ColorTimetableTheme({
    this.backgroundColor = const Color(0xFFFFFFFF),
    // Tailwind gray-200
    this.gridLineColor = const Color(0xFFE5E7EB),
    this.labelColor = const Color(0xFF757575),
    this.courseTextColor = const Color(0xFF212121),
    this.selectedBorderColor = const Color(0xFF42A5F5),
    this.weekHighlightColor = const Color(0xFF90CAF9),
    this.paletteIndex = 0,
    this.inactiveCourseColor = const Color(0xFFB0B0B0),
    this.conflictBarColor = const Color(0xFFFFFFFF),
  });

  const ColorTimetableTheme.dark()
      : backgroundColor = const Color(0xFF111111),
        // Tailwind gray-400 @ 50% opacity
        gridLineColor = const Color(0x809CA3AF),
        labelColor = const Color(0xFFBDBDBD),
        courseTextColor = const Color(0xFFFFFFFF),
        selectedBorderColor = const Color(0xFF42A5F5),
        weekHighlightColor = const Color(0xFF1E88E5),
        paletteIndex = 1,
        inactiveCourseColor = const Color(0xFF6B7280),
        conflictBarColor = const Color(0xFFFFFFFF);
}

const List<List<Color>> _palette = [
  [
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
  [
    Color(0xFF99CCFF),
    Color(0xFFFFCC99),
    Color(0xFFCCCCFF),
    Color(0xFF99CCCC),
    Color(0xFFA1D699),
    Color(0xFF7397DB),
    Color(0xFFFF9983),
    Color(0xFF87D7EB),
    Color(0xFF99CC99),
  ],
];

class CourseColorAllocator {
  final Map<String, Color> _cache = {};
  final int paletteIndex;

  CourseColorAllocator(this.paletteIndex);

  Color colorForTitle(String title) {
    if (_cache.containsKey(title)) return _cache[title]!;
    final list = _palette[(paletteIndex % _palette.length).abs()];
    final color = list[_cache.length % list.length];
    _cache[title] = color;
    return color;
  }
}
