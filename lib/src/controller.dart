import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/foundation.dart';

class TimetableController extends ChangeNotifier {
  int _currentWeekIndex;
  double _zoom;

  TimetableController({int initialWeekIndex = 0, double initialZoom = 1.0})
      : _currentWeekIndex = initialWeekIndex,
        _zoom = initialZoom;

  int get currentWeekIndex => _currentWeekIndex;
  double get zoom => _zoom;

  void setWeekIndex(int index) {
    if (index == _currentWeekIndex) return;
    _currentWeekIndex = index;
    notifyListeners();
  }

  void setZoom(double value) {
    final next = value.clamp(0.7, 2.0);
    if (next == _zoom) return;
    _zoom = next.toDouble();
    notifyListeners();
  }
}

class TimetableCaptureController {
  final GlobalKey repaintKey = GlobalKey();

  Future<Uint8List?> capturePng({double pixelRatio = 3.0}) async {
    final boundary = repaintKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ByteData? bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes?.buffer.asUint8List();
  }
}
