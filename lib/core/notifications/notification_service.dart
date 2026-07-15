import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService instance = NotificationService._internal();

  static const int duplicateCheckWindowMinutes = 10;

  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NotificationService._internal();

  Future<void> initialize() async {
    // 1. Initialize Timezones
    tz.initializeTimeZones();

    // 2. Configure Android Init Settings
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // 3. Initialize the plugin
    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotification,
    );

    // Create standard channels
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel alertsChannel = AndroidNotificationChannel(
      'budget_alerts', // id
      'Budget Alerts', // title
      description: 'Triggered when category budgets reach 80% or 100%',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel remindersChannel = AndroidNotificationChannel(
      'daily_reminders', // id
      'Daily Reminders', // title
      description: 'Scheduled daily logging reminders',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel backupChannel = AndroidNotificationChannel(
      'weekly_backup_reminders', // id
      'Weekly Backup Reminders', // title
      description: 'Weekly reminders to backup database',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    const AndroidNotificationChannel monthEndChannel = AndroidNotificationChannel(
      'month_end_reminders', // id
      'Month End Reminders', // title
      description: 'Reminders to plan your monthly budget',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(alertsChannel);
      await androidImplementation.createNotificationChannel(remindersChannel);
      await androidImplementation.createNotificationChannel(backupChannel);
      await androidImplementation.createNotificationChannel(monthEndChannel);
    }
  }

  Future<bool> requestPermissions() async {
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        _localNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      final bool? granted = await androidImplementation.requestNotificationsPermission();
      return granted ?? false;
    }
    return false;
  }

  /// Show an immediate notification for budget limit reached
  Future<void> showBudgetAlert(String categoryName, double percentageUsed) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Triggered when category budgets reach 80% or 100%',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final String message = percentageUsed >= 100.0
          ? '🚨 Budget for "$categoryName" has been fully exhausted! (100% Used)'
          : '⚠️ Budget for "$categoryName" is 80% used. Be mindful of your spending!';

      await _localNotificationsPlugin.show(
        categoryName.hashCode,
        'Budget Warning',
        message,
        platformDetails,
      );
    } catch (e, stack) {
      print('[NotificationService] showBudgetAlert error: $e\n$stack');
    }
  }

  /// Show an immediate notification for category limit reached
  Future<void> showCategoryLimitAlert(String categoryName, double limitAmount) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Triggered when category budgets reach 80% or 100%',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        categoryName.hashCode + 1,
        'Category Limit Exceeded',
        '🚨 You have exceeded your spending limit for "$categoryName"! (Limit: ${limitAmount.toStringAsFixed(0)})',
        platformDetails,
      );
    } catch (e, stack) {
      print('[NotificationService] showCategoryLimitAlert error: $e\n$stack');
    }
  }

  /// Show an immediate notification for duplicate transaction detected
  Future<void> showDuplicateAlert(String title, double amount) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Triggered when category budgets reach 80% or 100%',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        title.hashCode + 2,
        'Duplicate Transaction Detected',
        '⚠️ A similar transaction for "$title" of ${amount.toStringAsFixed(0)} was logged within the last $duplicateCheckWindowMinutes minutes.',
        platformDetails,
      );
    } catch (e, stack) {
      print('[NotificationService] showDuplicateAlert error: $e\n$stack');
    }
  }

  /// Show a custom local alert notification
  Future<void> showCustomAlert(String title, String body) async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Triggered when custom alerts are enabled',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        title.hashCode + 3,
        title,
        body,
        platformDetails,
      );
    } catch (e, stack) {
      print('[NotificationService] showCustomAlert error: $e\n$stack');
    }
  }

  /// Show an immediate notification for security lockout cooldown
  Future<void> showLockoutAlert() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'budget_alerts',
        'Budget Alerts',
        channelDescription: 'Triggered when security events occur',
        importance: Importance.max,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      await _localNotificationsPlugin.show(
        999,
        'Security Lockout Active',
        '🚨 Money Manager has been locked for 30 minutes due to 5 failed PIN entry attempts.',
        platformDetails,
      );
    } catch (e, stack) {
      print('[NotificationService] showLockoutAlert error: $e\n$stack');
    }
  }

  /// Schedule a daily reminder at a custom hour and minute
  Future<void> scheduleDailyReminder(int hour, int minute) async {
    try {
      // Cancel existing reminder first to prevent duplicates
      await cancelDailyReminder();

      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'daily_reminders',
        'Daily Reminders',
        channelDescription: 'Scheduled daily logging reminders',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);

      await _localNotificationsPlugin.zonedSchedule(
        101, // Unique ID for daily reminder
        '📝 Daily Expense Logger',
        "Don't forget to log today's transactions to stay on top of your budget!",
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time, // Matches time daily
      );
    } catch (e, stack) {
      print('[NotificationService] scheduleDailyReminder error: $e\n$stack');
    }
  }

  Future<void> scheduleWeeklyBackupReminder() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'weekly_backup_reminders',
        'Weekly Backup Reminders',
        channelDescription: 'Weekly reminders to backup database',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final now = DateTime.now();
      DateTime targetLocal = DateTime(now.year, now.month, now.day, 10, 0);
      if (targetLocal.isBefore(now)) {
        targetLocal = targetLocal.add(const Duration(days: 1));
      }
      final targetUtc = targetLocal.toUtc();
      final scheduledDate = tz.TZDateTime.from(targetUtc, tz.getLocation('UTC'));

      await _localNotificationsPlugin.zonedSchedule(
        202,
        '💾 Database Backup Reminder',
        "It's time to back up your database! Save a local backup now to secure your financial data.",
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    } catch (e, stack) {
      print('[NotificationService] scheduleWeeklyBackupReminder error: $e\n$stack');
    }
  }

  Future<void> scheduleMonthEndBudgetReminder() async {
    try {
      const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        'month_end_reminders',
        'Month End Reminders',
        channelDescription: 'Reminders to plan your monthly budget',
        importance: Importance.high,
        priority: Priority.high,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
      );

      final now = DateTime.now();
      final lastDay = DateTime(now.year, now.month + 1, 0);
      DateTime targetLocal = DateTime(lastDay.year, lastDay.month, lastDay.day, 18, 0);
      if (targetLocal.isBefore(now)) {
        final nextMonthLastDay = DateTime(now.year, now.month + 2, 0);
        targetLocal = DateTime(nextMonthLastDay.year, nextMonthLastDay.month, nextMonthLastDay.day, 18, 0);
      }
      
      final targetUtc = targetLocal.toUtc();
      final scheduledDate = tz.TZDateTime.from(targetUtc, tz.getLocation('UTC'));

      await _localNotificationsPlugin.zonedSchedule(
        303,
        '📅 Plan Your Budget',
        "The month is ending! Plan your budget splits and category limits now in the Money Map.",
        scheduledDate,
        platformDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfMonthAndTime,
      );
    } catch (e, stack) {
      print('[NotificationService] scheduleMonthEndBudgetReminder error: $e\n$stack');
    }
  }

  Future<void> cancelDailyReminder() async {
    try {
      await _localNotificationsPlugin.cancel(101);
    } catch (e, stack) {
      print('[NotificationService] cancelDailyReminder error: $e\n$stack');
    }
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = DateTime.now();
    DateTime targetLocal = DateTime(now.year, now.month, now.day, hour, minute);
    if (targetLocal.isBefore(now)) {
      targetLocal = targetLocal.add(const Duration(days: 1));
    }
    final targetUtc = targetLocal.toUtc();
    return tz.TZDateTime.from(targetUtc, tz.getLocation('UTC'));
  }

  void _onDidReceiveNotification(NotificationResponse details) {
    // Handle notification click if needed
  }
}
