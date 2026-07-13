import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quick_actions/quick_actions.dart';
import '../common/premium_background.dart';
import '../../pages/transactions/transaction_form.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/partner_sync_provider.dart';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

class ScaffoldWithBottomNavBar extends ConsumerStatefulWidget {
  final Widget child;
  const ScaffoldWithBottomNavBar({super.key, required this.child});

  @override
  ConsumerState<ScaffoldWithBottomNavBar> createState() => _ScaffoldWithBottomNavBarState();
}

class _ScaffoldWithBottomNavBarState extends ConsumerState<ScaffoldWithBottomNavBar> {
  static const _channel = MethodChannel('com.example.money_manager/widget_actions');

  @override
  void initState() {
    super.initState();
    const QuickActions quickActions = QuickActions();
    quickActions.initialize((String shortcutType) {
      if (shortcutType == 'action_add_transaction') {
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _openTransactionForm();
          }
        });
      }
    });
    quickActions.setShortcutItems(<ShortcutItem>[
      const ShortcutItem(
        type: 'action_add_transaction',
        localizedTitle: 'Add Transaction',
        icon: 'ic_launcher',
      ),
    ]);

    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onWidgetAction') {
        final action = call.arguments as String?;
        if (action != null) {
          _handleWidgetAction(action);
        }
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialWidgetAction();
    });
  }

  Future<void> _checkInitialWidgetAction() async {
    try {
      final action = await _channel.invokeMethod<String>('getWidgetAction');
      if (action != null) {
        _handleWidgetAction(action);
      }
    } catch (_) {}
  }

  void _handleWidgetAction(String action) {
    String? type;
    if (action == 'add_expense') type = 'expense';
    if (action == 'add_income') type = 'income';
    if (action == 'add_transfer') type = 'transfer';
    
    if (type != null) {
      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) {
          _openTransactionForm(initialType: type);
        }
      });
    }
  }

  void _openTransactionForm({String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(initialType: initialType),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/transactions')) return 1;
    if (location.startsWith('/accounts')) return 2;
    if (location.startsWith('/budgets')) return 3;
    if (location.startsWith('/partners')) return 4;
    if (location.startsWith('/settings')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        GoRouter.of(context).go('/dashboard');
        break;
      case 1:
        GoRouter.of(context).go('/transactions');
        break;
      case 2:
        GoRouter.of(context).go('/accounts');
        break;
      case 3:
        GoRouter.of(context).go('/budgets');
        break;
      case 4:
        GoRouter.of(context).go('/partners');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _calculateSelectedIndex(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final budgetsState = ref.watch(budgetsProvider);
    final partnerSyncState = ref.watch(partnerSyncProvider);

    // Check if any budget is overspent
    bool isAnyBudgetOverspent = false;
    for (var b in budgetsState.budgets) {
      final spent = budgetsState.categorySpendings[b.categoryId] ?? 0.0;
      final limit = b.limitAmount;
      if (spent > limit) {
        isAnyBudgetOverspent = true;
        break;
      }
    }

    // Check if any sync conflicts exist
    bool isAnySyncConflict = partnerSyncState.conflicts.isNotEmpty;
    
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        // If there are subpages in the navigation stack, pop them first instead of exiting
        if (context.mounted && GoRouter.of(context).canPop()) {
          GoRouter.of(context).pop();
          return;
        }

        final shouldExit = await _showExitBackupDialog(context);
        if (shouldExit == true) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: GestureDetector(
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            if (details.primaryVelocity! < -500) {
              // Swipe left -> Next tab
              final nextIndex = (selectedIndex + 1) % 5;
              _onItemTapped(nextIndex, context);
            } else if (details.primaryVelocity! > 500) {
              // Swipe right -> Prev tab
              final prevIndex = (selectedIndex - 1 + 5) % 5;
              _onItemTapped(prevIndex, context);
            }
          },
          behavior: HitTestBehavior.translucent,
          child: PremiumBackground(child: widget.child),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
          ),
          child: BottomNavigationBar(
            items: [
              const BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Dashboard',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.receipt_long_outlined),
                activeIcon: Icon(Icons.receipt_long),
                label: 'Ledger',
              ),
              const BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet_outlined),
                activeIcon: Icon(Icons.account_balance_wallet),
                label: 'Accounts',
              ),
              BottomNavigationBarItem(
                icon: isAnyBudgetOverspent
                    ? const Badge(
                        label: Text('!'),
                        child: Icon(Icons.map_outlined),
                      )
                    : const Icon(Icons.map_outlined),
                activeIcon: isAnyBudgetOverspent
                    ? const Badge(
                        label: Text('!'),
                        child: Icon(Icons.map),
                      )
                    : const Icon(Icons.map),
                label: 'Money Map',
              ),
              BottomNavigationBarItem(
                icon: isAnySyncConflict
                    ? const Badge(
                        label: Text('!'),
                        child: Icon(Icons.grid_view_rounded),
                      )
                    : const Icon(Icons.grid_view_rounded),
                activeIcon: isAnySyncConflict
                    ? const Badge(
                        label: Text('!'),
                        child: Icon(Icons.grid_view_rounded),
                      )
                    : const Icon(Icons.grid_view_rounded),
                label: 'More',
              ),
            ],
            currentIndex: selectedIndex,
            onTap: (index) => _onItemTapped(index, context),
          ),
        ),
      ),
    );
  }

  Future<bool?> _showExitBackupDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text('Backup Required'),
            ],
          ),
          content: const Text(
            'If you uninstall the app, all local data will be permanently lost.\n\n'
            'Would you like to back up your database (.db) to your local files before exiting?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Exit Without Backup', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                Navigator.pop(context, false); // close dialog
                final success = await _backupDatabaseBeforeExit();
                if (success) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup saved successfully! Exiting app...'), backgroundColor: Colors.green),
                    );
                    Future.delayed(const Duration(milliseconds: 800), () {
                      SystemNavigator.pop();
                    });
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to save backup.'), backgroundColor: Colors.redAccent),
                    );
                  }
                }
              },
              child: const Text('Back Up Now'),
            ),
          ],
        );
      },
    );
  }

  Future<bool> _backupDatabaseBeforeExit() async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}_${now.month.toString().padLeft(2, '0')}_${now.day.toString().padLeft(2, '0')}';
      final fileName = 'money_manager_backup_$dateStr.db';

      final dbFolder = await getApplicationDocumentsDirectory();
      final localDbPath = p.join(dbFolder.path, 'money_manager.db');
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
      final tempFile = File(p.join(tempDir.path, fileName));
      await tempFile.writeAsBytes(bytes);

      await Share.shareXFiles(
        [XFile(tempFile.path, mimeType: 'application/octet-stream')],
        subject: 'Money Manager Exit Backup',
      );
      return true;
    } catch (e) {
      print('Error during _backupDatabaseBeforeExit: $e');
      return false;
    }
  }
}
