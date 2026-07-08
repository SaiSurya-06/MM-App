import 'package:flutter/material.dart';
import '../../../models/transaction.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_helpers.dart';
import '../../../core/utils/category_icon_helper.dart';

class TransactionListItem extends StatelessWidget {
  final Transaction transaction;
  final String categoryName;
  final String categoryColorHex;
  final String categoryIconKey;
  final String accountName;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final DismissDirectionCallback? onDismissed;
  final ConfirmDismissCallback? confirmDismiss;

  const TransactionListItem({
    super.key,
    required this.transaction,
    required this.categoryName,
    required this.categoryColorHex,
    required this.categoryIconKey,
    required this.accountName,
    required this.currency,
    required this.onTap,
    required this.onLongPress,
    this.onDismissed,
    this.confirmDismiss,
  });

  IconData _getIconData(String iconName) {
    if (iconName == 'transfer') return Icons.swap_horiz;
    return CategoryIconHelper.getIcon(iconName);
  }

  @override
  Widget build(BuildContext context) {
    final hex = '0xFF${categoryColorHex.replaceAll("#", "")}';
    final color = Color(int.tryParse(hex) ?? 0xFF757575);
    final isIncome = transaction.type == 'income';
    final isTransfer = transaction.type == 'transfer';
    final isVirtual = transaction.id != null && transaction.id! < 0;

    final tagList = transaction.tags
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    Widget itemContent = GlassmorphismCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Category Icon Circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isTransfer ? Icons.swap_horiz : _getIconData(categoryIconKey),
              color: color,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Text Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        transaction.title,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ),

                    if (isVirtual) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FUTURE',
                          style: TextStyle(color: Colors.amber, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      accountName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Inter',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 4, height: 4, decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.grey)),
                    const SizedBox(width: 8),
                    Text(
                      DateHelpers.formatDate(transaction.date),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontFamily: 'Inter',
                      ),
                    ),
                  ],
                ),
                if (tagList.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: tagList.map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
                      ),
                      child: Text(
                        tag.startsWith('#') ? tag : '#$tag',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontFamily: 'Inter',
                        ),
                      ),
                    )).toList(),
                  ),
                ],
              ],
            ),
          ),
          
          // Amount Label
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount, currency)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isIncome
                      ? Colors.green
                      : (isTransfer ? Colors.blue : const Color(0xFFE53935)),
                  fontFamily: 'Inter',
                ),
              ),
              if (transaction.recurrence != 'none')
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Row(
                    children: [
                      const Icon(Icons.autorenew, size: 10, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        transaction.recurrence,
                        style: const TextStyle(fontSize: 9, color: Colors.grey, fontFamily: 'Inter'),
                      ),
                    ],
                  ),
                )
            ],
          ),
        ],
      ),
    );

    Widget clickableContent = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: itemContent,
    );

    if (onDismissed != null && !isVirtual) {
      return Dismissible(
        key: ValueKey(transaction.id ?? transaction.createdAt.millisecondsSinceEpoch),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          decoration: BoxDecoration(
            color: const Color(0xFFE53935),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(
            Icons.delete_outline,
            color: Colors.white,
          ),
        ),
        confirmDismiss: confirmDismiss,
        onDismissed: onDismissed,
        child: clickableContent,
      );
    }

    return clickableContent;
  }
}


