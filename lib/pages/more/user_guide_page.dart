import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';
import '../../widgets/common/toast_notification.dart';
import '../categories/categories_page.dart';
import '../savings/savings_goals_page.dart';
import '../debts/debts_page.dart';

class UserGuidePage extends StatefulWidget {
  const UserGuidePage({super.key});

  @override
  State<UserGuidePage> createState() => _UserGuidePageState();
}

class _UserGuidePageState extends State<UserGuidePage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isLoading = true;
  List<Map<String, dynamic>> _guideItems = [];

  final List<String> _categories = [
    'All',
    'Security',
    'Transactions',
    'Accounts',
    'Budgets',
    'Goals',
    'Analytics',
    'Sync',
    'Settings',
    'Categories'
  ];

  @override
  void initState() {
    super.initState();
    _loadGuideData();
  }

  Future<void> _loadGuideData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/user_guide.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);
      setState(() {
        _guideItems = jsonList.map((item) {
          final map = Map<String, dynamic>.from(item);
          // Parse hex color string to Color
          final colorHex = map['color'] as String;
          map['color'] = Color(int.parse(colorHex));
          // Parse icon string to IconData
          map['icon'] = _getIconData(map['icon'] as String);
          return map;
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ToastNotification.show(context, 'Failed to load user guide: $e', isError: true);
      }
    }
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'people_outline':
        return Icons.people_outline;
      case 'lock_outline':
        return Icons.lock_outline;
      case 'call_split':
        return Icons.call_split;
      case 'import_export':
        return Icons.import_export;
      case 'credit_card_outlined':
        return Icons.credit_card_outlined;
      case 'pie_chart_outline':
        return Icons.pie_chart_outline;
      case 'track_changes':
        return Icons.track_changes;
      case 'analytics_outlined':
        return Icons.analytics_outlined;
      case 'sync':
        return Icons.sync;
      case 'settings_brightness':
        return Icons.settings_brightness;
      case 'person_pin':
        return Icons.person_pin;
      default:
        return Icons.help_outline;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0D0D0D) : const Color(0xFFF8F9FA);
    final cardBg = isDark ? const Color(0xFF161625) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    // Filter items based on category and search query
    final filteredItems = _guideItems.where((item) {
      final matchesCategory = _selectedCategory == 'All' || item['category'] == _selectedCategory;
      final matchesSearch = item['title'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          item['summary'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (item['steps'] as List<dynamic>).any((step) => (step as String).toLowerCase().contains(_searchQuery.toLowerCase()));
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'User Guide & Help',
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: PremiumBackground(
        child: TweenAnimationBuilder<double>(
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Search Bar
                Container(
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(color: textColor, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'Search help articles...',
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.black38),
                      prefixIcon: const Icon(Icons.search, color: Colors.grey),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onChanged: (val) {
                      setState(() => _searchQuery = val);
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Category chips
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, idx) {
                      final cat = _categories[idx];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(
                            cat,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: const Color(0xFFE53935),
                          backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.04),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Guide Items List
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (filteredItems.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.search_off, size: 48, color: Colors.grey.withValues(alpha: 0.5)),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'No matching guide articles found.',
                                          style: TextStyle(color: Colors.grey, fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else
                                ...filteredItems.map((item) {
                                  final routeStr = item['route'] as String?;
                                  final hasRoute = routeStr != null && routeStr.isNotEmpty;
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: GlassmorphismCard(
                                      padding: EdgeInsets.zero,
                                      child: ExpansionTile(
                                        title: Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: (item['color'] as Color).withValues(alpha: 0.12),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                item['icon'] as IconData,
                                                color: item['color'] as Color,
                                                size: 18,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                item['title'] as String,
                                                style: TextStyle(
                                                  fontFamily: 'Inter',
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.only(left: 38.0, top: 4.0),
                                          child: Text(
                                            item['summary'] as String,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? Colors.white54 : Colors.black45,
                                            ),
                                          ),
                                        ),
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0, top: 8.0),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                ...(item['steps'] as List<dynamic>).map((step) {
                                                  return Padding(
                                                    padding: const EdgeInsets.only(bottom: 8.0),
                                                    child: Row(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Container(
                                                          margin: const EdgeInsets.only(top: 5),
                                                          width: 6,
                                                          height: 6,
                                                          decoration: BoxDecoration(
                                                            color: item['color'] as Color,
                                                            shape: BoxShape.circle,
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            step as String,
                                                            style: TextStyle(
                                                              fontSize: 12,
                                                              height: 1.4,
                                                              color: isDark ? Colors.white70 : Colors.black87,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                }),
                                                if (hasRoute) ...[
                                                  const SizedBox(height: 12),
                                                  Center(
                                                    child: ElevatedButton.icon(
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: item['color'] as Color,
                                                        foregroundColor: Colors.white,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                                      ),
                                                      onPressed: () {
                                                        if (routeStr.startsWith('/')) {
                                                          GoRouter.of(context).go(routeStr);
                                                        } else {
                                                          if (routeStr == 'savings-goals') {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (context) => const SavingsGoalsPage()),
                                                            );
                                                          } else if (routeStr == 'categories') {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (context) => const CategoriesPage()),
                                                            );
                                                          } else if (routeStr == 'debt-tracker') {
                                                            Navigator.push(
                                                              context,
                                                              MaterialPageRoute(builder: (context) => const DebtsPage()),
                                                            );
                                                          }
                                                        }
                                                      },
                                                      icon: const Icon(Icons.open_in_new, size: 16),
                                                      label: Text('Go to ${item['category']}'),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
