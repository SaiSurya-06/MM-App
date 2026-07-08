import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'widgets/common/premium_background.dart';
import 'widgets/common/premium_error_widget.dart';

import 'widgets/navigation/scaffold_with_bottom_nav_bar.dart';

// Pages
import 'pages/auth/pin_setup_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/dashboard/dashboard_page.dart';
import 'pages/accounts/accounts_page.dart';
import 'pages/transactions/transactions_page.dart';
import 'pages/budgets/budgets_page.dart';
import 'pages/more/more_page.dart';
import 'pages/more/user_guide_page.dart';
import 'pages/settings/settings_page.dart';
import 'pages/transactions/transaction_form.dart';
import 'pages/analytics/trend_analytics_page.dart';
import 'pages/analytics/analytics_advanced_page.dart';
import 'pages/accounts/account_comparison_page.dart';
import 'pages/partners/partners_page.dart';
import 'pages/partners/partner_detail_page.dart';
import 'models/account.dart';
import 'package:quick_actions/quick_actions.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<NavigatorState> _shellNavigatorKey = GlobalKey<NavigatorState>();

class _RouterNotifier extends ChangeNotifier {
  void update() {
    notifyListeners();
  }
}

class MoneyManagerApp extends ConsumerStatefulWidget {
  const MoneyManagerApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MoneyManagerApp> createState() => _MoneyManagerAppState();
}

class _MoneyManagerAppState extends ConsumerState<MoneyManagerApp> {
  late final _RouterNotifier _routerNotifier;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _routerNotifier = _RouterNotifier();
    _router = GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: '/dashboard',
      refreshListenable: _routerNotifier,
      redirect: (context, state) {
        final authState = ref.read(authProvider);
        final status = authState.status;
        final isLoggingIn = state.matchedLocation == '/login' ||
            state.matchedLocation == '/pin-setup';

        if (status == AuthStatus.undetermined) {
          return null; // Show nothing or loading spinner
        }

        if (status == AuthStatus.pinSetupRequired) {
          return state.matchedLocation == '/pin-setup' ? null : '/pin-setup';
        }

        if (status == AuthStatus.unauthenticated) {
          return state.matchedLocation == '/login' ? null : '/login';
        }

        // If authenticated but trying to go to login pages, redirect to dashboard
        if (status == AuthStatus.authenticated && isLoggingIn) {
          return '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/pin-setup',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PinSetupPage(),
        ),
        GoRoute(
          path: '/login',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const LoginPage(),
        ),
        GoRoute(
          path: '/analytics',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const TrendAnalyticsPage(),
        ),
        GoRoute(
          path: '/analytics-advanced',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AnalyticsAdvancedPage(),
        ),
        GoRoute(
          path: '/user-guide',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const UserGuidePage(),
        ),
        GoRoute(
          path: '/account-comparison',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const AccountComparisonPage(),
        ),
        GoRoute(
          path: '/partner-sharing',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) => const PartnersPage(),
        ),
        GoRoute(
          path: '/partner-sharing/account-detail',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (context, state) {
            final account = state.extra as Account;
            return PartnerDetailPage(account: account);
          },
        ),
        
        // Shell navigation for main pages
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) {
            return ScaffoldWithBottomNavBar(child: child);
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: DashboardPage(),
              ),
            ),
            GoRoute(
              path: '/transactions',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: TransactionsPage(),
              ),
            ),
            GoRoute(
              path: '/accounts',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: AccountsPage(),
              ),
            ),
            GoRoute(
              path: '/budgets',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: BudgetsPage(),
              ),
            ),
            GoRoute(
              path: '/partners',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: MorePage(),
              ),
            ),
            GoRoute(
              path: '/settings',
              pageBuilder: (context, state) => const NoTransitionPage(
                child: SettingsPage(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    // Listen to changes to authProvider and notify the router notifier on status change
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.status != next.status || previous?.profile?.id != next.profile?.id) {
        _routerNotifier.update();
      }
    });

    // Dynamic theme selection
    final themePref = authState.profile?.themePreference ?? 'dark';
    final themeMode = themePref == 'light' ? ThemeMode.light : ThemeMode.dark;

    if (authState.status == AuthStatus.undetermined) {
      return MaterialApp(
        title: 'Money Manager',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFE53935),
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'Money Manager',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}



