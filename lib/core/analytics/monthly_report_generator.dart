import 'package:intl/intl.dart';
import '../database/database.dart';
import '../../models/transaction.dart';
import '../../providers/analytics_provider.dart';
import 'ai_analyst.dart';
import '../utils/currency_formatter.dart';

class MonthlyReport {
  final String month; // Format: "yyyy-MM"
  final DateTime dateGenerated; // Always the 1st of the next month
  final double totalIncome;
  final double totalExpense;
  final double totalSavings;
  final double savingsRate; // Percentage
  final int totalBudgets;
  final int budgetsExceeded;
  final List<Map<String, dynamic>> budgetDetails; // {categoryName, limit, spent, exceededAmount}
  final List<AiAnomaly> anomalies;
  final List<String> suggestions;

  MonthlyReport({
    required this.month,
    required this.dateGenerated,
    required this.totalIncome,
    required this.totalExpense,
    required this.totalSavings,
    required this.savingsRate,
    required this.totalBudgets,
    required this.budgetsExceeded,
    required this.budgetDetails,
    required this.anomalies,
    required this.suggestions,
  });

  String get formattedMonth {
    try {
      final date = DateTime.parse('$month-01');
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return month;
    }
  }

  String get formattedDateGenerated {
    return DateFormat('MMMM d, yyyy').format(dateGenerated);
  }
}

class MonthlyReportGenerator {
  /// Fetch all historical months that contain transaction data
  static Future<List<String>> getAvailableReportMonths() async {
    try {
      final db = await AppDatabase.instance.database;
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT DISTINCT strftime('%Y-%m', date) as month
        FROM transaction_log
        ORDER BY month DESC
      ''');
      return result.map((row) => row['month'] as String).toList();
    } catch (_) {
      return [];
    }
  }

  /// Generate a detailed report for a specific month
  static Future<MonthlyReport> generateReportForMonth(
    String monthStr,
    List<Transaction> allTransactions,
    String currency,
  ) async {
    final db = await AppDatabase.instance.database;

    // Parse the target month
    final parts = monthStr.split('-');
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    
    // Generation date is the 1st of the following month
    final dateGenerated = DateTime(year, month + 1, 1);

    // 1. Calculate Income, Expense, and Savings
    final List<Map<String, dynamic>> totalsQuery = await db.rawQuery('''
      SELECT type, SUM(amount) as total
      FROM transaction_log
      WHERE strftime('%Y-%m', date) = ?
      GROUP BY type
    ''', [monthStr]);

    double income = 0.0;
    double expense = 0.0;
    for (var row in totalsQuery) {
      if (row['type'] == 'income') {
        income = (row['total'] as num).toDouble();
      } else if (row['type'] == 'expense') {
        expense = (row['total'] as num).toDouble();
      }
    }

    final double savings = income - expense;
    final double savingsRate = income > 0 ? (savings / income) * 100 : 0.0;

    // 2. Fetch Budgets and Category Spendings for this month
    final List<Map<String, dynamic>> budgetsQuery = await db.rawQuery('''
      SELECT b.limit_amount, c.name, c.id as category_id,
        (SELECT SUM(amount) FROM transaction_log WHERE type = 'expense' AND category_id = c.id AND strftime('%Y-%m', date) = ?) as spent
      FROM budget b
      INNER JOIN category c ON b.category_id = c.id
      WHERE b.month = ?
    ''', [monthStr, monthStr]);

    int totalBudgets = budgetsQuery.length;
    int budgetsExceeded = 0;
    final List<Map<String, dynamic>> budgetDetails = [];
    final List<String> exceededCategoryNames = [];

    for (var row in budgetsQuery) {
      final catName = row['name'] as String;
      final limit = (row['limit_amount'] as num).toDouble();
      final spent = (row['spent'] as num?)?.toDouble() ?? 0.0;
      final exceeded = spent > limit;
      final exceededAmount = exceeded ? spent - limit : 0.0;

      if (exceeded) {
        budgetsExceeded++;
        exceededCategoryNames.add(catName);
      }

      budgetDetails.add({
        'categoryName': catName,
        'limit': limit,
        'spent': spent,
        'exceededAmount': exceededAmount,
      });
    }

    // 3. Find Outliers/Anomalies for this month (using historical baseline from before this month)
    // Filter transactions to those in this month and before it
    final monthEnd = DateTime(year, month + 1, 0, 23, 59, 59);
    final priorTransactions = allTransactions.where((tx) => tx.date.isBefore(monthEnd)).toList();

    final List<Map<String, dynamic>> allCategories = await db.query('category');
    final Map<int, String> categoryNamesMap = {};
    for (var cat in allCategories) {
      categoryNamesMap[cat['id'] as int] = cat['name'] as String;
    }

    // Generate anomalies based on the history up to the end of the report month
    final allAnomalies = AiAnalyst.detectAnomalies(priorTransactions, categoryNamesMap);
    // Filter to only anomalies occurring in the report month
    final monthStartStr = '$monthStr-01';
    final monthStart = DateTime.parse(monthStartStr);
    final monthAnomalies = allAnomalies.where((anom) {
      return (anom.date.isAfter(monthStart) || anom.date.isAtSameMomentAs(monthStart)) &&
             anom.date.isBefore(monthEnd);
    }).toList();

    // 4. Run AI Trend analysis using data up to this month
    // Build monthly comparisons list from history up to this month
    final List<MonthlyComparison> history = [];
    for (int i = 5; i >= 0; i--) {
      final target = DateTime(year, month - i, 1);
      final targetStr = DateFormat('yyyy-MM').format(target);
      final label = DateFormat('MMM').format(target);

      final List<Map<String, dynamic>> rowSum = await db.rawQuery('''
        SELECT type, SUM(amount) as total
        FROM transaction_log
        WHERE strftime('%Y-%m', date) = ?
        GROUP BY type
      ''', [targetStr]);

      double inc = 0.0;
      double exp = 0.0;
      for (var row in rowSum) {
        if (row['type'] == 'income') {
          inc = (row['total'] as num).toDouble();
        } else if (row['type'] == 'expense') {
          exp = (row['total'] as num).toDouble();
        }
      }
      history.add(MonthlyComparison(month: label, income: inc, expense: exp));
    }
    final List<Map<String, dynamic>> monthlyCategoryHistory = await db.rawQuery('''
      SELECT category_id, strftime('%Y-%m', date) as month, SUM(amount) as total
      FROM transaction_log
      WHERE type = 'expense' AND strftime('%Y-%m', date) < ?
      GROUP BY category_id, month
    ''', [monthStr]);

    final Map<String, List<double>> categoryMonthlyHistories = {};
    for (var row in monthlyCategoryHistory) {
      final catId = row['category_id'] as int;
      final catName = categoryNamesMap[catId] ?? 'Category';
      final total = (row['total'] as num).toDouble();
      categoryMonthlyHistories.putIfAbsent(catName, () => []).add(total);
    }

    final forecast = AiAnalyst.calculateForecast(history, expense, categoryMonthlyHistories);

    // 5. Generate AI Suggestions / Recommendations
    final List<String> suggestions = [];

    // Rule A: Savings Rate Recommendation
    if (savingsRate < 0) {
      suggestions.add(
        '⚠️ CRITICAL DEFICIT: Your spending exceeded income. We recommend cutting all non-essential dining/entertainment immediately and using cash envelopes to restrict outflow.'
      );
    } else if (savingsRate < 10) {
      suggestions.add(
        '🚨 LOW SAVINGS: Your savings rate of ${savingsRate.toStringAsFixed(1)}% is below the recommended 10% baseline. Setup a recurring auto-saving transfer of 10% on the 1st of next month.'
      );
    } else if (savingsRate < 20) {
      suggestions.add(
        '📈 STRENGTHEN SAVINGS: Good progress at ${savingsRate.toStringAsFixed(1)}% saved. Try setting budget limits for your top 3 expense categories to reach the golden 20% savings rate.'
      );
    } else {
      suggestions.add(
        '🌟 OPTIMAL SAVINGS: Amazing! You saved ${savingsRate.toStringAsFixed(1)}% of your income. We recommend allocating a portion of these savings into long-term investments.'
      );
    }

    // Rule B: Budget Compliance Advice
    if (budgetsExceeded > 0) {
      final cats = exceededCategoryNames.join(', ');
      suggestions.add(
        '📉 BUDGET OVERRUNS: You exceeded your budget limit in: $cats. We recommend setting a spending alert inside these categories or lowering your credit card limit.'
      );
    } else if (totalBudgets > 0) {
      suggestions.add(
        '🎯 PERFECT COMPLIANCE: Congratulations! You stayed within all category budget limits. Lock in these limit configurations to build consistency.'
      );
    } else {
      suggestions.add(
        '📋 BUDGET UNMANAGED: You had no active budgets set. Creating category limits is the most effective way to control spending. Try setting a budget for Food and Transport first.'
      );
    }

    // Rule C: Anomaly Analysis
    if (monthAnomalies.isNotEmpty) {
      final topAnomaly = monthAnomalies.first;
      suggestions.add(
        '⚡ SPENDING SPIKE: A transaction of ${CurrencyFormatter.format(topAnomaly.amount, currency)} on "${topAnomaly.title}" in ${topAnomaly.categoryName} was ${topAnomaly.zScore.toStringAsFixed(1)}x standard deviations above your historical mean. Audit this transaction for impulse spending.'
      );
    }

    // Rule D: Trend Projections
    if (forecast.trendDirection == 'upward') {
      suggestions.add(
        '🔮 AI FORECAST ALERT: Our linear regression model projects an upward spending pressure for next month (+${forecast.changePercentage.toStringAsFixed(1)}%). We suggest reducing utility and leisure limits by 10% to prevent overruns.'
      );
    } else if (forecast.trendDirection == 'downward') {
      suggestions.add(
        '🔮 AI FORECAST STABLE: Regression forecast indicates downward spending momentum. Keep maintaining this velocity to accelerate your savings goal dates.'
      );
    }

    return MonthlyReport(
      month: monthStr,
      dateGenerated: dateGenerated,
      totalIncome: income,
      totalExpense: expense,
      totalSavings: savings,
      savingsRate: savingsRate,
      totalBudgets: totalBudgets,
      budgetsExceeded: budgetsExceeded,
      budgetDetails: budgetDetails,
      anomalies: monthAnomalies,
      suggestions: suggestions,
    );
  }
}
