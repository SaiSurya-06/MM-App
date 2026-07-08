import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/toast_notification.dart';
import '../../widgets/common/premium_background.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  String _pin = '';
  final int _pinLength = 4;
  Timer? _lockoutTimer;
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    // Auto-trigger biometric login after frame is rendered if enabled
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometrics();
    });
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  Future<void> _triggerBiometrics() async {
    final authState = ref.read(authProvider);
    if (authState.profile != null && authState.profile!.biometricEnabled) {
      final success = await ref.read(authProvider.notifier).authenticateBiometrically();
      if (success && mounted) {
        ToastNotification.show(context, 'Authenticated successfully!');
      }
    }
  }

  void _onKeypadTap(String key) {
    if (_pin.length >= _pinLength) return;

    setState(() {
      _pin += key;
    });

    if (_pin.length == _pinLength) {
      _verifyPin();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
    });
  }

  Future<void> _verifyPin() async {
    final success = await ref.read(authProvider.notifier).verifyPin(_pin);
    if (success && mounted) {
      ToastNotification.show(context, 'Welcome back!');
    } else {
      setState(() {
        _pin = '';
      });
      if (mounted) {
        final error = ref.read(authProvider).errorMessage ?? 'Incorrect PIN. Try again.';
        ToastNotification.show(context, error, isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final profile = authState.profile;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isLockedOut = authState.lockedUntil != null &&
        DateTime.now().isBefore(authState.lockedUntil!);

    if (profile == null && authState.profiles.isNotEmpty) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF09090E) : Colors.white,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Who is using Money Manager?',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A26),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 40),
                  Wrap(
                    spacing: 24,
                    runSpacing: 24,
                    alignment: WrapAlignment.center,
                    children: [
                      ...authState.profiles.map((p) {
                        return InkWell(
                          onTap: () => ref.read(authProvider.notifier).selectProfile(p),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            width: 100,
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFF5F5F7),
                                  child: Text(
                                    p.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFFE53935) : Colors.red,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  p.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? Colors.white70 : Colors.black87,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                      // Create Profile Button
                      InkWell(
                        onTap: () => ref.read(authProvider.notifier).startCreateProfile(),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 100,
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            children: [
                              CircleAvatar(
                                radius: 36,
                                backgroundColor: isDark ? const Color(0xFF161625) : const Color(0xFFEBEBEF),
                                child: Icon(
                                  Icons.add,
                                  size: 32,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Add Profile',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isLockedOut) {
      if (_lockoutTimer == null) {
        _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) {
            setState(() {});
          }
          if (authState.lockedUntil == null || DateTime.now().isAfter(authState.lockedUntil!)) {
            _lockoutTimer?.cancel();
            _lockoutTimer = null;
          }
        });
      }

      final remaining = authState.lockedUntil!.difference(DateTime.now());
      final min = remaining.inMinutes.toString().padLeft(2, '0');
      final sec = (remaining.inSeconds % 60).toString().padLeft(2, '0');

      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF09090E) : Colors.white,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.security_outlined,
                  size: 80,
                  color: Color(0xFFE53935),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Security Lockout',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Too many failed login attempts. Money Manager has been locked for your security.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE53935).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE53935).withOpacity(0.3)),
                  ),
                  child: Text(
                    'Try again in: $min:$sec',
                    style: const TextStyle(
                      color: Color(0xFFE53935),
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      if (_lockoutTimer != null) {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
      }
    }

    return Scaffold(
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: PremiumBackground(
          child: SafeArea(
            child: Column(
            children: [
              // Top navigation row for Back Button
              if (authState.profiles.isNotEmpty)
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0, top: 8.0),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white70 : Colors.black87),
                      onPressed: () => ref.read(authProvider.notifier).showSelector(),
                    ),
                  ),
                )
              else
                const SizedBox(height: 48), // Keep spacing consistent

              const Spacer(),
              
              // Welcome Header
              Column(
                children: [
                  Text(
                    'Welcome Back,',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.grey : const Color(0xFF6C6C7D),
                      fontFamily: 'Inter',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile?.name ?? 'User',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1A1A26),
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              
              // PIN Dots Indicator with Show/Hide Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 48), // Spacing to balance the eye icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pinLength, (index) {
                      final active = index < _pin.length;
                      return Container(
                        width: 24,
                        height: 24,
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: active
                              ? const Color(0xFFE53935).withOpacity(_obscurePin ? 1.0 : 0.15)
                              : (isDark ? Colors.white12 : Colors.black12),
                          border: Border.all(
                            color: active 
                                ? const Color(0xFFE53935) 
                                : (isDark ? Colors.white30 : Colors.black38),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            !_obscurePin && active ? _pin[index] : '',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF1A1A26),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                  IconButton(
                    icon: Icon(
                      _obscurePin ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                      color: isDark ? Colors.white54 : Colors.black45,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePin = !_obscurePin;
                      });
                    },
                  ),
                ],
              ),
              
              const Spacer(),
              
              // Numeric Custom Keypad
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildKeypadButton('1'),
                        _buildKeypadButton('2'),
                        _buildKeypadButton('3'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildKeypadButton('4'),
                        _buildKeypadButton('5'),
                        _buildKeypadButton('6'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildKeypadButton('7'),
                        _buildKeypadButton('8'),
                        _buildKeypadButton('9'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Biometrics Toggle Button
                        (profile != null && profile.biometricEnabled)
                            ? _buildIconButton(
                                Icons.fingerprint,
                                _triggerBiometrics,
                              )
                            : const SizedBox(width: 70, height: 70),
                        _buildKeypadButton('0'),
                        _buildIconButton(
                          Icons.backspace_outlined,
                          _onBackspace,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              TextButton(
                onPressed: () => ref.read(authProvider.notifier).showSelector(),
                child: const Text(
                  'Switch / Add Profile',
                  style: TextStyle(
                    color: Color(0xFFE53935),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildKeypadButton(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _onKeypadTap(digit),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A26),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData iconData, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF161625) : Colors.black.withOpacity(0.02),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Center(
          child: Icon(
            iconData,
            size: 26,
            color: iconData == Icons.fingerprint
                ? const Color(0xFFE53935)
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}


