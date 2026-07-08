import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../widgets/common/animated_counter.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../widgets/common/skeleton_loader.dart';
import '../../../providers/auth_provider.dart';


class SummaryCards extends ConsumerStatefulWidget {
  final double totalBalance;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double netSavings;
  final double healthScore;
  final String currency;
  final bool isLoading;

  const SummaryCards({
    Key? key,
    required this.totalBalance,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.netSavings,
    required this.healthScore,
    required this.currency,
    required this.isLoading,
  }) : super(key: key);

  @override
  ConsumerState<SummaryCards> createState() => _SummaryCardsState();
}

class _SummaryCardsState extends ConsumerState<SummaryCards> {
  static bool _sessionUnlocked = false;
  bool _isNetWorthVisible = false;

  Future<void> _toggleNetWorthVisibility() async {
    if (_isNetWorthVisible) {
      setState(() {
        _isNetWorthVisible = false;
      });
      return;
    }

    if (_sessionUnlocked) {
      setState(() {
        _isNetWorthVisible = true;
      });
      return;
    }

    final authState = ref.read(authProvider);
    final authNotifier = ref.read(authProvider.notifier);

    bool authenticated = false;

    // 1. Try Biometrics if enabled and available
    if (authState.profile?.biometricEnabled == true && authState.isBiometricAvailable) {
      authenticated = await authNotifier.authenticateBiometrically();
    }

    // 2. Fallback to PIN dialog if not authenticated
    if (!authenticated) {
      final pinVerified = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PinVerificationDialog(
          onVerify: (pin) async {
            return await authNotifier.verifyPin(pin);
          },
        ),
      );
      authenticated = pinVerified ?? false;
    }

    if (authenticated) {
      _sessionUnlocked = true;
      setState(() {
        _isNetWorthVisible = true;
      });
    }
  }

  Widget _buildHealthScoreGauge(double score) {
    final color = _getHealthScoreColor(score);
    return Container(
      width: 48,
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: score / 100.0,
            strokeWidth: 4.5,
            backgroundColor: color.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
          Text(
            score.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              fontFamily: 'Inter',
            ),
          ),
        ],
      ),
    );
  }

  String _getHealthScoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'Good';
    if (score >= 50) return 'Fair';
    return 'Critical';
  }

  Color _getHealthScoreColor(double score) {
    if (score >= 85) return Colors.greenAccent;
    if (score >= 70) return Colors.tealAccent;
    if (score >= 50) return Colors.orangeAccent;
    return const Color(0xFFE53935);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Column(
        children: [
          Row(
            children: const [
              Expanded(flex: 3, child: SkeletonLoader(height: 140, borderRadius: 24)),
              SizedBox(width: 12),
              Expanded(flex: 2, child: SkeletonLoader(height: 140, borderRadius: 24)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 16)),
              SizedBox(width: 12),
              Expanded(child: SkeletonLoader(height: 90, borderRadius: 16)),
            ],
          )
        ],
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        // Row 1: Net Worth Card & Health Score Card
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Net Worth Card (2x1 column equivalent)
            Expanded(
              flex: 3,
              child: Container(
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFFA855F7)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'NET WORTH',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isNetWorthVisible ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                            size: 18,
                          ),
                          onPressed: _toggleNetWorthVisibility,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: _isNetWorthVisible
                          ? FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: AnimatedCounter(
                                value: widget.totalBalance,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                ),
                                formatter: (val) => CurrencyFormatter.format(val, widget.currency),
                              ),
                            )
                          : const FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '••••••',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'Inter',
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          widget.netSavings >= 0 ? Icons.trending_up : Icons.trending_down,
                          color: widget.netSavings >= 0 ? Colors.greenAccent : Colors.orangeAccent,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            widget.netSavings >= 0 ? 'Surplus this month' : 'Deficit this month',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 9,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Financial Health Score Bento Card (1x1 column equivalent)
            Expanded(
              flex: 2,
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Container(
                  height: 112, // match height with main container minus padding/margins
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'HEALTH SCORE',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                          fontFamily: 'Inter',
                        ),
                      ),
                      
                      // Circular Score indicator
                      _buildHealthScoreGauge(widget.healthScore),
                      
                      Text(
                        _getHealthScoreLabel(widget.healthScore),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _getHealthScoreColor(widget.healthScore),
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        // Row 2: Income, Expenses, & Savings Grid Row
        Row(
          children: [
            // Income
            Expanded(
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                color: isDark 
                    ? Colors.green.withOpacity(0.06) 
                    : Colors.green.withOpacity(0.04),
                borderColor: Colors.green.withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.arrow_downward, color: Colors.green, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'INCOME',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCounter(
                          value: widget.monthlyIncome,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A26),
                            fontFamily: 'Inter',
                          ),
                          formatter: (val) => CurrencyFormatter.format(val, widget.currency),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 10),

            // Expenses
            Expanded(
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                color: isDark 
                    ? const Color(0xFFE53935).withOpacity(0.06) 
                    : const Color(0xFFE53935).withOpacity(0.04),
                borderColor: const Color(0xFFE53935).withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.arrow_upward, color: Color(0xFFE53935), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'EXPENSES',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCounter(
                          value: widget.monthlyExpenses,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF1A1A26),
                            fontFamily: 'Inter',
                          ),
                          formatter: (val) => CurrencyFormatter.format(val, widget.currency),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(width: 10),

            // Savings
            Expanded(
              child: GlassmorphismCard(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                color: isDark 
                    ? const Color(0xFFA855F7).withOpacity(0.06) 
                    : const Color(0xFFA855F7).withOpacity(0.04),
                borderColor: const Color(0xFFA855F7).withOpacity(0.15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.savings_outlined, color: Color(0xFFA855F7), size: 12),
                        SizedBox(width: 4),
                        Text(
                          'NET FLOW',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    SizedBox(
                      width: double.infinity,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: AnimatedCounter(
                          value: widget.netSavings,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: widget.netSavings >= 0 
                                ? Colors.green 
                                : const Color(0xFFE53935),
                            fontFamily: 'Inter',
                          ),
                          formatter: (val) => CurrencyFormatter.format(val, widget.currency),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class PinVerificationDialog extends StatefulWidget {
  final Future<bool> Function(String) onVerify;
  const PinVerificationDialog({Key? key, required this.onVerify}) : super(key: key);

  @override
  State<PinVerificationDialog> createState() => _PinVerificationDialogState();
}

class _PinVerificationDialogState extends State<PinVerificationDialog> {
  String _pin = '';
  final int _pinLength = 4;
  bool _isError = false;

  void _onKeypadTap(String key) {
    if (_pin.length >= _pinLength) return;
    setState(() {
      _pin += key;
      _isError = false;
    });

    if (_pin.length == _pinLength) {
      _verify();
    }
  }

  void _onBackspace() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin = _pin.substring(0, _pin.length - 1);
      _isError = false;
    });
  }

  Future<void> _verify() async {
    final success = await widget.onVerify(_pin);
    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _pin = '';
        _isError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Enter PIN',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1A1A26),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isError ? 'Incorrect PIN. Try again.' : 'Enter your PIN to show Net Worth',
              style: TextStyle(
                fontSize: 13,
                color: _isError ? const Color(0xFFE53935) : (isDark ? Colors.grey : const Color(0xFF6C6C7D)),
                fontFamily: 'Inter',
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pinLength, (index) {
                final active = index < _pin.length;
                return Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: active
                        ? const Color(0xFFE53935)
                        : (isDark ? Colors.white12 : Colors.black12),
                    border: Border.all(
                      color: active 
                          ? const Color(0xFFE53935) 
                          : (isDark ? Colors.white30 : Colors.black38),
                      width: 1.5,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            // Numeric Keypad
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKey('1'),
                    _buildKey('2'),
                    _buildKey('3'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKey('4'),
                    _buildKey('5'),
                    _buildKey('6'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildKey('7'),
                    _buildKey('8'),
                    _buildKey('9'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: () => Navigator.of(context).pop(false),
                    ),
                    _buildKey('0'),
                    IconButton(
                      icon: Icon(Icons.backspace_outlined, color: isDark ? Colors.white70 : Colors.black54),
                      onPressed: _onBackspace,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKey(String digit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isDark ? const Color(0xFF161625) : Colors.black.withOpacity(0.02),
      ),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _onKeypadTap(digit),
        child: Center(
          child: Text(
            digit,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF1A1A26),
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}

