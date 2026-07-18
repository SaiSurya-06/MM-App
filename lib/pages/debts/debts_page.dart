import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/debts_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/accounts_provider.dart';
import '../../models/debt_loan.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/toast_notification.dart';
import '../../core/utils/currency_formatter.dart';

class DebtsPage extends ConsumerStatefulWidget {
  const DebtsPage({super.key});

  @override
  ConsumerState<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends ConsumerState<DebtsPage> {
  void _openAddDebtSheet([DebtLoan? debt]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DebtFormSheet(debt: debt),
    );
  }

  void _showRecordPaymentDialog(DebtLoan debt, String currency) {
    final accounts = ref.read(accountsProvider).accounts;
    if (accounts.isEmpty) {
      ToastNotification.show(context, 'Please create a funding account first.', isError: true);
      return;
    }

    int? selectedAccountId = accounts.first.id;
    final TextEditingController amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Record Payment to ${debt.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Current Balance: ${CurrencyFormatter.format(debt.balance, currency)}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              const Text('Source Account', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              DropdownButtonFormField<int>(
                value: selectedAccountId,
                decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                items: accounts.map((acc) => DropdownMenuItem(value: acc.id, child: Text('${acc.name} (${CurrencyFormatter.format(acc.balance, currency)})'))).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => selectedAccountId = val);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Payment Amount',
                  prefixIcon: Icon(Icons.payment),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final amt = double.tryParse(amountController.text) ?? 0.0;
                if (amt <= 0) {
                  ToastNotification.show(context, 'Please enter a valid amount', isError: true);
                  return;
                }
                final acc = accounts.firstWhere((a) => a.id == selectedAccountId);
                if (acc.balance < amt) {
                  ToastNotification.show(context, 'Insufficient balance in selected account.', isError: true);
                  return;
                }

                final success = await ref.read(debtsProvider.notifier).recordPayment(debt.id!, amt, selectedAccountId!);
                if (success && context.mounted) {
                  ToastNotification.show(context, 'Payment of ${CurrencyFormatter.format(amt, currency)} recorded.');
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final debtsState = ref.watch(debtsProvider);
    final authState = ref.watch(authProvider);
    final currency = authState.profile?.preferredCurrency ?? 'USD';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debt & Loan Tracker'),
        actions: [
          IconButton(
            onPressed: () => _openAddDebtSheet(),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: debtsState.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE53935)))
          : debtsState.debts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.credit_score_outlined, size: 64, color: Colors.grey.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      const Text(
                        'No loans or debts tracked yet.',
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () => _openAddDebtSheet(),
                        icon: const Icon(Icons.add),
                        label: const Text('Add Debt / Loan'),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    StrategyComparisonCard(debts: debtsState.debts, currency: currency),
                    ...debtsState.debts.map((debt) {
                      final paidAmount = (debt.originalAmount - debt.balance).clamp(0.0, double.infinity);
                      final progress = debt.originalAmount > 0 
                          ? (paidAmount / debt.originalAmount).clamp(0.0, 1.0)
                          : 0.0;
                      
                      final payoffMonths = debt.monthsToPayoff;
                      final totalInterest = debt.totalInterestPaid;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: TiltCardGesture(
                          onTap: () => _openAddDebtSheet(debt),
                          child: GlassmorphismCard(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          debt.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          debt.type.toUpperCase(),
                                          style: const TextStyle(fontSize: 9, color: Colors.grey, fontWeight: FontWeight.bold, letterSpacing: 1.0),
                                        ),
                                      ],
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE53935).withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        CurrencyFormatter.format(debt.balance, currency),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE53935), fontSize: 15),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                
                                // Progress bar
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Paid: ${CurrencyFormatter.format(paidAmount, currency)}',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                    Text(
                                      'Goal: ${CurrencyFormatter.format(debt.originalAmount, currency)} (${(progress * 100).toStringAsFixed(0)}%)',
                                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 6,
                                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04),
                                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Projections
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Interest Rate', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text('${debt.interestRate.toStringAsFixed(1)}%', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Monthly Payment', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(CurrencyFormatter.format(debt.monthlyPayment, currency), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text('Start Date', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                        const SizedBox(height: 2),
                                        Text(DateFormat('MMM yyyy').format(debt.startDate), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24, thickness: 0.5),

                                // Amortization Schedule Details
                                AmortizationScheduleWidget(debt: debt, currency: currency),

                                const Divider(height: 24, thickness: 0.5),

                                // Timeline payoff projections
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Row(
                                        children: [
                                          const Icon(Icons.hourglass_empty, size: 16, color: Colors.grey),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              payoffMonths == -1
                                                  ? 'Will never pay off with current payment.'
                                                  : 'Timeline: $payoffMonths months (Interest: ${CurrencyFormatter.format(totalInterest, currency)})',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w500,
                                                color: payoffMonths == -1 ? Colors.orange : Colors.grey,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      style: IconButton.styleFrom(
                                        backgroundColor: const Color(0xFFE53935).withValues(alpha: 0.1),
                                        foregroundColor: const Color(0xFFE53935),
                                      ),
                                      onPressed: () => _showRecordPaymentDialog(debt, currency),
                                      icon: const Icon(Icons.payment, size: 18),
                                      tooltip: 'Record Payment',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}

class TiltCardGesture extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;
  const TiltCardGesture({super.key, required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: child,
    );
  }
}

class DebtFormSheet extends ConsumerStatefulWidget {
  final DebtLoan? debt;
  const DebtFormSheet({super.key, this.debt});

  @override
  ConsumerState<DebtFormSheet> createState() => _DebtFormSheetState();
}

class _DebtFormSheetState extends ConsumerState<DebtFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _balanceController;
  late TextEditingController _originalAmountController;
  late TextEditingController _interestController;
  late TextEditingController _paymentController;
  late String _selectedType;
  late DateTime _selectedDate;

  final List<String> _types = ['loan', 'credit_card'];

  @override
  void initState() {
    super.initState();
    final d = widget.debt;
    _nameController = TextEditingController(text: d?.name ?? '');
    _balanceController = TextEditingController(text: d?.balance.toString() ?? '');
    _originalAmountController = TextEditingController(text: d?.originalAmount.toString() ?? '');
    _interestController = TextEditingController(text: d?.interestRate.toString() ?? '');
    _paymentController = TextEditingController(text: d?.monthlyPayment.toString() ?? '');
    _selectedType = d?.type ?? 'loan';
    _selectedDate = d?.startDate ?? DateTime.now();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _balanceController.dispose();
    _originalAmountController.dispose();
    _interestController.dispose();
    _paymentController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2018),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFFE53935),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameController.text.trim();
    final balance = double.tryParse(_balanceController.text) ?? 0.0;
    final origAmount = double.tryParse(_originalAmountController.text) ?? 0.0;
    final rate = double.tryParse(_interestController.text) ?? 0.0;
    final pay = double.tryParse(_paymentController.text) ?? 0.0;

    bool success;
    if (widget.debt == null) {
      success = await ref.read(debtsProvider.notifier).addDebt(
            name: name,
            type: _selectedType,
            balance: balance,
            originalAmount: origAmount,
            interestRate: rate,
            monthlyPayment: pay,
            startDate: _selectedDate,
          );
    } else {
      final updated = widget.debt!.copyWith(
        name: name,
        type: _selectedType,
        balance: balance,
        originalAmount: origAmount,
        interestRate: rate,
        monthlyPayment: pay,
        startDate: _selectedDate,
      );
      success = await ref.read(debtsProvider.notifier).updateDebt(updated);
    }

    if (success && mounted) {
      ToastNotification.show(context, widget.debt == null ? 'Debt added successfully.' : 'Debt updated.');
      Navigator.pop(context);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E2E) : Colors.white,
        title: const Text('Delete Debt Tracker', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this debt tracker?'),
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
    if (confirmed != true) return;

    final success = await ref.read(debtsProvider.notifier).deleteDebt(widget.debt!.id!);
    if (success && mounted) {
      ToastNotification.show(context, 'Debt tracker deleted.');
      Navigator.pop(context);
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
                widget.debt == null ? 'Track Debt / Loan' : 'Edit Debt Details',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Inter'),
              ),
              const SizedBox(height: 16),
              
              TextFormField(
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Name (e.g. Home Loan)', prefixIcon: Icon(Icons.badge_outlined)),
                validator: (val) => val == null || val.trim().isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Type', prefixIcon: Icon(Icons.category_outlined)),
                dropdownColor: isDark ? const Color(0xFF1E1E2E) : Colors.white,
                items: _types.map((type) => DropdownMenuItem(value: type, child: Text(type.replaceAll('_', ' ').toUpperCase()))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _originalAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Original Debt', prefixIcon: Icon(Icons.money)),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _balanceController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Current Balance', prefixIcon: Icon(Icons.account_balance_wallet)),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid amount' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _interestController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Interest Rate %', prefixIcon: Icon(Icons.percent)),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid rate' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _paymentController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(labelText: 'Monthly Payment', prefixIcon: Icon(Icons.payment)),
                      validator: (val) => val == null || double.tryParse(val) == null ? 'Invalid payment' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Start Date', prefixIcon: Icon(Icons.calendar_today)),
                  child: Text(DateFormat('MMMM dd, yyyy').format(_selectedDate), style: const TextStyle(fontSize: 14)),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _save,
                child: Text(widget.debt == null ? 'Track Debt' : 'Save Changes'),
              ),
              if (widget.debt != null) ...[
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
                  label: const Text('Stop Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AmortizationScheduleWidget extends StatefulWidget {
  final DebtLoan debt;
  final String currency;
  const AmortizationScheduleWidget({super.key, required this.debt, required this.currency});

  @override
  State<AmortizationScheduleWidget> createState() => _AmortizationScheduleWidgetState();
}

class _AmortizationScheduleWidgetState extends State<AmortizationScheduleWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate schedule
    final List<Map<String, dynamic>> schedule = [];
    double tempBalance = widget.debt.balance;
    final rate = widget.debt.interestRate / 100 / 12;
    final payment = widget.debt.monthlyPayment;
    
    DateTime paymentDate = DateTime.now();

    for (int i = 1; i <= 12; i++) {
      if (tempBalance <= 0) break;
      final interest = tempBalance * rate;
      final principal = (payment - interest).clamp(0.0, tempBalance);
      tempBalance = (tempBalance - principal).clamp(0.0, double.infinity);
      paymentDate = DateTime(paymentDate.year, paymentDate.month + 1, 1);
      
      schedule.add({
        'month': DateFormat('MMM yyyy').format(paymentDate),
        'principal': principal,
        'interest': interest,
        'remaining': tempBalance,
      });
      if (tempBalance <= 0) break;
    }

    if (schedule.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amortization Schedule (Next 12 Mos)',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Inter'),
                ),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 18,
                  color: Colors.grey,
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(2),
                3: FlexColumnWidth(2.5),
              },
              children: [
                TableRow(
                  children: [
                    _buildHeaderCell('Month'),
                    _buildHeaderCell('Principal'),
                    _buildHeaderCell('Interest'),
                    _buildHeaderCell('Remaining'),
                  ],
                ),
                ...schedule.map((row) => TableRow(
                  children: [
                    _buildCell(row['month'] as String),
                    _buildCell(CurrencyFormatter.format(row['principal'] as double, widget.currency)),
                    _buildCell(CurrencyFormatter.format(row['interest'] as double, widget.currency)),
                    _buildCell(CurrencyFormatter.format(row['remaining'] as double, widget.currency)),
                  ],
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildHeaderCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Inter'),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildCell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        text,
        style: const TextStyle(fontSize: 10, fontFamily: 'Inter'),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class StrategyComparisonCard extends StatelessWidget {
  final List<DebtLoan> debts;
  final String currency;
  const StrategyComparisonCard({super.key, required this.debts, required this.currency});

  @override
  Widget build(BuildContext context) {
    if (debts.length < 2) return const SizedBox.shrink();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Sort for Snowball (smallest balance first)
    final snowballList = List<DebtLoan>.from(debts)..sort((a, b) => a.balance.compareTo(b.balance));
    
    // Sort for Avalanche (highest interest rate first)
    final avalancheList = List<DebtLoan>.from(debts)..sort((a, b) => b.interestRate.compareTo(a.interestRate));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GlassmorphismCard(
        padding: const EdgeInsets.all(16),
        color: isDark ? const Color(0xFF1E1E2E).withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.02),
        borderColor: const Color(0xFFE53935).withValues(alpha: 0.2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.analytics_outlined, color: Color(0xFFE53935), size: 20),
                SizedBox(width: 8),
                Text(
                  'Debt Payoff Strategy Guide',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, fontFamily: 'Inter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Compare two popular payoff strategies for your current debts:',
              style: TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'Inter'),
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Snowball
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '❄️ Debt Snowball',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pay smallest balance first for quick wins and motivation.',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      const Text('PAYOFF ORDER:', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Inter')),
                      ...snowballList.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '- ${d.name} (${CurrencyFormatter.format(d.balance, currency)})',
                          style: const TextStyle(fontSize: 9.5, fontFamily: 'Inter'),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Avalanche
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '⚡ Debt Avalanche',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark ? Colors.amber.shade300 : Colors.amber.shade700,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Pay highest interest first. Mathematically saves the most interest.',
                        style: TextStyle(fontSize: 10, color: Colors.grey, fontFamily: 'Inter'),
                      ),
                      const SizedBox(height: 8),
                      const Text('PAYOFF ORDER:', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.grey, fontFamily: 'Inter')),
                      ...avalancheList.map((d) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '- ${d.name} (${d.interestRate.toStringAsFixed(1)}%)',
                          style: const TextStyle(fontSize: 9.5, fontFamily: 'Inter'),
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
