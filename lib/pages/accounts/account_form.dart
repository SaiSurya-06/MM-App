import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/account.dart';
import '../../../providers/accounts_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/common/toast_notification.dart';
import 'account_card.dart';

class AccountForm extends ConsumerStatefulWidget {
  final Account? account;

  const AccountForm({Key? key, this.account}) : super(key: key);

  @override
  ConsumerState<AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends ConsumerState<AccountForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _limitController;
  late String _selectedType;
  late String _selectedIcon;
  late String _selectedColor;

  final List<String> _types = ['Bank', 'Cash', 'Credit Card', 'Savings', 'Investment'];
  
  final List<Map<String, String>> _icons = [
    {'name': 'Bank', 'key': 'account_balance'},
    {'name': 'Cash', 'key': 'payments'},
    {'name': 'Card', 'key': 'credit_card'},
    {'name': 'Savings', 'key': 'savings'},
    {'name': 'Investment', 'key': 'trending_up'},
  ];

  final List<Map<String, String>> _colors = [
    {'name': 'Emerald', 'hex': '#00A86B'},
    {'name': 'Red', 'hex': '#E53935'},
    {'name': 'Sapphire', 'hex': '#1E88E5'},
    {'name': 'Purple', 'hex': '#8E24AA'},
    {'name': 'Orange', 'hex': '#FB8C00'},
    {'name': 'Gold', 'hex': '#D4AF37'},
    {'name': 'Rose Gold', 'hex': '#B76E79'},
    {'name': 'Charcoal', 'hex': '#36454F'},
    {'name': 'Midnight Blue', 'hex': '#191970'},
    {'name': 'Orchid', 'hex': '#DA70D6'},
  ];

  @override
  void initState() {
    super.initState();
    final acc = widget.account;
    _nameController = TextEditingController(text: acc?.name ?? '');
    _balanceController = TextEditingController(text: acc?.balance.toString() ?? '0.0');
    _limitController = TextEditingController(text: acc?.limitAmount?.toString() ?? '');
    _selectedType = acc?.type ?? 'Bank';
    _selectedIcon = acc?.icon ?? 'account_balance';
    _selectedColor = acc?.color ?? '#1E88E5';

    _nameController.addListener(() => setState(() {}));
    _balanceController.addListener(() => setState(() {}));
    _limitController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final limit = _selectedType == 'Credit Card' ? (double.tryParse(_limitController.text) ?? 0.0) : null;
    
    bool success;
    if (widget.account == null) {
      // Create new account
      success = await ref.read(accountsProvider.notifier).addAccount(
            name,
            _selectedType,
            balance,
            _selectedIcon,
            _selectedColor,
            true,
            limit,
          );
    } else {
      // Update existing account
      final updated = widget.account!.copyWith(
        name: name,
        type: _selectedType,
        balance: balance,
        icon: _selectedIcon,
        color: _selectedColor,
        isShared: true,
        limitAmount: limit,
      );
      success = await ref.read(accountsProvider.notifier).updateAccount(updated);
    }

    if (success && mounted) {
      ToastNotification.show(
        context,
        widget.account == null ? 'Account created successfully!' : 'Account updated successfully!',
      );
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to delete this account? All associated transactions will be permanently deleted.'),
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

    if (confirmed == true && mounted) {
      final success = await ref.read(accountsProvider.notifier).deleteAccount(widget.account!.id!);
      if (success && mounted) {
        ToastNotification.show(context, 'Account deleted.');
        Navigator.pop(context); // Close AccountForm
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
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              Text(
                widget.account == null ? 'Create Account' : 'Edit Account',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Inter',
                ),
              ),
              
              const SizedBox(height: 16),

              Center(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.45,
                  height: 172.0,
                  child: AccountCard(
                    account: Account(
                      id: widget.account?.id,
                      name: _nameController.text.trim().isEmpty ? 'Preview Account' : _nameController.text.trim(),
                      type: _selectedType,
                      balance: double.tryParse(_balanceController.text.trim()) ?? 0.0,
                      icon: _selectedIcon,
                      color: _selectedColor,
                      isShared: true,
                      createdAt: widget.account?.createdAt ?? DateTime.now(),
                      limitAmount: _selectedType == 'Credit Card' ? (double.tryParse(_limitController.text.trim()) ?? 0.0) : null,
                    ),
                    currency: ref.watch(authProvider).profile?.preferredCurrency ?? 'USD',
                    onTap: () {},
                    onLongPress: () {},
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Name Field
              TextFormField(
                controller: _nameController,
                keyboardType: TextInputType.text,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Account Name',
                  prefixIcon: Icon(Icons.badge_outlined),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Please enter an account name';
                  return null;
                },
              ),
              
              const SizedBox(height: 16),

              // Balance Field
              TextFormField(
                controller: _balanceController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Balance',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'Please enter a balance';
                  if (double.tryParse(val) == null) return 'Please enter a valid number';
                  return null;
                },
              ),

              if (_selectedType == 'Credit Card') ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _limitController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Credit Limit',
                    prefixIcon: Icon(Icons.credit_score_outlined),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) return 'Please enter a credit limit';
                    if (double.tryParse(val) == null || double.parse(val) <= 0) return 'Please enter a valid limit';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 16),

              // Account Type dropdown
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Account Type',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                items: _types.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _selectedType = val;
                      
                      // Auto-select icon match type
                      if (val == 'Bank') _selectedIcon = 'account_balance';
                      if (val == 'Cash') _selectedIcon = 'payments';
                      if (val == 'Credit Card') _selectedIcon = 'credit_card';
                      if (val == 'Savings') _selectedIcon = 'savings';
                      if (val == 'Investment') _selectedIcon = 'trending_up';
                    });
                  }
                },
              ),

              const SizedBox(height: 20),

              // Color Selection Row
              const Text(
                'Color Tag',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _colors.length,
                  itemBuilder: (context, index) {
                    final item = _colors[index];
                    final hexStr = '0xFF${item["hex"]!.replaceAll("#", "")}';
                    final color = Color(int.parse(hexStr));
                    final isSelected = _selectedColor == item['hex'];

                    return GestureDetector(
                      onTap: () => setState(() => _selectedColor = item['hex']!),
                      child: Container(
                        width: 38,
                        height: 38,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: isDark ? Colors.white : Colors.black, width: 3)
                              : null,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Icon Selection Row
              const Text(
                'Card Icon',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _icons.length,
                  itemBuilder: (context, index) {
                    final item = _icons[index];
                    final key = item['key']!;
                    final isSelected = _selectedIcon == key;

                    IconData iconData;
                    if (key == 'account_balance') {
                      iconData = Icons.account_balance;
                    } else if (key == 'payments') {
                      iconData = Icons.payments;
                    } else if (key == 'credit_card') {
                      iconData = Icons.credit_card;
                    } else if (key == 'savings') {
                      iconData = Icons.savings;
                    } else {
                      iconData = Icons.trending_up;
                    }

                    return GestureDetector(
                      onTap: () => setState(() => _selectedIcon = key),
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? const Color(0xFFE53935).withOpacity(0.15) 
                              : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03)),
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(color: const Color(0xFFE53935), width: 2)
                              : null,
                        ),
                        child: Icon(
                          iconData,
                          color: isSelected ? const Color(0xFFE53935) : Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // Save Action Button
              ElevatedButton(
                onPressed: _save,
                child: Text(widget.account == null ? 'Create Account' : 'Save Changes'),
              ),
              if (widget.account != null) ...[
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
                  label: const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

