import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../categories/categories_page.dart';
import '../savings/savings_goals_page.dart';
import '../debts/debts_page.dart';
import '../../widgets/common/glassmorphism_card.dart';

// Class representation of a feature in the More page
class FeatureItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onTap;
  final String routeName;

  FeatureItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradientColors,
    required this.onTap,
    required this.routeName,
  });
}

// Provider to keep track of recently accessed features
final recentlyUsedProvider = StateNotifierProvider<RecentlyUsedNotifier, List<String>>((ref) {
  return RecentlyUsedNotifier();
});

class RecentlyUsedNotifier extends StateNotifier<List<String>> {
  RecentlyUsedNotifier() : super(['/settings', '/user-guide', 'categories']); // Initial shortcuts

  void addFeature(String routeName) {
    final current = List<String>.from(state);
    current.remove(routeName);
    current.insert(0, routeName);
    if (current.length > 3) {
      current.removeLast();
    }
    state = current;
  }
}

class MorePage extends ConsumerStatefulWidget {
  const MorePage({Key? key}) : super(key: key);

  @override
  ConsumerState<MorePage> createState() => _MorePageState();
}

class _MorePageState extends ConsumerState<MorePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF5F5F5);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    // List of all features available
    final List<FeatureItem> allFeatures = [
      FeatureItem(
        label: 'User Guide & Help',
        subtitle: 'Learn how to use profiles, security, budgets, and goals',
        icon: Icons.menu_book_outlined,
        gradientColors: [const Color(0xFFFF9800), const Color(0xFFFF5722)],
        routeName: '/user-guide',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('/user-guide');
          context.push('/user-guide');
        },
      ),
      FeatureItem(
        label: 'Settings',
        subtitle: 'Preferences & backup',
        icon: Icons.settings_outlined,
        gradientColors: [const Color(0xFF6C63FF), const Color(0xFF3F51B5)],
        routeName: '/settings',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('/settings');
          context.push('/settings');
        },
      ),
      FeatureItem(
        label: 'Categories',
        subtitle: 'Manage P2P & types',
        icon: Icons.category_outlined,
        gradientColors: [const Color(0xFF9C27B0), const Color(0xFFE91E63)],
        routeName: 'categories',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('categories');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CategoriesPage()),
          );
        },
      ),
      FeatureItem(
        label: 'Savings Goals',
        subtitle: 'Optimize targets',
        icon: Icons.track_changes,
        gradientColors: [const Color(0xFFE91E63), const Color(0xFFFF2E93)],
        routeName: 'savings-goals',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('savings-goals');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const SavingsGoalsPage()),
          );
        },
      ),
      FeatureItem(
        label: 'Debt Tracker',
        subtitle: 'Payoffs & rates',
        icon: Icons.money_off_csred_outlined,
        gradientColors: [const Color(0xFFFF5722), const Color(0xFFFF8A65)],
        routeName: 'debt-tracker',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('debt-tracker');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const DebtsPage()),
          );
        },
      ),
      FeatureItem(
        label: 'Trend Analytics',
        subtitle: 'Forecasts & metrics',
        icon: Icons.trending_up,
        gradientColors: [const Color(0xFF3F51B5), const Color(0xFF2196F3)],
        routeName: '/analytics',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('/analytics');
          context.push('/analytics');
        },
      ),
      FeatureItem(
        label: 'Advanced Analytics',
        subtitle: 'YoY & Timelines',
        icon: Icons.analytics_outlined,
        gradientColors: [const Color(0xFF1E88E5), const Color(0xFF00BCD4)],
        routeName: '/analytics-advanced',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('/analytics-advanced');
          context.push('/analytics-advanced');
        },
      ),
      FeatureItem(
        label: 'Account Comparison',
        subtitle: 'Side-by-side performance comparison',
        icon: Icons.compare_arrows_outlined,
        gradientColors: [const Color(0xFF4CAF50), const Color(0xFF8BC34A)],
        routeName: '/account-comparison',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('/account-comparison');
          context.push('/account-comparison');
        },
      ),
      FeatureItem(
        label: 'Partner Sharing',
        subtitle: 'Sync accounts & transactions with your partner',
        icon: Icons.people_outline,
        gradientColors: [const Color(0xFFE53935), const Color(0xFFFF5252)],
        routeName: '/partner-sharing',
        onTap: () {
          ref.read(recentlyUsedProvider.notifier).addFeature('/partner-sharing');
          context.push('/partner-sharing');
        },
      ),
    ];

    // Filter features by query
    final filteredFeatures = allFeatures.where((item) {
      return item.label.toLowerCase().contains(_searchQuery) ||
          item.subtitle.toLowerCase().contains(_searchQuery);
    }).toList();

    // Get recently used items
    final recentlyUsedRoutes = ref.watch(recentlyUsedProvider);
    final recentlyUsedFeatures = recentlyUsedRoutes
        .map((route) => allFeatures.firstWhere((item) => item.routeName == route,
            orElse: () => allFeatures.first))
        .toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        title: Text(
          'More',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: textColor,
          ),
        ),
      ),
      body: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutQuart,
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, 30 * (1 - value)),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Search Input Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search features...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: isDark ? Colors.white10 : Colors.black12,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: Color(0xFFE53935),
                      width: 1,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Recently Used section (only visible when not searching)
              if (_searchQuery.isEmpty && recentlyUsedFeatures.isNotEmpty) ...[
                Text(
                  'Recently Used',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: isDark ? Colors.white54 : Colors.black45,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: recentlyUsedFeatures.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final item = recentlyUsedFeatures[index];
                      return _buildRecentCard(context, item);
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],



              // All Features list or Grid
              Text(
                _searchQuery.isEmpty ? 'All Features' : 'Search Results',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),

              if (_searchQuery.isNotEmpty) ...[
                if (filteredFeatures.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text(
                        'No matching features found.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                    ),
                  )
                else
                  // Render filtered list of wide cards
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredFeatures.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filteredFeatures[index];
                      return _buildWideCard(context, item);
                    },
                  )
              ] else ...[
                // Original Custom Premium Grid Layout
                _buildWideCard(context, allFeatures[0]), // User Guide
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSquareCard(context, allFeatures[1])), // Settings
                    const SizedBox(width: 12),
                    Expanded(child: _buildSquareCard(context, allFeatures[2])), // Categories
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSquareCard(context, allFeatures[3])), // Savings
                    const SizedBox(width: 12),
                    Expanded(child: _buildSquareCard(context, allFeatures[4])), // Debt
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _buildSquareCard(context, allFeatures[5])), // Trend
                    const SizedBox(width: 12),
                    Expanded(child: _buildSquareCard(context, allFeatures[6])), // Advanced
                  ],
                ),
                const SizedBox(height: 12),
                _buildWideCard(context, allFeatures[7]), // Account comparison
                const SizedBox(height: 12),
                _buildWideCard(context, allFeatures[8]), // Partner sharing
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentCard(BuildContext context, FeatureItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 130,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: item.gradientColors.map((c) => c.withOpacity(0.85)).toList(),
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: item.gradientColors[0].withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(item.icon, color: Colors.white, size: 20),
            Text(
              item.label,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.white,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSquareCard(BuildContext context, FeatureItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        height: 145,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: item.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: item.gradientColors[0].withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(item.icon, color: Colors.white, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.label,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10,
                    color: Colors.white.withOpacity(0.8),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWideCard(BuildContext context, FeatureItem item) {
    return GestureDetector(
      onTap: item.onTap,
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            colors: item.gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: item.gradientColors[0].withOpacity(0.25),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(item.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.85),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withOpacity(0.8),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }


}
