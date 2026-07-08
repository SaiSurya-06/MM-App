import 'package:flutter/material.dart';
import '../../../models/account.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../widgets/common/tilt_card.dart';
import '../../../core/utils/currency_formatter.dart';

class AccountCard extends StatelessWidget {
  final Account account;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const AccountCard({
    Key? key,
    required this.account,
    required this.currency,
    required this.onTap,
    this.onLongPress,
  }) : super(key: key);

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'account_balance':
        return Icons.account_balance;
      case 'payments':
        return Icons.payments;
      case 'credit_card':
        return Icons.credit_card;
      case 'savings':
        return Icons.savings;
      case 'trending_up':
        return Icons.trending_up;
      default:
        return Icons.wallet;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hex = '0xFF${account.color.replaceAll("#", "")}';
    final cardColor = Color(int.tryParse(hex) ?? 0xFFE53935);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isCreditCard = account.type == 'Credit Card';
    final remainingLimit = isCreditCard && account.limitAmount != null
        ? (account.limitAmount! - account.balance.abs())
        : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: TiltCard(
        maxTilt: 10.0,
        enabled: false,
        child: GlassmorphismCard(
          padding: EdgeInsets.zero,
          color: isDark 
              ? cardColor.withOpacity(0.12) 
              : cardColor.withOpacity(0.08),
          borderColor: cardColor.withOpacity(0.2),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              onLongPress: onLongPress,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                // Header Row (Icon and type)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _getIconData(account.icon),
                        color: cardColor,
                        size: 20,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          account.type.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 1.0,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                
                // Card details
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isCreditCard && account.limitAmount != null && account.limitAmount! > 0) ...[
                      // 1. Remaining Amount
                      const Text(
                        'Remaining Limit',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(remainingLimit, currency),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: remainingLimit >= 0 
                                  ? (isDark ? Colors.white : const Color(0xFF1A1A26))
                                  : const Color(0xFFE53935),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      
                      // 2. Pending Payment
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Pending Payment: ${CurrencyFormatter.format(account.pendingPayment < 0 ? 0.0 : account.pendingPayment, currency)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: (account.pendingPayment > 0)
                                  ? const Color(0xFFE53935).withOpacity(0.9)
                                  : Colors.grey,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // 3. Progress Bar
                      Builder(
                        builder: (context) {
                          final ratio = (account.balance.abs() / account.limitAmount!).clamp(0.0, 1.0);
                          final activeColor = ratio > 0.8 
                              ? const Color(0xFFE53935) 
                              : (ratio > 0.5 ? Colors.orangeAccent : Colors.greenAccent);
                          return AnimatedCreditProgressBar(
                            ratio: ratio,
                            activeColor: activeColor,
                          );
                        }
                      ),
                      const SizedBox(height: 6),

                      // 4. Utilized percentage
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Utilized: ${((account.balance.abs() / account.limitAmount!) * 100).toStringAsFixed(0)}% of ${CurrencyFormatter.format(account.limitAmount!, currency)}',
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark ? Colors.white70 : Colors.black54,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // Regular account balance
                      SizedBox(
                        width: double.infinity,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            CurrencyFormatter.format(account.balance, currency),
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: account.balance >= 0 
                                  ? (isDark ? Colors.white : const Color(0xFF1A1A26))
                                  : const Color(0xFFE53935),
                              fontFamily: 'Inter',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedCreditProgressBar extends StatefulWidget {
  final double ratio;
  final Color activeColor;

  const AnimatedCreditProgressBar({
    Key? key,
    required this.ratio,
    required this.activeColor,
  }) : super(key: key);

  @override
  State<AnimatedCreditProgressBar> createState() => _AnimatedCreditProgressBarState();
}

class _AnimatedCreditProgressBarState extends State<AnimatedCreditProgressBar> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  late AnimationController _shineController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOutBack, // Playful elastic bounce curve
    );

    _shineController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(); // Infinite repeating shimmer sweep

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1400),
      vsync: this,
    )..repeat(reverse: true); // Pulsing soft glow effect

    _progressController.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedCreditProgressBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ratio != widget.ratio) {
      _progressController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _shineController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: Listenable.merge([_progressAnimation, _pulseController]),
      builder: (context, child) {
        final progressValue = (_progressAnimation.value * widget.ratio).clamp(0.0, 1.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Stack(
            children: [
              // Track Background
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                    width: 1,
                  ),
                ),
              ),
              // Glow Layer & Progress Fill
              if (progressValue > 0)
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progressValue,
                  child: Stack(
                    children: [
                      // Pulsing Glow Shadow Layer
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: widget.activeColor.withOpacity(0.35 + 0.15 * _pulseController.value),
                              blurRadius: 5.0 + 4.0 * _pulseController.value,
                              spreadRadius: 0.5 * _pulseController.value,
                            ),
                          ],
                        ),
                      ),
                      // Main Gradient Filled Bar
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: LinearGradient(
                            colors: [
                              widget.activeColor.withOpacity(0.85),
                              widget.activeColor,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                      ),
                      // Sliding Shimmer Shine Effect
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _shineController,
                          builder: (context, child) {
                            return ShaderMask(
                              shaderCallback: (bounds) {
                                return LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  stops: [
                                    (_shineController.value - 0.25).clamp(0.0, 1.0),
                                    _shineController.value.clamp(0.0, 1.0),
                                    (_shineController.value + 0.25).clamp(0.0, 1.0),
                                  ],
                                  colors: [
                                    Colors.white.withOpacity(0.0),
                                    Colors.white.withOpacity(0.35),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ).createShader(bounds);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
