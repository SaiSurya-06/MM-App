import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/transaction.dart';
import '../../../widgets/common/glassmorphism_card.dart';
import '../../transactions/transaction_form.dart';
import '../../../core/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/auth_provider.dart';

class CalendarWidget extends ConsumerStatefulWidget {
  final List<Transaction> transactions;

  const CalendarWidget({
    Key? key,
    required this.transactions,
  }) : super(key: key);

  @override
  ConsumerState<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends ConsumerState<CalendarWidget> {
  late DateTime _focusedMonth;
  late Set<String> _transactionDates;
  final Map<String, double> _dailyExpenses = {};
  final Map<String, double> _dailyIncome = {};
  final Map<String, List<Transaction>> _dailyTransactions = {};

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _extractTransactionDates();
  }

  @override
  void didUpdateWidget(covariant CalendarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      _extractTransactionDates();
    }
  }

  void _extractTransactionDates() {
    _transactionDates = widget.transactions.map((tx) {
      return tx.date.toIso8601String().substring(0, 10);
    }).toSet();

    _dailyExpenses.clear();
    _dailyIncome.clear();
    _dailyTransactions.clear();

    for (var tx in widget.transactions) {
      final key = tx.date.toIso8601String().substring(0, 10);
      _dailyTransactions.putIfAbsent(key, () => []).add(tx);
      if (tx.type == 'expense') {
        _dailyExpenses[key] = (_dailyExpenses[key] ?? 0.0) + tx.amount;
      } else if (tx.type == 'income') {
        _dailyIncome[key] = (_dailyIncome[key] ?? 0.0) + tx.amount;
      }
    }
  }

  int _getDaysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  int _getStartWeekday(DateTime date) {
    // weekday is 1 for Mon, 7 for Sun. We normalize to 0 for Mon, 6 for Sun.
    return DateTime(date.year, date.month, 1).weekday - 1;
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
    });
  }

  void _onDayTap(DateTime date) {
    // Filter transactions for this specific day
    final dayStr = date.toIso8601String().substring(0, 10);
    final dayTxs = widget.transactions.where((tx) {
      return tx.date.toIso8601String().substring(0, 10) == dayStr;
    }).toList();

    _showDayTransactionsBottomSheet(date, dayTxs);
  }

  void _showDayTransactionsBottomSheet(DateTime date, List<Transaction> txs) {
    final currency = ref.read(authProvider).profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Pre-calculate income & expense totals for this day
    final double dayIncome = txs
        .where((tx) => tx.type == 'income')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final double dayExpenses = txs
        .where((tx) => tx.type == 'expense')
        .fold(0.0, (sum, tx) => sum + tx.amount);
    final double dayNet = dayIncome - dayExpenses;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.80,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
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
                  const SizedBox(height: 20),

                  // ── Header Row ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        DateFormat('MMMM dd, yyyy').format(date),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Inter',
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _openTransactionForm(date);
                        },
                        icon: const Icon(Icons.add_circle,
                            color: Color(0xFFE53935), size: 30),
                      ),
                    ],
                  ),

                  // ── Day Summary Strip ────────────────────────────────────
                  if (txs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        // Income tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(
                                  isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.green.withOpacity(0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.arrow_downward,
                                        color: Colors.green, size: 13),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'INCOME',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                        letterSpacing: 0.8,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '+${CurrencyFormatter.format(dayIncome, currency)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Expense tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935)
                                  .withOpacity(isDark ? 0.15 : 0.08),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: const Color(0xFFE53935)
                                      .withOpacity(0.25)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward,
                                        color: Color(0xFFE53935), size: 13),
                                    const SizedBox(width: 4),
                                    const Text(
                                      'EXPENSE',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFE53935),
                                        letterSpacing: 0.8,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '-${CurrencyFormatter.format(dayExpenses, currency)}',
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFE53935),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Net tile
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: (dayNet >= 0 ? Colors.green : const Color(0xFFE53935))
                                  .withOpacity(isDark ? 0.12 : 0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: (dayNet >= 0
                                        ? Colors.green
                                        : const Color(0xFFE53935))
                                    .withOpacity(0.2),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      dayNet >= 0
                                          ? Icons.trending_up
                                          : Icons.trending_down,
                                      color: dayNet >= 0
                                          ? Colors.green
                                          : const Color(0xFFE53935),
                                      size: 13,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'NET',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: dayNet >= 0
                                            ? Colors.green
                                            : const Color(0xFFE53935),
                                        letterSpacing: 0.8,
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${dayNet >= 0 ? '+' : ''}${CurrencyFormatter.format(dayNet, currency)}',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: dayNet >= 0
                                        ? Colors.green
                                        : const Color(0xFFE53935),
                                    fontFamily: 'Inter',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Divider(
                        height: 1,
                        thickness: 0.5,
                        color: isDark
                            ? Colors.white12
                            : Colors.black12),
                    const SizedBox(height: 8),
                  ],

                  // ── Transaction List ─────────────────────────────────────
                  if (txs.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Text(
                          'No transactions logged for this day.',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                            fontFamily: 'Inter',
                          ),
                        ),
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: txs.length,
                        itemBuilder: (context, index) {
                          final tx = txs[index];
                          final isIncome = tx.type == 'income';

                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(vertical: 4.0),
                            child: InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _openTransactionForm(date, tx);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 8.0, horizontal: 8.0),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: (isIncome
                                                ? Colors.green
                                                : const Color(0xFFE53935))
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        isIncome
                                            ? Icons.arrow_downward
                                            : Icons.arrow_upward,
                                        color: isIncome
                                            ? Colors.green
                                            : const Color(0xFFE53935),
                                        size: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              fontFamily: 'Inter',
                                            ),
                                          ),
                                          if (tx.note != null &&
                                              tx.note!.isNotEmpty)
                                            Text(
                                              tx.note!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 11,
                                                fontFamily: 'Inter',
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isIncome ? '+' : '-'}${CurrencyFormatter.format(tx.amount, currency)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: isIncome
                                            ? Colors.green
                                            : const Color(0xFFE53935),
                                        fontFamily: 'Inter',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _openTransactionForm(DateTime date, [Transaction? tx]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransactionForm(
        initialDate: date,
        transaction: tx,
      ),
    );
  }



  Widget _buildLegendBox(Color bg, Color border) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(2),
        border: Border.all(color: border, width: 0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalDays = _getDaysInMonth(_focusedMonth);
    final startWeekday = _getStartWeekday(_focusedMonth);
    
    final list = <Widget>[];

    // Add empty spacer cells for weekdays preceding the 1st of the month
    for (int i = 0; i < startWeekday; i++) {
      list.add(const SizedBox());
    }

    // Add active date cells
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    for (int day = 1; day <= totalDays; day++) {
      final cellDate = DateTime(_focusedMonth.year, _focusedMonth.month, day);
      final cellDateStr = cellDate.toIso8601String().substring(0, 10);
      
      final hasTx = _transactionDates.contains(cellDateStr);
      final isToday = cellDateStr == todayStr;
      
      final txs = _dailyTransactions[cellDateStr] ?? [];
      final expenses = _dailyExpenses[cellDateStr] ?? 0.0;

      Color? cellBg;
      Color? cellBorder;
      Color textColor = isDark ? Colors.white70 : Colors.black87;
      FontWeight textWeight = FontWeight.normal;

      if (isToday) {
        cellBorder = const Color(0xFFE53935);
        textWeight = FontWeight.bold;
      }

      if (txs.isEmpty) {
        cellBg = isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02);
        textColor = isDark ? Colors.white30 : Colors.black38;
      } else if (expenses == 0) {
        cellBg = Colors.blue.withOpacity(isDark ? 0.2 : 0.1);
        cellBorder = cellBorder ?? Colors.blue.withOpacity(0.4);
        textColor = isDark ? Colors.blueAccent : Colors.blue[800]!;
      } else {
        // We have expenses
        if (expenses <= 15) {
          cellBg = Colors.green.withOpacity(isDark ? 0.2 : 0.12);
          cellBorder = cellBorder ?? Colors.green.withOpacity(0.3);
          textColor = isDark ? Colors.greenAccent : Colors.green[800]!;
        } else if (expenses <= 45) {
          cellBg = Colors.green.withOpacity(isDark ? 0.45 : 0.3);
          cellBorder = cellBorder ?? Colors.green.withOpacity(0.6);
          textColor = isDark ? Colors.white : Colors.green[900]!;
          textWeight = FontWeight.bold;
        } else if (expenses <= 100) {
          cellBg = const Color(0xFFE53935).withOpacity(isDark ? 0.2 : 0.12);
          cellBorder = cellBorder ?? const Color(0xFFE53935).withOpacity(0.3);
          textColor = isDark ? const Color(0xFFFF8A80) : const Color(0xFFC62828);
        } else if (expenses <= 250) {
          cellBg = const Color(0xFFE53935).withOpacity(isDark ? 0.45 : 0.3);
          cellBorder = cellBorder ?? const Color(0xFFE53935).withOpacity(0.6);
          textColor = isDark ? Colors.white : const Color(0xFFB71C1C);
          textWeight = FontWeight.bold;
        } else {
          cellBg = const Color(0xFFE53935).withOpacity(isDark ? 0.75 : 0.65);
          cellBorder = cellBorder ?? const Color(0xFFE53935);
          textColor = Colors.white;
          textWeight = FontWeight.bold;
        }
      }

      list.add(
        InkWell(
          onTap: () => _onDayTap(cellDate),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cellBg,
              borderRadius: BorderRadius.circular(10),
              border: cellBorder != null 
                  ? Border.all(color: cellBorder, width: isToday ? 1.5 : 1.0)
                  : null,
            ),
            child: Text(
              day.toString(),
              style: TextStyle(
                fontWeight: textWeight,
                fontSize: 13,
                color: textColor,
                fontFamily: 'Inter',
              ),
            ),
          ),
        ),
      );
    }

    final monthLabel = DateFormat('MMMM yyyy').format(_focusedMonth);

    return GestureDetector(
      onHorizontalDragEnd: (details) {
        if (details.primaryVelocity == null) return;
        if (details.primaryVelocity! < -300) {
          _nextMonth();
        } else if (details.primaryVelocity! > 300) {
          _previousMonth();
        }
      },
      behavior: HitTestBehavior.translucent,
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        child: Column(
        children: [
          // Header selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _previousMonth,
                icon: const Icon(Icons.chevron_left, size: 20),
              ),
              Text(
                monthLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  fontFamily: 'Inter',
                ),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right, size: 20),
              ),
            ],
          ),
          
          const SizedBox(height: 12),

          // Weekday Labels Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((label) {
              return SizedBox(
                width: 32,
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white30 : Colors.black38,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      fontFamily: 'Inter',
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          
          const Divider(height: 16, thickness: 0.5),

          // Grid Days
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.0,
            children: list,
          ),

          const SizedBox(height: 14),
          
          // Heatmap Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Less ',
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 9,
                  fontFamily: 'Inter',
                ),
              ),
              _buildLegendBox(isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.02), isDark ? Colors.white10 : Colors.black12),
              const SizedBox(width: 4),
              _buildLegendBox(Colors.green.withOpacity(isDark ? 0.2 : 0.12), Colors.green.withOpacity(0.3)),
              const SizedBox(width: 4),
              _buildLegendBox(Colors.green.withOpacity(isDark ? 0.45 : 0.3), Colors.green.withOpacity(0.6)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFFE53935).withOpacity(isDark ? 0.2 : 0.12), const Color(0xFFE53935).withOpacity(0.3)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFFE53935).withOpacity(isDark ? 0.45 : 0.3), const Color(0xFFE53935).withOpacity(0.6)),
              const SizedBox(width: 4),
              _buildLegendBox(const Color(0xFFE53935).withOpacity(isDark ? 0.75 : 0.65), const Color(0xFFE53935)),
              Text(
                ' More',
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 9,
                  fontFamily: 'Inter',
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                  border: Border.all(color: Colors.blue.withOpacity(0.5), width: 0.5),
                ),
              ),
              Text(
                ' Income Only',
                style: TextStyle(
                  color: isDark ? Colors.white30 : Colors.black38,
                  fontSize: 9,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ],
      ),
    ));
  }
}


