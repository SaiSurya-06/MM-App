import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart' show deleteDatabase;
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart' show getApplicationDocumentsDirectory, getTemporaryDirectory;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../providers/transactions_provider.dart';
import '../../providers/categories_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/debts_provider.dart';
import '../../providers/savings_goals_provider.dart';
import '../../providers/transaction_templates_provider.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/utils/date_helpers.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/toast_notification.dart';
import '../../core/backup/backup_service.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/database/database.dart';


class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameController = TextEditingController();
  bool _isEditingName = false;

  final List<String> _currencies = [
    'USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD', 'CAD', 'CHF', 'CNY', 'HKD',
    'NZD', 'SEK', 'SGD', 'NOK', 'KRW', 'TRY', 'RUB', 'BRL', 'ZAR', 'MXN'
  ];

  @override
  void initState() {
    super.initState();
    final profile = ref.read(authProvider).profile;
    _nameController.text = profile?.name ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    final updated = profile.copyWith(name: newName);
    await ref.read(authProvider.notifier).updateProfile(updated);
    setState(() => _isEditingName = false);
    if (mounted) {
      ToastNotification.show(context, 'Name updated successfully.');
    }
  }

  Future<void> _updateCurrency(String val) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final updated = profile.copyWith(preferredCurrency: val);
    await ref.read(authProvider.notifier).updateProfile(updated);
    if (mounted) {
      ToastNotification.show(context, 'Currency updated to $val.');
    }
  }

  void _showCurrencyPickerDialog(BuildContext context, String currentCurrency) {
    showDialog(
      context: context,
      builder: (context) {
        return _CurrencyPickerDialog(
          currencies: _currencies,
          initialCurrency: currentCurrency,
          onSelected: (val) {
            _updateCurrency(val);
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteDatabase() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Delete Database?', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
        content: const Text(
          'This will permanently delete all profiles, transactions, budgets, savings goals, and debts. '
          'This action is irreversible.\n\nAre you sure you want to proceed?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Proceed', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      _showPinVerificationDialog();
    }
  }

  void _showPinVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PinVerificationDialog(
          correctPinHash: ref.read(authProvider).profile?.pinHash ?? '',
          onVerified: () {
            Navigator.pop(context); // Close PIN Dialog
            _deleteDatabase();
          },
        );
      },
    );
  }

  Future<void> _deleteDatabase() async {
    try {
      final dbPath = await getApplicationDocumentsDirectory();
      final path = join(dbPath.path, 'money_manager.db');
      
      // Close database connection
      await AppDatabase.instance.close();
      
      // Delete database file
      await deleteDatabase(path);
      
      if (mounted) {
        ToastNotification.show(context, 'Database deleted successfully.');
        ref.read(authProvider.notifier).logout();
        ref.read(authProvider.notifier).checkProfile();
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Error deleting database: $e', isError: true);
      }
    }
  }

  Future<void> _uninstallAppData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: const Text('Wipe & Uninstall Data', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935))),
        content: const Text(
          'This will wipe all application profiles, transactions, and settings to simulate a complete uninstall.\n\n'
          'Would you like to back up your database (.db) to your local files first to avoid permanent data loss?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context, true); // Wipe without backup
            },
            child: const Text('Wipe Without Backup', style: TextStyle(color: Color(0xFFE53935))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
            onPressed: () async {
              Navigator.pop(context, null); // Proceed with backup
            },
            child: const Text('Back Up & Wipe'),
          ),
        ],
      ),
    );

    if (confirm == false) {
      return; // Canceled
    }

    bool backupSuccess = true;
    if (confirm == null) {
      // User chose to backup first
      backupSuccess = await _backupDatabaseBeforeWipe();
    }

    if (backupSuccess) {
      _showPinVerificationForUninstallWipe();
    }
  }

  void _showPinVerificationForUninstallWipe() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return _PinVerificationDialog(
          correctPinHash: ref.read(authProvider).profile?.pinHash ?? '',
          onVerified: () {
            Navigator.pop(context); // Close PIN Dialog
            _performWipeAndExit();
          },
        );
      },
    );
  }

  Future<void> _performWipeAndExit() async {
    try {
      final dbPath = await getApplicationDocumentsDirectory();
      final path = join(dbPath.path, 'money_manager.db');
      
      // Close database connection
      await AppDatabase.instance.close();
      
      // Delete database file
      await deleteDatabase(path);
      
      if (mounted) {
        ToastNotification.show(context, 'All app data wiped successfully. Exiting app...');
        Future.delayed(const Duration(milliseconds: 1000), () {
          SystemNavigator.pop();
        });
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Error wiping app data: $e', isError: true);
      }
    }
  }

  Future<bool> _backupDatabaseBeforeWipe() async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
      final fileName = 'money_manager_backup_$dateStr.db';

      final dbFolder = await getApplicationDocumentsDirectory();
      final localDbPath = join(dbFolder.path, 'money_manager.db');
      final dbFile = File(localDbPath);
      if (!await dbFile.exists()) return false;

      final bytes = await dbFile.readAsBytes();

      // 1. Try FilePicker saveFile
      final outputPath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Database Backup',
        fileName: fileName,
        bytes: bytes,
      );

      if (outputPath != null) {
        final outputFile = File(outputPath);
        await outputFile.writeAsBytes(bytes);
        return true;
      }

      // 2. Fallback to sharing it (which has "Save to Files")
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/octet-stream')],
        subject: 'Money Manager Backup',
      );
      return true;
    } catch (e) {
      print('Error during _backupDatabaseBeforeWipe: $e');
      return false;
    }
  }

  Widget _buildFormatInfoItem(String title, String description) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE53935)),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: const TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
        ),
      ],
    );
  }

  Future<void> _updateTheme(bool isDark) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final updated = profile.copyWith(themePreference: isDark ? 'dark' : 'light');
    await ref.read(authProvider.notifier).updateProfile(updated);
  }

  Future<void> _updateBiometric(bool enabled) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    if (enabled) {
      // Validate device supports biometrics
      final isAvailable = ref.read(authProvider).isBiometricAvailable;
      if (!isAvailable) {
        ToastNotification.show(context, 'Biometrics not available or supported on this device.', isError: true);
        return;
      }
    }

    final updated = profile.copyWith(biometricEnabled: enabled);
    await ref.read(authProvider.notifier).updateProfile(updated);
    if (mounted) {
      ToastNotification.show(context, enabled ? 'Biometric login enabled.' : 'Biometric login disabled.');
    }
  }

  Future<void> _updateReminderToggle(bool enabled) async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final updated = profile.copyWith(reminderEnabled: enabled);
    await ref.read(authProvider.notifier).updateProfile(updated);

    if (enabled) {
      // Schedule reminder
      final parts = profile.reminderTime.split(':');
      final hour = int.parse(parts[0]);
      final min = int.parse(parts[1]);
      await NotificationService.instance.scheduleDailyReminder(hour, min);
      
      // Request notifications permission (important for Android 13+)
      await NotificationService.instance.requestPermissions();
    } else {
      // Cancel reminder
      await NotificationService.instance.cancelDailyReminder();
    }

    if (mounted) {
      ToastNotification.show(context, enabled ? 'Daily reminder enabled.' : 'Daily reminder disabled.');
    }
  }

  Future<void> _selectReminderTime() async {
    final profile = ref.read(authProvider).profile;
    if (profile == null) return;

    final parts = profile.reminderTime.split(':');
    final initialTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE53935),
              onPrimary: Colors.white,
              surface: Color(0xFF1E1E2E),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final hour = picked.hour;
      final min = picked.minute;
      final timeStr = '${hour.toString().padLeft(2, '0')}:${min.toString().padLeft(2, '0')}';

      final updated = profile.copyWith(reminderTime: timeStr);
      await ref.read(authProvider.notifier).updateProfile(updated);

      if (profile.reminderEnabled) {
        await NotificationService.instance.scheduleDailyReminder(hour, min);
      }

      if (mounted) {
        ToastNotification.show(context, 'Reminder time set to ${DateHelpers.formatTime(timeStr)}.');
      }
    }
  }

  // --- Backup & Restore Sheet Helpers ---

  Future<void> _showBackupOptionsSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161625) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Backup Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose format and destination for backup',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildBackupSection(context, 'sqlite', 'SQLite Database (.db)', 'Complete snapshot of all tables.'),
              const SizedBox(height: 12),
              _buildBackupSection(context, 'json', 'JSON Database Export (.json)', 'Human-readable portable format.'),
              const SizedBox(height: 12),
              _buildBackupSection(context, 'csv', 'CSV Transaction Ledger (.csv)', 'Only the transaction log rows.'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBackupSection(BuildContext context, String format, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _performBackup(context, format, 'drive'),
                  icon: const Icon(Icons.cloud_upload_outlined, size: 16),
                  label: const Text('Google Drive', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => _performBackup(context, format, 'local'),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Share File', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performBackup(BuildContext context, String format, String destination) async {
    Navigator.pop(context); // Close bottom sheet
    ToastNotification.show(context, 'Starting backup...');

    try {
      bool success = false;
      if (destination == 'local') {
        success = await BackupService.instance.backupToLocal(format);
      } else {
        if (!BackupService.instance.isSignedIn && !BackupService.instance.isSimulatedMode) {
          final signedIn = await BackupService.instance.signIn();
          if (!signedIn) {
            if (context.mounted) {
              ToastNotification.show(context, 'Failed to sign in to Google Drive', isError: true);
            }
            return;
          }
        }
        success = await BackupService.instance.backupToGoogleDrive(format);
      }

      if (context.mounted) {
        if (success) {
          ToastNotification.show(
            context,
            BackupService.instance.isSimulatedMode && destination == 'drive'
                ? 'Backup simulated successfully (Sandbox Mode).'
                : 'Backup completed successfully!'
          );
        } else {
          ToastNotification.show(context, 'Backup failed. Please check permissions.', isError: true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ToastNotification.show(context, 'Backup error: $e', isError: true);
      }
    }
  }

  Future<void> _showRestoreOptionsSheet(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161625) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Restore Options',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select format and source to restore database',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildRestoreSection(context, 'sqlite', 'SQLite Database (.db)', 'Overwrite current database with a DB backup.'),
              const SizedBox(height: 12),
              _buildRestoreSection(context, 'json', 'JSON Database Export (.json)', 'Restore database tables from a JSON backup.'),
              const SizedBox(height: 12),
              _buildRestoreSection(context, 'csv', 'CSV Transaction Ledger (.csv)', 'Re-apply transaction list and update balances.'),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRestoreSection(BuildContext context, String format, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12, width: 0.5),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E88E5),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _performRestore(context, format, 'drive'),
                  icon: const Icon(Icons.cloud_download_outlined, size: 16),
                  label: const Text('Google Drive', style: TextStyle(fontSize: 12)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                    foregroundColor: isDark ? Colors.white : Colors.black87,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: () => _performRestore(context, format, 'local'),
                  icon: const Icon(Icons.folder_open, size: 16),
                  label: const Text('Browse File', style: TextStyle(fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _performRestore(BuildContext context, String format, String destination) async {
    Navigator.pop(context); // Close bottom sheet

    if (!context.mounted) return;

    PlatformFile? prePickedFile;
    if (destination == 'local') {
      final pickerResult = await FilePicker.platform.pickFiles(
        type: FileType.any,
        withData: true,
      );
      if (pickerResult == null || pickerResult.files.isEmpty) {
        // User cancelled file selection or picker closed — do nothing
        return;
      }
      prePickedFile = pickerResult.files.single;
    }

    if (!context.mounted) return;

    // Show a blocking loading dialog ONLY after a file has been selected
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Restoring your data…\nPlease wait.')),
          ],
        ),
      ),
    );

    try {
      bool success = false;
      if (destination == 'local') {
        success = await BackupService.instance.restoreFromLocal(format, prePickedFile);
      } else {
        if (!BackupService.instance.isSignedIn && !BackupService.instance.isSimulatedMode) {
          final signedIn = await BackupService.instance.signIn();
          if (!signedIn) {
            if (context.mounted) Navigator.of(context, rootNavigator: true).pop(); // dismiss dialog
            if (context.mounted) {
              ToastNotification.show(context, 'Failed to sign in to Google Drive', isError: true);
            }
            return;
          }
        }
        success = await BackupService.instance.restoreFromGoogleDrive(format);
      }

      // Dismiss the loading dialog
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      if (!context.mounted) return;

      if (success) {
        // ── Step 1: Invalidate ALL data providers so they discard stale
        //    in-memory state and reload from the restored database on next read.
        ref.invalidate(accountsProvider);
        ref.invalidate(transactionsProvider);
        ref.invalidate(categoriesProvider);
        ref.invalidate(budgetsProvider);
        ref.invalidate(debtsProvider);
        ref.invalidate(savingsGoalsProvider);
        ref.invalidate(transactionTemplatesProvider);

        // ── Step 2: ALSO invalidate authProvider so the auth notifier is
        //    rebuilt fresh. Without this, checkProfile() still references the
        //    old (pre-restore) profile object in state, which causes PIN
        //    verification to use the wrong hash after restore.
        ref.invalidate(authProvider);
        // The new AuthNotifier constructor calls checkProfile() automatically,
        // which reads the restored database's user_profile and sets status to
        // AuthStatus.unauthenticated. GoRouter will then redirect to /login.

        if (!context.mounted) return;

        // ── Step 3: Show a clear success dialog so the user understands
        //    what just happened and what they need to do next.
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text('Restore Complete'),
              ],
            ),
            content: const Text(
              'Your database has been restored successfully.\n\n'
              'Please enter your PIN to access your data.',
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Enter PIN'),
              ),
            ],
          ),
        );

        // ── Step 4: Explicitly navigate to /login to guarantee the redirect
        //    happens even if GoRouter's refreshListenable is slightly delayed.
        if (context.mounted) {
          GoRouter.of(context).go('/login');
        }
      } else {
        if (context.mounted) {
          ToastNotification.show(
            context,
            'Restore failed. Please select a valid .db backup file.',
            isError: true,
          );
        }
      }
    } catch (e) {
      // Dismiss loading dialog if still open
      if (context.mounted) {
        try { Navigator.of(context, rootNavigator: true).pop(); } catch (_) {}
      }
      if (context.mounted) {
        ToastNotification.show(context, 'Restore error: $e', isError: true);
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasUnsavedChanges = _isEditingName && _nameController.text.trim() != profile.name;

    return PopScope(
      canPop: !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final discard = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(context).cardColor,
            title: const Text('Unsaved Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            content: const Text('You have unsaved changes in your profile name. Do you want to discard them?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Discard', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
        if (discard == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr(ref)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Section
            Text(
              'Profile Details',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _isEditingName
                        ? TextFormField(
                            controller: _nameController,
                            keyboardType: TextInputType.name,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                          )
                        : Text(
                            profile.name,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                  ),
                  _isEditingName
                      ? Row(
                          children: [
                            IconButton(
                              onPressed: _updateName,
                              icon: const Icon(Icons.check, color: Colors.green),
                            ),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _nameController.text = profile.name;
                                  _isEditingName = false;
                                });
                              },
                              icon: const Icon(Icons.close, color: Colors.red),
                            ),
                          ],
                        )
                      : IconButton(
                          onPressed: () => setState(() => _isEditingName = true),
                          icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                        ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Regional Settings Section
            Text(
              'Regional & Theme',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  // Currency dropdown
                  // Currency selection dialog trigger button (with search filter inside selection)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'preferred_currency'.tr(ref),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      InkWell(
                        onTap: () => _showCurrencyPickerDialog(context, profile.preferredCurrency),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isDark ? Colors.white10 : Colors.black12, width: 0.5),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                profile.preferredCurrency,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // Dark mode toggle
                  SwitchListTile(
                    value: profile.themePreference == 'dark',
                    activeColor: const Color(0xFFE53935),
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'dark_mode'.tr(ref),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    onChanged: _updateTheme,
                  ),
                  const Divider(height: 24, thickness: 0.5),

                  // Language dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'language'.tr(ref),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Theme(
                        data: Theme.of(context).copyWith(
                          canvasColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        ),
                        child: DropdownButton<String>(
                          value: ref.watch(localeProvider),
                          underline: const SizedBox(),
                          icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          items: const [
                            DropdownMenuItem(value: 'en', child: Text('English')),
                            DropdownMenuItem(value: 'es', child: Text('Español')),
                            DropdownMenuItem(value: 'hi', child: Text('हिन्दी')),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(localeProvider.notifier).setLocale(val);
                              ToastNotification.show(context, 'Language updated!');
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                ],
              ),
            ),

            const SizedBox(height: 24),

            // Security & Auth Section
            Text(
              'security_biometrics'.tr(ref),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SwitchListTile(
                value: profile.biometricEnabled,
                activeColor: const Color(0xFFE53935),
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'biometric_login'.tr(ref),
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: const Text(
                  'Verify fingerprint or face recognition upon opening the application.',
                  style: TextStyle(fontSize: 11),
                ),
                onChanged: _updateBiometric,
              ),
            ),

            const SizedBox(height: 24),

            // Backup & Restore Section
            Text(
              'database_backup'.tr(ref),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'backup_database'.tr(ref),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Backup your data as JSON, SQLite DB, or CSV ledger to Google Drive or Local Storage.',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.upload, color: Colors.grey),
                    onTap: () => _showBackupOptionsSheet(context),
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'restore_database'.tr(ref),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Restore database from Google Drive or Local Storage backup.',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.download, color: Colors.grey),
                    onTap: () => _showRestoreOptionsSheet(context),
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Google Drive Connection',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      BackupService.instance.isSignedIn
                          ? 'Signed in as ${BackupService.instance.currentUser?.email}'
                          : (BackupService.instance.isSimulatedMode 
                              ? 'Running in Sandbox Simulation Mode' 
                              : 'Secure your financial history on Google Drive.'),
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Icon(
                      BackupService.instance.isSignedIn || BackupService.instance.isSimulatedMode
                          ? Icons.cloud_done_outlined
                          : Icons.cloud_off_outlined,
                      color: BackupService.instance.isSignedIn || BackupService.instance.isSimulatedMode
                          ? Colors.green
                          : Colors.grey,
                    ),
                    onTap: () async {
                      if (BackupService.instance.isSignedIn || BackupService.instance.isSimulatedMode) {
                        await BackupService.instance.signOut();
                        if (!context.mounted) return;
                        setState(() {});
                        ToastNotification.show(context, 'Signed out of backup services.');
                      } else {
                        final success = await BackupService.instance.signIn();
                        if (!context.mounted) return;
                        setState(() {});
                        if (success) {
                          ToastNotification.show(
                            context,
                            'Google Drive Backup connected successfully!'
                          );
                        } else {
                          if (context.mounted) {
                            showDialog(
                              context: context,
                              builder: (BuildContext ctx) {
                                return AlertDialog(
                                  backgroundColor: Theme.of(context).cardColor,
                                  title: const Text('Connection Failed', style: TextStyle(fontWeight: FontWeight.bold)),
                                  content: const Text(
                                    'Could not connect to Google Drive. Would you like to use local Sandbox Simulation Mode instead?\n\n'
                                    'Note: Backups in Sandbox Mode will be stored locally on this device and will not sync to the cloud.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        BackupService.instance.enableSimulatedMode();
                                        Navigator.pop(ctx);
                                        setState(() {});
                                        ToastNotification.show(context, 'Sandbox Simulation Mode enabled.');
                                      },
                                      child: const Text('Enable Sandbox', style: TextStyle(color: Color(0xFFE53935), fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        }
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            GlassmorphismCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline, color: Color(0xFFE53935), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Backup & Restore Formats Info',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildFormatInfoItem(
                    'SQLite Database (.db)',
                    'A complete binary snapshot of the application state. Restoring from SQLite replaces all data including user profiles, settings, categories, and logs. Recommended for full device transfers.',
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildFormatInfoItem(
                    'JSON Export (.json)',
                    'A portable, human-readable file containing structured tables of your accounts, transactions, budgets, categories, and goals. Best format for backing up and restoring between different versions.',
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _buildFormatInfoItem(
                    'CSV Transaction Ledger (.csv)',
                    'A comma-separated plain text file containing only the transaction ledger entries (date, amount, category, account, tags, note). Easy to open and edit in Excel, Google Sheets, or Numbers.',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Reminders Section
            Text(
              'Daily Log Reminders',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black45,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  SwitchListTile(
                    value: profile.reminderEnabled,
                    activeColor: const Color(0xFFE53935),
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Daily Reminder Notification',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Sends a notification reminding you to log daily transactions.',
                      style: TextStyle(fontSize: 11),
                    ),
                    onChanged: _updateReminderToggle,
                  ),
                  if (profile.reminderEnabled) ...[
                    const Divider(height: 24, thickness: 0.5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Reminder Time',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        InkWell(
                          onTap: _selectReminderTime,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              DateHelpers.formatTime(profile.reminderTime),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFE53935)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 48),

            // Switch User Profile Button (always show to allow adding new profiles)
            if (ref.watch(authProvider).profiles.isNotEmpty) ...[
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02),
                  foregroundColor: isDark ? Colors.white70 : Colors.black87,
                  side: BorderSide(color: isDark ? Colors.white24 : Colors.black26, width: 1),
                  minimumSize: const Size(double.infinity, 54),
                ),
                onPressed: () {
                  ref.read(authProvider.notifier).showSelector();
                  ToastNotification.show(context, 'Switching profile...');
                },
                icon: const Icon(Icons.people),
                label: const Text('Switch User Profile'),
              ),
              const SizedBox(height: 16),
            ],

             // App Logout Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02),
                foregroundColor: const Color(0xFFE53935),
                side: const BorderSide(color: Color(0xFFE53935), width: 1),
                minimumSize: const Size(double.infinity, 54),
              ),
              onPressed: () {
                ref.read(authProvider.notifier).logout();
                ToastNotification.show(context, 'Logged out successfully.');
              },
              icon: const Icon(Icons.logout),
              label: const Text('Log Out / Lock Session'),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            const Text(
              'Danger Zone',
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFE53935),
                fontWeight: FontWeight.bold,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            GlassmorphismCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Delete Database',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFE53935)),
                    ),
                    subtitle: const Text(
                      'Permanently wipe all profiles, accounts, transactions, and settings. This cannot be undone.',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.delete_forever, color: Color(0xFFE53935)),
                    onTap: _confirmDeleteDatabase,
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Wipe & Uninstall App Data',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFFE53935)),
                    ),
                    subtitle: const Text(
                      'Wipe all application data to simulate an uninstall, with an option to backup your SQLite database file first.',
                      style: TextStyle(fontSize: 11),
                    ),
                    trailing: const Icon(Icons.phonelink_erase, color: Color(0xFFE53935)),
                    onTap: _uninstallAppData,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    ),
  );
}
}

class _CurrencyPickerDialog extends StatefulWidget {
  final List<String> currencies;
  final String initialCurrency;
  final ValueChanged<String> onSelected;

  const _CurrencyPickerDialog({
    required this.currencies,
    required this.initialCurrency,
    required this.onSelected,
  });

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  late List<String> _filteredCurrencies;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredCurrencies = widget.currencies;
    _searchController.addListener(_filterList);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterList() {
    final query = _searchController.text.toUpperCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCurrencies = widget.currencies;
      } else {
        _filteredCurrencies = widget.currencies
            .where((curr) => curr.contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161625) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select Currency',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _searchController,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'Search currency...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => _searchController.clear(),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: _filteredCurrencies.isEmpty
            ? const Center(
                child: Text(
                  'No currencies match your search.',
                  style: TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
                shrinkWrap: true,
                itemCount: _filteredCurrencies.length,
                itemBuilder: (context, index) {
                  final curr = _filteredCurrencies[index];
                  final isSelected = curr == widget.initialCurrency;
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    title: Text(
                      curr,
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? const Color(0xFFE53935) : null,
                      ),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: Color(0xFFE53935))
                        : null,
                    onTap: () {
                      widget.onSelected(curr);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
      ),
    );
  }
}

class _PinVerificationDialog extends StatefulWidget {
  final String correctPinHash;
  final VoidCallback onVerified;

  const _PinVerificationDialog({
    required this.correctPinHash,
    required this.onVerified,
  });

  @override
  State<_PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<_PinVerificationDialog> {
  String _pin = '';
  final int _pinLength = 4;
  bool _obscurePin = true;
  String? _errorMessage;

  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  void _onKeypadTap(String key) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += key;
      _errorMessage = null;
    });

    if (_pin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final inputHash = _hashPin(_pin);
    if (inputHash == widget.correctPinHash) {
      widget.onVerified();
    } else {
      setState(() {
        _pin = '';
        _errorMessage = 'Incorrect PIN. Verification failed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF161625) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Verify security PIN',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Enter your 4-digit profile PIN to confirm database deletion.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 24),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(_pinLength, (index) {
                  final active = index < _pin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE53935), width: 1.5),
                      color: active
                          ? const Color(0xFFE53935).withValues(alpha: _obscurePin ? 1.0 : 0.15)
                          : Colors.transparent,
                    ),
                    alignment: Alignment.center,
                    child: !_obscurePin && active
                        ? Text(
                            _pin[index],
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFFE53935)),
                          )
                        : null,
                  );
                }),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(
                  _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  color: Colors.grey,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ],
          ),
          
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFFE53935), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
          
          const SizedBox(height: 24),
          
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKeypadButton('1'),
                  _buildKeypadButton('2'),
                  _buildKeypadButton('3'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKeypadButton('4'),
                  _buildKeypadButton('5'),
                  _buildKeypadButton('6'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildKeypadButton('7'),
                  _buildKeypadButton('8'),
                  _buildKeypadButton('9'),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  const SizedBox(width: 60),
                  _buildKeypadButton('0'),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: IconButton(
                      onPressed: _onBackspace,
                      icon: const Icon(Icons.backspace_outlined, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: () => _onKeypadTap(digit),
          child: Center(
            child: Text(
              digit,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
            ),
          ),
        ),
      ),
    );
  }
}


