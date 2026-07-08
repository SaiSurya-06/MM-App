import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category.dart';
import '../../../providers/categories_provider.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import 'category_form.dart';

class CategoriesPage extends ConsumerWidget {
  const CategoriesPage({super.key});

  void _openCategoryForm(BuildContext context, [Category? category]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryForm(category: category),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesState = ref.watch(categoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openCategoryForm(context),
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: categoriesState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : () {
              final expenseCategories = categoriesState.categories.where((c) => c.type == 'expense' && c.parentId == null).toList();
              final incomeCategories = categoriesState.categories.where((c) => c.type == 'income' && c.parentId == null).toList();
              final bothCategories = categoriesState.categories.where((c) => c.type == 'both' && c.parentId == null).toList();
              final personCategories = categoriesState.categories.where((c) => c.type == 'person' && c.parentId == null).toList();

              // Get sub-categories maps
              final Map<int, List<Category>> subCategories = {};
              for (var c in categoriesState.categories) {
                if (c.parentId != null) {
                  subCategories.putIfAbsent(c.parentId!, () => []).add(c);
                }
              }

              return ListView(
                padding: const EdgeInsets.all(20.0),
                children: [
                  if (expenseCategories.isNotEmpty) ...[
                    _buildSectionHeader('Expense Categories', isDark),
                    const SizedBox(height: 10),
                    ...expenseCategories.expand((cat) => [
                      _buildCategoryTile(context, ref, cat, isDark),
                      if (subCategories.containsKey(cat.id))
                        ...subCategories[cat.id]!.map((sub) => Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: _buildCategoryTile(context, ref, sub, isDark),
                        )),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  if (incomeCategories.isNotEmpty) ...[
                    _buildSectionHeader('Income Categories', isDark),
                    const SizedBox(height: 10),
                    ...incomeCategories.expand((cat) => [
                      _buildCategoryTile(context, ref, cat, isDark),
                      if (subCategories.containsKey(cat.id))
                        ...subCategories[cat.id]!.map((sub) => Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: _buildCategoryTile(context, ref, sub, isDark),
                        )),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  if (personCategories.isNotEmpty) ...[
                    _buildSectionHeader('Person to Person (P2P) Categories', isDark),
                    const SizedBox(height: 10),
                    ...personCategories.expand((cat) => [
                      _buildCategoryTile(context, ref, cat, isDark),
                      if (subCategories.containsKey(cat.id))
                        ...subCategories[cat.id]!.map((sub) => Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: _buildCategoryTile(context, ref, sub, isDark),
                        )),
                    ]),
                    const SizedBox(height: 20),
                  ],
                  if (bothCategories.isNotEmpty) ...[
                    _buildSectionHeader('Expense & Income Categories', isDark),
                    const SizedBox(height: 10),
                    ...bothCategories.expand((cat) => [
                      _buildCategoryTile(context, ref, cat, isDark),
                      if (subCategories.containsKey(cat.id))
                        ...subCategories[cat.id]!.map((sub) => Padding(
                          padding: const EdgeInsets.only(left: 24.0),
                          child: _buildCategoryTile(context, ref, sub, isDark),
                        )),
                    ]),
                    const SizedBox(height: 20),
                  ],
                ],
              );
            }(),
    );
  }

  Widget _buildCategoryTile(BuildContext context, WidgetRef ref, Category category, bool isDark) {
    final hex = '0xFF${category.color.replaceAll("#", "")}';
    final color = Color(int.tryParse(hex) ?? 0xFF757575);
    final iconData = CategoryIconHelper.getIcon(category.icon);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Dismissible(
        key: Key('category_${category.id}'),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Category'),
              content: Text('Are you sure you want to delete "${category.name}"? Transactions linked to this category will become uncategorized.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE53935),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
        onDismissed: (direction) async {
          final success = await ref.read(categoriesProvider.notifier).deleteCategory(category.id!);
          if (success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category "${category.name}" deleted.'),
                backgroundColor: const Color(0xFF1E1E2E),
              ),
            );
          }
        },
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.delete, color: Colors.white),
        ),
        child: InkWell(
          onTap: () => _openCategoryForm(context, category),
          borderRadius: BorderRadius.circular(16),
          child: GlassmorphismCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            color: isDark ? color.withValues(alpha: 0.06) : color.withValues(alpha: 0.04),
            borderColor: color.withValues(alpha: 0.12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        iconData,
                        color: color,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            category.type == 'both' ? 'EXPENSE & INCOME' : category.type.toUpperCase(),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Icon(Icons.edit_outlined, color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.white54 : Colors.black45,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}
