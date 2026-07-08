import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/category.dart';
import '../../../providers/categories_provider.dart';
import '../../../core/utils/category_icon_helper.dart';
import '../../../widgets/common/toast_notification.dart';
import '../../../widgets/common/glassmorphism_card.dart';

class CategoryForm extends ConsumerStatefulWidget {
  final Category? category;

  const CategoryForm({super.key, this.category});

  @override
  ConsumerState<CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _spendingLimitController;
  int? _selectedParentId;
  late String _selectedType; // 'income', 'expense', 'both'
  late String _selectedIcon;
  late String _selectedColor;
  String _iconSearchQuery = '';

  final List<String> _colors = [
    'E53935', // Red
    '4CAF50', // Green
    '1E88E5', // Blue
    'FFB300', // Amber
    '8E24AA', // Purple
    '00ACC1', // Cyan
    'FB8C00', // Orange
    'F06292', // Pink
    '4DB6AC', // Teal
    '795548', // Brown
    '757575', // Grey
    '3F51B5', // Indigo
  ];

  late List<String> _icons;

  String _getDarkVariant(String lightHex) {
    switch (lightHex.toUpperCase()) {
      case 'E53935': return 'B71C1C';
      case '4CAF50': return '1B5E20';
      case '1E88E5': return '0D47A1';
      case 'FFB300': return 'FF6F00';
      case '8E24AA': return '4A148C';
      case '00ACC1': return '006064';
      case 'FB8C00': return 'E65100';
      case 'F06292': return '880E4F';
      case '4DB6AC': return '004D40';
      case '795548': return '3E2723';
      case '757575': return '212121';
      case '3F51B5': return '1A237E';
      default: return '212121';
    }
  }

  @override
  void initState() {
    super.initState();
    final cat = widget.category;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _nameController.addListener(() {
      if (mounted) setState(() {});
    });
    _spendingLimitController = TextEditingController(
      text: cat?.spendingLimit != null ? cat!.spendingLimit.toString() : '',
    );
    _selectedParentId = cat?.parentId;
    _selectedType = cat?.type ?? 'expense';
    _selectedIcon = cat?.icon ?? 'category';
    _selectedColor = cat?.color ?? '757575';
    _icons = CategoryIconHelper.getSelectableIcons();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _spendingLimitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final isEdit = widget.category != null;
    final limitText = _spendingLimitController.text.trim();
    final spendingLimit = limitText.isNotEmpty ? double.tryParse(limitText) : null;

    bool success;
    if (isEdit) {
      final updated = widget.category!.copyWith(
        name: name,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
        parentId: _selectedParentId,
        spendingLimit: spendingLimit,
        darkColor: _getDarkVariant(_selectedColor),
      );
      success = await ref.read(categoriesProvider.notifier).updateCategory(updated);
    } else {
      final newCat = Category(
        name: name,
        type: _selectedType,
        icon: _selectedIcon,
        color: _selectedColor,
        isDefault: false,
        parentId: _selectedParentId,
        spendingLimit: spendingLimit,
        darkColor: _getDarkVariant(_selectedColor),
      );
      final newId = await ref.read(categoriesProvider.notifier).addCategory(newCat);
      success = newId != null;
    }

    if (success && mounted) {
      ToastNotification.show(
        context,
        isEdit ? 'Category updated successfully!' : 'Category created successfully!',
      );
      Navigator.pop(context, true);
    } else if (mounted) {
      final error = ref.read(categoriesProvider).errorMessage ?? 'An error occurred';
      ToastNotification.show(context, error, isError: true);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: const Text(
          'Are you sure you want to delete this category? All transactions and budgets under this category will be automatically reassigned to another remaining category.',
        ),
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

    if (confirmed == true && widget.category?.id != null && mounted) {
      final success = await ref.read(categoriesProvider.notifier).deleteCategory(widget.category!.id!);
      if (success && mounted) {
        ToastNotification.show(context, 'Category deleted.');
        Navigator.pop(context, true); // Pop the form sheet
      } else if (mounted) {
        final error = ref.read(categoriesProvider).errorMessage ?? 'Deletion failed';
        ToastNotification.show(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161625) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Bar Indicator
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

              Text(
                widget.category == null ? 'Create Category' : 'Edit Category',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(height: 16),

              // Live Preview Card
              const Text(
                'Live Preview',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final hex = '0xFF${_selectedColor.replaceAll("#", "")}';
                  final color = Color(int.tryParse(hex) ?? 0xFF757575);
                  final iconData = CategoryIconHelper.getIcon(_selectedIcon);
                  final name = _nameController.text.trim().isEmpty ? 'Category Name' : _nameController.text;
                  final displayType = _selectedType == 'both' ? 'EXPENSE & INCOME' : _selectedType.toUpperCase();
                  
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    child: GlassmorphismCard(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      color: isDark ? color.withValues(alpha: 0.08) : color.withValues(alpha: 0.05),
                      borderColor: color.withValues(alpha: 0.18),
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
                                    name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      fontFamily: 'Inter',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      displayType,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          Icon(iconData, color: color.withValues(alpha: 0.4), size: 24),
                        ],
                      ),
                    ),
                  );
                }
              ),
              const SizedBox(height: 8),

              // Name Field
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Category Name',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter a name';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Type Selector Row
              const Text(
                'Category Type',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeButton('expense', 'Expense', const Color(0xFFE53935)),
                  const SizedBox(width: 6),
                  _buildTypeButton('income', 'Income', Colors.green),
                  const SizedBox(width: 6),
                  _buildTypeButton('both', 'Both', Colors.blue),
                  const SizedBox(width: 6),
                  _buildTypeButton('person', 'Person', Colors.purple),
                ],
              ),
              const SizedBox(height: 20),

              // Color Selector
              const Text(
                'Select Color',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final colorHex = _colors[index];
                    final color = Color(int.parse('0xFF$colorHex'));
                    final isSelected = _selectedColor == colorHex;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = colorHex),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 8, spreadRadius: 1)]
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Icon Selector with Search
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Icon',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  SizedBox(
                    width: 150,
                    height: 32,
                    child: TextField(
                      onChanged: (val) {
                        setState(() {
                          _iconSearchQuery = val.toLowerCase().trim();
                        });
                      },
                      style: const TextStyle(fontSize: 12),
                      decoration: InputDecoration(
                        hintText: 'Search icons...',
                        hintStyle: const TextStyle(fontSize: 12),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        prefixIcon: const Icon(Icons.search, size: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.04),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
                ),
                padding: const EdgeInsets.all(12),
                child: () {
                  final filteredIcons = _icons.where((iconKey) => iconKey.toLowerCase().contains(_iconSearchQuery)).toList();
                  if (filteredIcons.isEmpty) {
                    return const Center(
                      child: Text(
                        'No icons found',
                        style: TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                    );
                  }
                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: filteredIcons.length,
                    itemBuilder: (context, index) {
                      final iconKey = filteredIcons[index];
                      final iconData = CategoryIconHelper.getIcon(iconKey);
                      final isSelected = _selectedIcon == iconKey;
                      final cardColor = Color(int.parse('0xFF$_selectedColor'));

                      return GestureDetector(
                        onTap: () => setState(() => _selectedIcon = iconKey),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? cardColor.withValues(alpha: 0.2) : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected ? Border.all(color: cardColor, width: 2) : null,
                          ),
                          child: Icon(
                            iconData,
                            color: isSelected ? cardColor : (isDark ? Colors.white70 : Colors.black54),
                            size: 20,
                          ),
                        ),
                      );
                    },
                  );
                }(),
              ),
              const SizedBox(height: 20),

              // Parent Category & Spending Limit
              () {
                final categoriesState = ref.watch(categoriesProvider);
                final allCategories = categoriesState.categories;

                Set<int> getDescendantIds(int parentId, List<Category> allCats) {
                  final descendants = <int>{};
                  void traverse(int pid) {
                    for (var c in allCats) {
                      if (c.parentId == pid && c.id != null) {
                        if (descendants.add(c.id!)) {
                          traverse(c.id!);
                        }
                      }
                    }
                  }
                  traverse(parentId);
                  return descendants;
                }

                final descendants = widget.category?.id != null
                    ? getDescendantIds(widget.category!.id!, allCategories)
                    : <int>{};

                final parentCategories = allCategories.where((c) {
                  if (c.id == null) return false;
                  final isOwn = widget.category != null && c.id == widget.category!.id;
                  final isDescendant = descendants.contains(c.id);
                  return c.parentId == null && !isOwn && !isDescendant;
                }).toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (parentCategories.isNotEmpty) ...[
                      DropdownButtonFormField<int?>(
                        value: _selectedParentId,
                        decoration: const InputDecoration(
                          labelText: 'Parent Category (Optional)',
                          prefixIcon: Icon(Icons.folder_open),
                        ),
                        dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                        items: [
                          const DropdownMenuItem<int?>(
                            value: null,
                            child: Text('None (Primary Category)'),
                          ),
                          ...parentCategories.map((c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          )),
                        ],
                        onChanged: (val) {
                          setState(() {
                            _selectedParentId = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    TextFormField(
                      controller: _spendingLimitController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Spending Limit (Optional)',
                        prefixIcon: Icon(Icons.speed),
                        hintText: 'e.g. 500',
                      ),
                      validator: (val) {
                        if (val != null && val.trim().isNotEmpty) {
                          if (double.tryParse(val) == null || double.parse(val) < 0) {
                            return 'Please enter a valid positive number';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                );
              }(),
              const SizedBox(height: 24),

              // Action Buttons
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.category == null ? 'Create Category' : 'Save Changes'),
              ),
              
              if (widget.category != null) ...[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE53935),
                    side: const BorderSide(color: Color(0xFFE53935)),
                    minimumSize: const Size(double.infinity, 48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete Category', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String type, String label, Color color) {
    final active = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: active
                ? color
                : (isDark ? const Color(0xFF1E1E2E) : Colors.black.withValues(alpha: 0.02)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: active
                  ? color
                  : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04)),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: active ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
