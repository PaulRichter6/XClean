import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

class WidgetService {
  static Future<void> update({
    required int streak,
    required int score,
    required int battery,
    required String lastTime,
  }) async {
    try {
      await HomeWidget.saveWidgetData<String>('streak', '🔥 $streak Tage');
      await HomeWidget.saveWidgetData<String>('score', score > 0 ? '$score / 100' : '-- / 100');
      await HomeWidget.saveWidgetData<String>('battery', battery >= 0 ? '$battery%' : '--%');
      await HomeWidget.saveWidgetData<String>('last_brush_time', lastTime.isNotEmpty ? lastTime : 'Oclean X Elite');
      await HomeWidget.updateWidget(
        name: 'XCleanWidgetProvider',
        androidName: 'XCleanWidgetProvider',
      );
    } catch (e) {
      debugPrint('[WidgetService] Error updating home widget: $e');
    }
  }
}
