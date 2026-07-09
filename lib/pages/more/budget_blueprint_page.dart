import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:excel/excel.dart' hide Border;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/database/database.dart';
import '../../core/utils/currency_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../widgets/common/glassmorphism_card.dart';
import '../../widgets/common/premium_background.dart';

class BudgetBlueprintPage extends ConsumerStatefulWidget {
  const BudgetBlueprintPage({super.key});

  @override
  ConsumerState<BudgetBlueprintPage> createState() => _BudgetBlueprintPageState();
}

class _BudgetBlueprintPageState extends ConsumerState<BudgetBlueprintPage> {
  final _formKey = GlobalKey<FormState>();
  final _incomeController = TextEditingController(text: "50000");
  final _fixedExpensesController = TextEditingController(text: "20000");
  final _savingsGoalController = TextEditingController(text: "10000");

  // Custom Strategy percentages
  final _customNeedsController = TextEditingController(text: "50");
  final _customWantsController = TextEditingController(text: "30");
  final _customSavingsController = TextEditingController(text: "20");
  
  String _selectedStrategy = "50/30/20 Rule";
  bool _hasGenerated = false;

  // Generated Blueprint Data
  double _income = 0.0;
  double _fixedExpenses = 0.0;
  double _savingsGoal = 0.0;

  double _targetNeeds = 0.0;
  double _targetWants = 0.0;
  double _targetSavings = 0.0;

  double _actualNeedsAvg = 0.0;
  double _actualWantsAvg = 0.0;

  Map<int, double> _categorySpendAverages = {};
  Map<int, String> _categoryTypes = {};

  final List<String> _strategies = [
    "50/30/20 Rule",
    "70/20/10 Rule",
    "Zero-Based Budgeting",
    "Envelope Budgeting",
    "60% Solution",
    "Custom Strategy",
  ];

  @override
  void initState() {
    super.initState();
    // Re-trigger calculations when custom values change
    _customNeedsController.addListener(_onCustomPercentChanged);
    _customWantsController.addListener(_onCustomPercentChanged);
    _customSavingsController.addListener(_onCustomPercentChanged);
  }

  void _onCustomPercentChanged() {
    if (_selectedStrategy == "Custom Strategy" && _hasGenerated) {
      _calculateAllocation();
    }
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _fixedExpensesController.dispose();
    _savingsGoalController.dispose();
    _customNeedsController.dispose();
    _customWantsController.dispose();
    _customSavingsController.dispose();
    super.dispose();
  }

  int get _customTotalSum {
    final n = int.tryParse(_customNeedsController.text) ?? 0;
    final w = int.tryParse(_customWantsController.text) ?? 0;
    final s = int.tryParse(_customSavingsController.text) ?? 0;
    return n + w + s;
  }

  bool get _isCustomValid => _customTotalSum == 100;

  void _calculateAllocation() {
    final incomeVal = double.tryParse(_incomeController.text) ?? 0.0;

    if (_selectedStrategy == "50/30/20 Rule") {
      _targetNeeds = incomeVal * 0.50;
      _targetWants = incomeVal * 0.30;
      _targetSavings = incomeVal * 0.20;
    } else if (_selectedStrategy == "70/20/10 Rule") {
      _targetNeeds = incomeVal * 0.70;
      _targetSavings = incomeVal * 0.20;
      _targetWants = incomeVal * 0.10;
    } else if (_selectedStrategy == "Zero-Based Budgeting") {
      // Zero-Based Budgeting default allocation split: Needs: 60%, Wants: 20%, Savings: 20%
      _targetNeeds = incomeVal * 0.60;
      _targetWants = incomeVal * 0.20;
      _targetSavings = incomeVal * 0.20;
    } else if (_selectedStrategy == "Envelope Budgeting") {
      // Needs: 55%, Wants: 25%, Savings: 20%
      _targetNeeds = incomeVal * 0.55;
      _targetWants = incomeVal * 0.25;
      _targetSavings = incomeVal * 0.20;
    } else if (_selectedStrategy == "60% Solution") {
      // Living Expenses (Needs): 60%, Savings: 20%, Wants: 10%, Retirement: 10% (Grouped Retirement into Savings)
      _targetNeeds = incomeVal * 0.60;
      _targetWants = incomeVal * 0.10;
      _targetSavings = incomeVal * 0.30;
    } else if (_selectedStrategy == "Custom Strategy") {
      final nPct = (double.tryParse(_customNeedsController.text) ?? 0.0) / 100.0;
      final wPct = (double.tryParse(_customWantsController.text) ?? 0.0) / 100.0;
      final sPct = (double.tryParse(_customSavingsController.text) ?? 0.0) / 100.0;
      
      _targetNeeds = incomeVal * nPct;
      _targetWants = incomeVal * wPct;
      _targetSavings = incomeVal * sPct;
    }
  }

  Future<void> _generateBlueprint() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStrategy == "Custom Strategy" && !_isCustomValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Custom percentages must sum to exactly 100%"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() {
      _income = double.parse(_incomeController.text);
      _fixedExpenses = double.parse(_fixedExpensesController.text);
      _savingsGoal = double.parse(_savingsGoalController.text);
    });

    _calculateAllocation();

    // 2. Fetch Category data and historical spending from Database
    final db = await AppDatabase.instance.database;

    // Load categories
    final List<Map<String, dynamic>> cats = await db.query('category');
    final catTypes = <int, String>{};
    for (var c in cats) {
      final id = c['id'] as int;
      
      // Classify category types
      final nameLower = (c['name'] as String).toLowerCase();
      if (nameLower == 'rent' || nameLower == 'utilities' || nameLower == 'health' || nameLower == 'transport' || nameLower == 'credit card payment') {
        catTypes[id] = 'needs';
      } else if (nameLower == 'food' || nameLower == 'entertainment' || nameLower == 'other') {
        catTypes[id] = 'wants';
      } else {
        catTypes[id] = 'wants'; // Default
      }
    }

    // Load transaction spending for the last 3 months
    final List<Map<String, dynamic>> txs = await db.rawQuery('''
      SELECT category_id, amount, strftime('%Y-%m', date) as month
      FROM transaction_log
      WHERE type = 'expense'
    ''');

    // Group spending by month and category
    final monthlySpending = <String, Map<int, double>>{};
    final uniqueMonths = <String>{};

    for (var tx in txs) {
      final month = tx['month'] as String;
      final catId = tx['category_id'] as int;
      final amt = (tx['amount'] as num).toDouble();
      
      uniqueMonths.add(month);
      monthlySpending.putIfAbsent(month, () => {});
      monthlySpending[month]![catId] = (monthlySpending[month]![catId] ?? 0.0) + amt;
    }

    // Calculate average spending per category
    final catAverages = <int, double>{};
    final numMonths = uniqueMonths.isNotEmpty ? uniqueMonths.length : 1;

    for (var month in uniqueMonths) {
      final spendMap = monthlySpending[month]!;
      for (var entry in spendMap.entries) {
        catAverages[entry.key] = (catAverages[entry.key] ?? 0.0) + (entry.value / numMonths);
      }
    }

    // Sum actual average Needs and Wants
    double actualNeeds = 0.0;
    double actualWants = 0.0;

    for (var catId in catTypes.keys) {
      final avg = catAverages[catId] ?? 0.0;
      final type = catTypes[catId] ?? 'wants';
      if (type == 'needs') {
        actualNeeds += avg;
      } else {
        actualWants += avg;
      }
    }

    setState(() {
      _actualNeedsAvg = actualNeeds;
      _actualWantsAvg = actualWants;
      _categorySpendAverages = catAverages;
      _categoryTypes = catTypes;
      _hasGenerated = true;
    });
  }

  Future<void> _applyBudgets() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Apply Budgets"),
        content: Text("This will update or create category budgets for the current month based on the $_selectedStrategy blueprint. Proceed?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE53935)),
            child: const Text("Apply"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final budgetsNotifier = ref.read(budgetsProvider.notifier);

    // Heuristically distribute Needs and Wants budgets
    final needsCatIds = _categoryTypes.entries
        .where((e) => e.value == 'needs')
        .map((e) => e.key)
        .toList();
    final wantsCatIds = _categoryTypes.entries
        .where((e) => e.value == 'wants')
        .map((e) => e.key)
        .toList();

    Future<void> distribute(List<int> catIds, double totalTarget) async {
      double totalActual = 0.0;
      for (var id in catIds) {
        totalActual += _categorySpendAverages[id] ?? 0.0;
      }

      for (var id in catIds) {
        double limitAmount;
        if (totalActual > 0) {
          final proportion = (_categorySpendAverages[id] ?? 0.0) / totalActual;
          limitAmount = totalTarget * proportion;
        } else {
          limitAmount = totalTarget / catIds.length;
        }

        limitAmount = (limitAmount / 10).roundToDouble() * 10;
        if (limitAmount < 10) limitAmount = 10;

        await budgetsNotifier.setBudget(
          id,
          limitAmount,
          recurrence: 'monthly',
        );
      }
    }

    await distribute(needsCatIds, _targetNeeds);
    await distribute(wantsCatIds, _targetWants);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Blueprint applied! budgets successfully created for $currentMonth."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _exportToPDF(String currencySymbol) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                "MONEY MANAGER - BUDGETING BLUEPRINT REPORT",
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.Divider(thickness: 1),
              pw.SizedBox(height: 12),
              pw.Text("Budget Strategy: $_selectedStrategy", style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Monthly Net Income: $currencySymbol${_income.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Monthly Fixed Expenses: $currencySymbol${_fixedExpenses.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
              pw.Text("Savings Goal Target: $currencySymbol${_savingsGoal.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 24),
              pw.Text("Recommended Blueprint Targets vs. actual averages:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(),
                children: [
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Group", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Target Allocation", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Actual Monthly Avg", style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Needs")),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("$currencySymbol${_targetNeeds.toStringAsFixed(0)}")),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("$currencySymbol${_actualNeedsAvg.toStringAsFixed(0)}")),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Wants")),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("$currencySymbol${_targetWants.toStringAsFixed(0)}")),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("$currencySymbol${_actualWantsAvg.toStringAsFixed(0)}")),
                    ],
                  ),
                  pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Savings & Goals")),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("$currencySymbol${_targetSavings.toStringAsFixed(0)}")),
                      pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text("Direct Savings")),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text("Actionable Recommendations:", style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              if (_actualNeedsAvg > _targetNeeds)
                pw.Bullet(text: "Your Needs spending exceeds the target by $currencySymbol${(_actualNeedsAvg - _targetNeeds).toStringAsFixed(0)}. Try negotiating recurring contracts or downsizing utilities."),
              if (_actualWantsAvg > _targetWants)
                pw.Bullet(text: "Your variable Wants spending is over by $currencySymbol${(_actualWantsAvg - _targetWants).toStringAsFixed(0)}. We suggest reducing dining out or flexible entertainment options."),
              if (_fixedExpenses + _savingsGoal > _income)
                pw.Bullet(text: "Warning: Fixed expenses and savings goals exceed your total monthly income. Consider decreasing your savings target slightly to maintain liquidity."),
            ],
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Budgeting_Blueprint.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'My Personal Budgeting Blueprint',
    );
  }

  Future<void> _exportToExcel(String currencySymbol) async {
    final excel = Excel.createExcel();
    final sheet = excel['Budget Blueprint'];
    excel.delete('Sheet1');

    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    sheet.appendRow([TextCellValue('Personal Budgeting Blueprint Report')]);
    sheet.appendRow([]);
    sheet.appendRow([TextCellValue('Property'), TextCellValue('Value')]);
    sheet.appendRow([TextCellValue('Strategy'), TextCellValue(_selectedStrategy)]);
    sheet.appendRow([TextCellValue('Monthly Net Income ($currencySymbol)'), DoubleCellValue(_income)]);
    sheet.appendRow([TextCellValue('Estimated Fixed Expenses ($currencySymbol)'), DoubleCellValue(_fixedExpenses)]);
    sheet.appendRow([TextCellValue('Savings Goal Target ($currencySymbol)'), DoubleCellValue(_savingsGoal)]);
    sheet.appendRow([]);

    final headers = ['Group', 'Target Amount ($currencySymbol)', 'Actual Monthly Average ($currencySymbol)'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: sheet.maxRows));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    sheet.appendRow([TextCellValue('Needs'), DoubleCellValue(_targetNeeds), DoubleCellValue(_actualNeedsAvg)]);
    sheet.appendRow([TextCellValue('Wants'), DoubleCellValue(_targetWants), DoubleCellValue(_actualWantsAvg)]);
    sheet.appendRow([TextCellValue('Savings & Goals'), DoubleCellValue(_targetSavings), TextCellValue('')]);

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/Budgeting_Blueprint.xlsx');
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'My Personal Budgeting Blueprint',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);

    final currencyCode = ref.watch(authProvider).profile?.preferredCurrency ?? 'USD';
    final currencySymbol = CurrencyFormatter.getSymbol(currencyCode);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Budgeting Blueprint",
          style: TextStyle(
            fontFamily: 'Inter',
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textColor,
          ),
        ),
      ),
      body: PremiumBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInputsForm(isDark, currencySymbol),
              if (_hasGenerated) ...[
                const SizedBox(height: 24),
                _buildVisualSummaryCard(isDark),
                const SizedBox(height: 24),
                _buildBlueprintResults(isDark, currencySymbol),
                const SizedBox(height: 24),
                _buildRecommendationsCard(isDark, currencySymbol),
                const SizedBox(height: 24),
                _buildExportSection(currencySymbol),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE53935).withValues(alpha: 0.25),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton.icon(
                      onPressed: _applyBudgets,
                      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                      label: const Text(
                        "Apply Blueprint to Budgets",
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputsForm(bool isDark, String currencySymbol) {
    return GlassmorphismCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PLAN DETAILS",
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _incomeController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: "Monthly Net Income",
                prefixText: "$currencySymbol ",
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Income is required";
                if (double.tryParse(val) == null || double.parse(val) <= 0) {
                  return "Please enter a valid amount";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fixedExpensesController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: "Estimated Fixed Expenses (Rent, Bills)",
                prefixText: "$currencySymbol ",
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Fixed expenses required";
                if (double.tryParse(val) == null || double.parse(val) < 0) {
                  return "Please enter a valid amount";
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _savingsGoalController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 15),
              decoration: InputDecoration(
                labelText: "Savings / Goal Target",
                prefixText: "$currencySymbol ",
                border: const OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) return "Savings target required";
                if (double.tryParse(val) == null || double.parse(val) < 0) {
                  return "Please enter a valid amount";
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              "BUDGETING STRATEGY",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: isDark ? Colors.white24 : Colors.black26),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedStrategy,
                  isExpanded: true,
                  items: _strategies.map((s) {
                    return DropdownMenuItem<String>(
                      value: s,
                      child: Text(s, style: const TextStyle(fontSize: 14)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _selectedStrategy = val;
                      });
                    }
                  },
                ),
              ),
            ),
            if (_selectedStrategy == "Custom Strategy") ...[
              const SizedBox(height: 20),
              const Text(
                "CUSTOM PERCENTAGES (MUST SUM TO 100%)",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _customNeedsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: "Needs %",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _customWantsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: "Wants %",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _customSavingsController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        labelText: "Savings %",
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Badge(
                  backgroundColor: _isCustomValid ? Colors.green : Colors.red,
                  label: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(
                      _isCustomValid ? "Valid: 100%" : "Invalid sum: $_customTotalSum% (Must be 100%)",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _generateBlueprint,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Generate Blueprint",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisualSummaryCard(bool isDark) {
    final sections = [
      PieChartSectionData(
        value: _targetNeeds,
        color: Colors.blueAccent,
        title: 'Needs\n${((_targetNeeds / _income) * 100).toStringAsFixed(0)}%',
        radius: 65,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: _targetWants,
        color: Colors.orangeAccent,
        title: 'Wants\n${((_targetWants / _income) * 100).toStringAsFixed(0)}%',
        radius: 65,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
      PieChartSectionData(
        value: _targetSavings,
        color: Colors.greenAccent,
        title: 'Savings\n${((_targetSavings / _income) * 100).toStringAsFixed(0)}%',
        radius: 65,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      ),
    ];

    return GlassmorphismCard(
      child: Column(
        children: [
          const Text(
            "ALLOCATION BLUEPRINT CHART",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlueprintResults(bool isDark, String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Blueprint Breakdown ($_selectedStrategy)",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        _buildBlueprintCard(
          title: "Needs (Fixed & Vital)",
          target: _targetNeeds,
          actual: _actualNeedsAvg,
          color: Colors.blueAccent,
          subtitle: "Rent, Utilities, Transport, Health",
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 12),
        _buildBlueprintCard(
          title: "Wants (Variable & Flexible)",
          target: _targetWants,
          actual: _actualWantsAvg,
          color: Colors.orangeAccent,
          subtitle: "Food, Entertainment, Shopping",
          currencySymbol: currencySymbol,
        ),
        const SizedBox(height: 12),
        _buildBlueprintCard(
          title: "Savings & Goals",
          target: _targetSavings,
          actual: 0.0,
          color: Colors.greenAccent,
          subtitle: "Savings Goals, Investments, Debt Payoff",
          currencySymbol: currencySymbol,
          hideActual: true,
        ),
      ],
    );
  }

  Widget _buildBlueprintCard({
    required String title,
    required double target,
    required double actual,
    required Color color,
    required String subtitle,
    required String currencySymbol,
    bool hideActual = false,
  }) {
    final percent = target > 0 ? (actual / target) : 0.0;
    final progress = percent.clamp(0.0, 1.0);
    final statusColor = percent > 1.0 ? const Color(0xFFE53935) : color;

    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                "Target: $currencySymbol${target.toStringAsFixed(0)}",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          if (!hideActual) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Actual Average: $currencySymbol${actual.toStringAsFixed(2)}",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: percent > 1.0 ? const Color(0xFFE53935) : null,
                  ),
                ),
                Text(
                  "${(percent * 100).toStringAsFixed(0)}%",
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                color: statusColor,
                minHeight: 8,
              ),
            ),
          ] else ...[
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Auto-Allocated directly to Savings",
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
                Icon(Icons.savings_outlined, color: Colors.green),
              ],
            ),
          ]
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(bool isDark, String currencySymbol) {
    final list = <Widget>[];

    // Heuristics
    if (_actualNeedsAvg > _targetNeeds) {
      list.add(_buildRecommendationRow(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE53935),
        text: "Your average Needs spending ($currencySymbol${_actualNeedsAvg.toStringAsFixed(0)}) is higher than the recommended $currencySymbol${_targetNeeds.toStringAsFixed(0)}. Review bills or contracts to see where you can trim fixed costs.",
      ));
    } else {
      list.add(_buildRecommendationRow(
        icon: Icons.check_circle_outline,
        color: Colors.green,
        text: "Your Needs spending is well within limits! This creates a great margin for savings.",
      ));
    }

    if (_actualWantsAvg > _targetWants) {
      final excess = _actualWantsAvg - _targetWants;
      list.add(_buildRecommendationRow(
        icon: Icons.lightbulb_outline,
        color: Colors.orangeAccent,
        text: "Your Wants spending exceeds the target by $currencySymbol${excess.toStringAsFixed(0)}. We recommend adding budget limits on discretionary categories (like Entertainment and Food) to save $currencySymbol${excess.toStringAsFixed(0)}.",
      ));
    }

    if (_fixedExpenses + _savingsGoal > _income) {
      list.add(_buildRecommendationRow(
        icon: Icons.error_outline,
        color: const Color(0xFFE53935),
        text: "Warning: Your combined fixed expenses and savings goal exceed your total income! Consider adjusting your savings target down or finding additional income sources.",
      ));
    } else {
      final leftover = _income - _fixedExpenses - _savingsGoal;
      if (leftover > 0) {
        list.add(_buildRecommendationRow(
          icon: Icons.savings_outlined,
          color: Colors.green,
          text: "You have $currencySymbol${leftover.toStringAsFixed(0)} left over each month after fixed expenses and savings. You can allocate this surplus to extra debt payoff or accelerate your savings goals!",
        ));
      }
    }

    return GlassmorphismCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BLUEPRINT INSIGHTS",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          ...list,
        ],
      ),
    );
  }

  Widget _buildRecommendationRow({
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportSection(String currencySymbol) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportToPDF(currencySymbol),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
            label: const Text("Export PDF"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _exportToExcel(currencySymbol),
            icon: const Icon(Icons.table_chart, color: Colors.green),
            label: const Text("Export Excel"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }
}
