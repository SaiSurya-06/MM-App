import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';

class BudgetProgressCard extends StatefulWidget {
  final String categoryName;
  final String categoryIcon;
  final String categoryColorHex;
  final double spent;
  final double limit;
  final String currency;
  final VoidCallback onTap;
  final double? monthlyAverage;
  final double? threeMonthRollingAverage;
  final double? projectedMonthEnd;
  final String recurrence;
  final String? groupName;
  final double rollover;

  const BudgetProgressCard({
    Key? key,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColorHex,
    required this.spent,
    required this.limit,
    required this.currency,
    required this.onTap,
    this.monthlyAverage,
    this.threeMonthRollingAverage,
    this.projectedMonthEnd,
    this.recurrence = 'monthly',
    this.groupName,
    this.rollover = 0.0,
  }) : super(key: key);

  @override
  State<BudgetProgressCard> createState() => _BudgetProgressCardState();
}

class _BudgetProgressCardState extends State<BudgetProgressCard> {
  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'fastfood':
        return Icons.fastfood;
      case 'home':
        return Icons.home;
      case 'payments':
        return Icons.payments;
      case 'directions_bus':
        return Icons.directions_bus;
      case 'movie':
        return Icons.movie;
      case 'local_hospital':
        return Icons.local_hospital;
      case 'power':
        return Icons.power;
      case 'category':
        return Icons.category;
      default:
        return Icons.monetization_on;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hex = '0xFF${widget.categoryColorHex.replaceAll("#", "")}';
    final catColor = Color(int.tryParse(hex) ?? 0xFF757575);
    
    final totalLimit = (widget.limit + widget.rollover).clamp(0.0, double.infinity);
    final percent = totalLimit > 0 ? (widget.spent / totalLimit) : 0.0;
    final percentClamped = percent.clamp(0.0, 1.0);
    
    // Choose progress bar and text color based on usage percent
    Color progressBarColor = Colors.green;
    String statusText = '';
    Color statusColor = Colors.green;

    if (percent >= 1.0) {
      progressBarColor = const Color(0xFFE53935);
      statusText = '🚨 Over Budget!';
      statusColor = const Color(0xFFE53935);
    } else if (percent >= 0.8) {
      progressBarColor = const Color(0xFFFB8C00); // Orange
      statusText = '⚠️ 80% Spent';
      statusColor = const Color(0xFFFB8C00);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    final rolloverText = widget.rollover > 0 
        ? ' (+${CurrencyFormatter.format(widget.rollover, widget.currency)} carry-over)' 
        : (widget.rollover < 0 
            ? ' (-${CurrencyFormatter.format(-widget.rollover, widget.currency)} carry-over)' 
            : '');
    final recurrenceLabel = widget.recurrence != 'monthly' ? ' (${widget.recurrence})' : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: GlassmorphismCard(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row (Icon, Name, and Warning tags)
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: catColor.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getIconData(widget.categoryIcon),
                      color: catColor,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              widget.categoryName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                fontFamily: 'Inter',
                              ),
                            ),
                            if (widget.groupName != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  widget.groupName!,
                                  style: const TextStyle(
                                    color: Colors.blue,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          'Limit: ${CurrencyFormatter.format(totalLimit, widget.currency)}$recurrenceLabel$rolloverText',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 11,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (statusText.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),
                ],
              ),
              
              const SizedBox(height: 18),
              
              // Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentClamped,
                  minHeight: 8,
                  backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                  valueColor: AlwaysStoppedAnimation<Color>(progressBarColor),
                ),
              ),
              
              const SizedBox(height: 8),

              // Spend text detail
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Spent: ${CurrencyFormatter.format(widget.spent, widget.currency)}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontFamily: 'Inter',
                    ),
                  ),
                  Text(
                    '${(percent * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                      fontFamily: 'Inter',
                    ),
                  ),
                ],
              ),

              // Projections and Trends
              if (widget.threeMonthRollingAverage != null || widget.projectedMonthEnd != null) ...[
                const Divider(height: 16, thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (widget.threeMonthRollingAverage != null)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '3-Mo Avg: ${CurrencyFormatter.format(widget.threeMonthRollingAverage!, widget.currency)}',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                              fontFamily: 'Inter',
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: const Text('3-Month Rolling Average'),
                                  content: const Text(
                                    'This is the average monthly spend over the last 3 months. It helps you understand spending trends and set realistic budgets.',
                                    style: TextStyle(fontFamily: 'Inter'),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text('OK'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(10),
                            child: Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Icon(
                                Icons.info_outline,
                                size: 12,
                                color: Colors.grey.withOpacity(0.8),
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (widget.projectedMonthEnd != null)
                      Row(
                        children: [
                          Text(
                            'Proj. Total: ${CurrencyFormatter.format(widget.projectedMonthEnd!, widget.currency)}',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: widget.projectedMonthEnd! > widget.limit ? FontWeight.bold : FontWeight.normal,
                              color: widget.projectedMonthEnd! > widget.limit ? const Color(0xFFE53935) : Colors.grey,
                              fontFamily: 'Inter',
                            ),
                          ),
                          if (widget.projectedMonthEnd! > widget.limit) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.trending_up, color: Color(0xFFE53935), size: 12),
                          ],
                        ],
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
