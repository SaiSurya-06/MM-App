import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/toast_notification.dart';
import '../../widgets/common/premium_background.dart';

class PinSetupPage extends ConsumerStatefulWidget {
  const PinSetupPage({Key? key}) : super(key: key);

  @override
  ConsumerState<PinSetupPage> createState() => _PinSetupPageState();
}

class _PinSetupPageState extends ConsumerState<PinSetupPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  String _selectedCurrency = 'USD';

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'INR', 'JPY', 'AUD', 'CAD'];

  @override
  void dispose() {
    _nameController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pinController.text != _confirmPinController.text) {
      ToastNotification.show(context, 'PINs do not match!', isError: true);
      return;
    }

    final success = await ref.read(authProvider.notifier).setupPin(
          _nameController.text.trim(),
          _selectedCurrency,
          _pinController.text,
        );

    if (success && mounted) {
      ToastNotification.show(context, 'Profile set up successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: PremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (authState.profiles.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: isDark ? Colors.white70 : Colors.black87),
                        onPressed: () => ref.read(authProvider.notifier).showSelector(),
                      ),
                    ),
                  if (authState.profiles.isEmpty) ...[
                    LinearProgressIndicator(
                      value: 0.5,
                      backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Step 1 of 2: Profile Settings',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey : const Color(0xFF6C6C7D),
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const SizedBox(height: 20),
                  Text(
                    'Welcome to\nMoney Manager',
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: isDark ? Colors.white : const Color(0xFF1A1A26),
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Set up your secure offline profile to begin tracking your finances on-device.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 48),

                  // Name Input
                  Text(
                    'Display Name',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    autofocus: true,
                    keyboardType: TextInputType.name,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Currency Dropdown
                  Text(
                    'Preferred Currency',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCurrency,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.monetization_on_outlined),
                    ),
                    dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                    items: _currencies.map((currency) {
                      return DropdownMenuItem<String>(
                        value: currency,
                        child: Text(currency, style: const TextStyle(fontWeight: FontWeight.w500)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedCurrency = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // PIN Input
                  Text(
                    'Secure 4-Digit PIN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _pinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: 'Enter a 4-digit code',
                      prefixIcon: Icon(Icons.lock_outline),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.length != 4 || int.tryParse(value) == null) {
                        return 'Please enter a valid 4-digit PIN';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Confirm PIN Input
                  Text(
                    'Confirm PIN',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPinController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 4,
                    decoration: const InputDecoration(
                      hintText: 'Re-enter your 4-digit code',
                      prefixIcon: Icon(Icons.lock_reset),
                      counterText: '',
                    ),
                    validator: (value) {
                      if (value == null || value.length != 4 || int.tryParse(value) == null) {
                        return 'Please confirm your 4-digit PIN';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 48),

                  // Submit Button
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Create Profile'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

