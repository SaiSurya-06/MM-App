import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/notifications/notification_service.dart';
import 'widgets/common/premium_error_widget.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      debugPrint('[FlutterError] Caught framework error: ${details.exceptionAsString()}');
    };

    // Override the default ErrorWidget builder to present our premium diagnostic error widget
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return PremiumErrorWidget(details: details);
    };

    // Catch platform level asynchronous errors
    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      debugPrint('[PlatformDispatcherError] Caught async error: $error\n$stack');
      return true; // Mark as handled
    };

    await NotificationService.instance.initialize();
    await NotificationService.instance.scheduleWeeklyBackupReminder();
    await NotificationService.instance.scheduleMonthEndBudgetReminder();

    runApp(
      const ProviderScope(
        child: MoneyManagerApp(),
      ),
    );
  }, (error, stackTrace) {
    debugPrint('[ZoneError] Unhandled asynchronous error: $error\n$stackTrace');
  });
}

