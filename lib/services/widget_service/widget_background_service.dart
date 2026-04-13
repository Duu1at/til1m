// ignore_for_file: unreachable_from_main // WorkManager entry-point: callbackDispatcher is @pragma('vm:entry-point'), so all classes here ARE reachable from that isolate.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import 'package:til1m/core/constants/app_constants.dart';
import 'package:til1m/services/widget_service/widget_service.dart';
import 'package:workmanager/workmanager.dart';

/// Unique task name registered with WorkManager.
const _kWidgetUpdateTask = 'com.til1m.til1m.updateWidget';

/// Callback executed by WorkManager in a background isolate.
/// All word data was already written to HomeWidget shared storage by
/// [WidgetService.updateWidget] — this task only re-triggers a repaint so
/// the OS re-renders the widget frame after a long idle period.
/// Must be a top-level function.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, inputData) async {
    try {
      await HomeWidget.setAppGroupId(AppConstants.widgetGroupId);

      for (final name in AppConstants.androidWidgetProviders) {
        await HomeWidget.updateWidget(
          androidName: name,
          iOSName: AppConstants.iosWidgetName,
          qualifiedAndroidName: '${AppConstants.androidWidgetPackage}.$name',
        );
      }
    } on Object catch (e, st) {
      debugPrint('[WidgetBgService] task error: $e\n$st');
    }
    return true;
  });
}

/// Manages WorkManager registration for periodic widget refresh.
@immutable
final class WidgetBackgroundService {
  const WidgetBackgroundService();

  /// Initialise WorkManager and register a periodic 4-hour update task.
  /// No-op on iOS — WorkManager only supports Android.
  Future<void> register() async {
    if (!Platform.isAndroid) return;

    await Workmanager().initialize(callbackDispatcher);

    await Workmanager().registerPeriodicTask(
      _kWidgetUpdateTask,
      _kWidgetUpdateTask,
      frequency: const Duration(hours: 4),
      constraints: Constraints(
        networkType: NetworkType.notRequired,
      ),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }

  /// Cancel the periodic task. No-op on iOS.
  Future<void> cancel() async {
    if (!Platform.isAndroid) return;
    await Workmanager().cancelByUniqueName(_kWidgetUpdateTask);
  }
}
