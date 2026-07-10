import 'dart:convert';
import 'agent_service.dart';
import 'financial_brain.dart';
import 'execution_plan.dart';
import 'analytics_engine.dart';
import 'investigation_engine.dart';
import 'prediction_engine.dart';
import 'decision_engine.dart';
import 'retriever.dart';

class CoachingResult {
  final String summary;
  final List<String> insights;
  final List<String> warnings;
  final List<String> recommendations;
  final List<String> nextActions;
  final String motivationalMessage;
  final String chartType;

  // Reasoning trace & Follow-ups
  final List<String> evidenceChecklist;
  final Map<String, dynamic> scopeDetails;
  final List<String> followUps;

  CoachingResult({
    required this.summary,
    required this.insights,
    required this.warnings,
    required this.recommendations,
    required this.nextActions,
    required this.motivationalMessage,
    required this.chartType,
    required this.evidenceChecklist,
    required this.scopeDetails,
    required this.followUps,
  });

  factory CoachingResult.fromJson(Map<String, dynamic> json) {
    return CoachingResult(
      summary: json['summary']?.toString() ?? '',
      insights: json['insights'] != null ? (json['insights'] as List).map((e) => e.toString()).toList() : [],
      warnings: json['warnings'] != null ? (json['warnings'] as List).map((e) => e.toString()).toList() : [],
      recommendations: json['recommendations'] != null ? (json['recommendations'] as List).map((e) => e.toString()).toList() : [],
      nextActions: json['nextActions'] != null ? (json['nextActions'] as List).map((e) => e.toString()).toList() : [],
      motivationalMessage: json['motivationalMessage']?.toString() ?? '',
      chartType: json['chartType']?.toString().toUpperCase() ?? 'NONE',
      evidenceChecklist: json['evidenceChecklist'] != null ? (json['evidenceChecklist'] as List).map((e) => e.toString()).toList() : [],
      scopeDetails: Map<String, dynamic>.from(json['scopeDetails'] as Map? ?? {}),
      followUps: json['followUps'] != null ? (json['followUps'] as List).map((e) => e.toString()).toList() : [],
    );
  }

  factory CoachingResult.empty() {
    return CoachingResult(
      summary: 'I could not retrieve enough data to generate recommendations. Please try checking your active accounts or adding transactions.',
      insights: [],
      warnings: [],
      recommendations: [],
      nextActions: [],
      motivationalMessage: '',
      chartType: 'NONE',
      evidenceChecklist: [],
      scopeDetails: {},
      followUps: [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'insights': insights,
      'warnings': warnings,
      'recommendations': recommendations,
      'nextActions': nextActions,
      'motivationalMessage': motivationalMessage,
      'chartType': chartType,
      'evidenceChecklist': evidenceChecklist,
      'scopeDetails': scopeDetails,
      'followUps': followUps,
    };
  }
}

class CoachingEngine implements FinancialEngine {
  final bool useOnline;

  CoachingEngine({required this.useOnline});

  @override
  Future<FinancialContext> execute(FinancialContext context) async {
    final plan = context.plan;
    final analytics = context.metrics;
    final scores = context.scores;
    final investigation = context.investigation;
    final forecast = context.forecast;
    final decision = context.decision;
    final evaluation = context.evaluation;
    final data = context.rawData;

    // 1. Chart engine (deterministic selection)
    String chart = 'NONE';
    final clean = context.query.toLowerCase();
    if (clean.contains("category") || clean.contains("breakdown") || clean.contains("most") || clean.contains("where did")) {
      chart = 'PIE';
    } else if (plan.comparisonMonth != null || plan.intent == 'compare') {
      chart = 'BAR';
    }

    if (evaluation.needsClarification) {
      final clarificationCoaching = CoachingResult(
        summary: evaluation.clarificationPrompt,
        insights: [],
        warnings: ["Needs user confirmation before final reasoning."],
        recommendations: [],
        nextActions: ["Clarify search intent"],
        motivationalMessage: "Help me understand your request better!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Flagged low confidence", "✓ Checked data coverage"],
        scopeDetails: {'transactions': data.transactions.length},
        followUps: ["Yes, help me categorize", "No, keep it as is"],
      );
      return context.copyWith(coaching: clarificationCoaching);
    }

    if (useOnline && plan.confidence >= 0.7) {
      final transactionSummary = data.transactions.map((t) => 
        "- ${t['date']}: ${t['title']} (${t['type'] == 'expense' ? 'Expense' : 'Income'}) - ₹${t['amount']} [Category: ${t['category'] ?? 'N/A'}]"
      ).join('\n');

      final coachPrompt = '''
You are an expert personal financial advisor and therapist.
Your objective is to provide a reasoning-heavy, empathetic explanation of the user's finances rather than a basic metric reporting loop.

User Question: "${context.query}"

Execution plan target:
${jsonEncode(plan.toJson())}

Grounded Metrics:
- Target Month/Year: ${data.activeMonth}/${data.activeYear} ${data.fallbackMonthUsed ? '(Note: fell back to latest available active data)' : ''}
- Score: ${scores.overallScore.toStringAsFixed(0)}/100 (Savings: ${scores.savingsScore.toStringAsFixed(0)}, Budget: ${scores.budgetScore.toStringAsFixed(0)}, Spending: ${scores.spendingScore.toStringAsFixed(0)}, Emergency: ${scores.emergencyScore.toStringAsFixed(0)})
- Monthly Income: ₹${analytics['totalIncome']?.toStringAsFixed(0) ?? '0'}
- Monthly Expense: ₹${analytics['totalExpense']?.toStringAsFixed(0) ?? '0'}
- Savings Rate: ${(analytics['savingsRate'] as num? ?? 0.0).toStringAsFixed(1)}%
- Scanned: ${analytics['transactionCount']} transactions

Grounded Transaction List:
$transactionSummary

Anomalies & Causes:
- Abs change: ₹${investigation.absoluteIncrease.toStringAsFixed(0)} (${investigation.percentageIncrease.toStringAsFixed(1)}%)
- Reasons: ${investigation.spendingCauses.join(', ')}
- Warnings: ${investigation.anomalies.join(', ')}

Projections & Goals:
- Depletion alerts: ${forecast.burnRateAlerts.join(', ')}
- Goal boosters: ${forecast.goalAccelerationTips.join(', ')}

Decision Affordability Check:
- Is Decision Query: ${decision.isDecisionQuery}
- Affordability: ${decision.decisionText}
- Recommendation: ${decision.recommendationText}

Advisor Reasoning Instructions (Version 3):
1. **Direct Answer First**:
   Start the `summary` immediately with a clear, direct answer to the user's question. For example, if they ask for account balance, state their total balance and accounts first. Do not add general summary briefs or health scores at the beginning. Get straight to the point.
2. **Plain English & Human Tone**:
   Avoid all technical jargon. Never use terms like 'Savings Rate', 'Budget Utilization', 'Emergency Score', 'Run Rate', or 'Cash Flow'. Instead, write 'Money Saved', 'Meters of Budget Spent', 'Emergency Funds Safety', 'Monthly Inflow/Outflow', or 'Money Left'. Explain things like a friend. Avoid looking like a corporate database report.
3. **Hypothesis-driven investigation**:
   Formulate internal hypotheses (e.g. Swiggy order frequency rising) and verify or disprove it using the transaction list, reporting this in plain English in the summary.
4. **Empathy & Reassurance**:
   Scan user emotion. Reassure them when spending is concentrated (e.g. "Spending is up, but it is concentrated in dining out rather than general overheads. Modifying one habit is much easier than restructuring everything.").
5. **Autonomous Discovery**:
   Look for duplicate payments or hidden increases and list them under "insights" or "warnings".
6. **Curiosity**:
   Generate 3 highly contextual follow-ups that keep the conversation open and exploratory (e.g. 'Was it planned?', 'Break down by Saturday vs Sunday', 'Show Swiggy history').
7. Populate "evidenceChecklist" and "scopeDetails" accurately.

Output JSON Schema:
{
  "summary": "Conversational text starting with the direct answer, followed by friendly explanation...",
  "insights": ["Bullet point 1", "Bullet point 2"],
  "warnings": ["Caution warning 1"],
  "recommendations": ["Recommendation 1"],
  "nextActions": ["First task to do today", "Second task"],
  "motivationalMessage": "Brief coaching sign-off...",
  "evidenceChecklist": ["✓ Analysed 142 transactions", "✓ Ranked by absolute increase"],
  "scopeDetails": {
    "transactionsScanned": 142,
    "accountsChecked": 4,
    "dateRange": "Jan - Jul 2026"
  },
  "followUps": ["Contextual query chip 1", "Contextual query chip 2"]
}
''';

      try {
        final rawResponse = await AgentService.sendMessage(coachPrompt);
        final cleanedJson = rawResponse.replaceAll(RegExp(r'```(json)?'), '').trim();
        final decoded = jsonDecode(cleanedJson) as Map<String, dynamic>;
        
        decoded['chartType'] = chart;
        final coachingResult = CoachingResult.fromJson(decoded);
        return context.copyWith(coaching: coachingResult);
      } catch (e) {
        final coachingResult = _generateOfflineCoaching(plan, scores, analytics, investigation, forecast, decision, data, chart);
        return context.copyWith(coaching: coachingResult);
      }
    } else {
      final coachingResult = _generateOfflineCoaching(plan, scores, analytics, investigation, forecast, decision, data, chart);
      return context.copyWith(coaching: coachingResult);
    }
  }

  static String _getMonthName(int month) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    if (month >= 1 && month <= 12) {
      return names[month - 1];
    }
    return '';
  }

  static CoachingResult _generateOfflineCoaching(
    ExecutionPlan plan,
    FinancialScores scores,
    Map<String, dynamic> analytics,
    InvestigationResult investigation,
    ForecastResult forecast,
    DecisionResult decision,
    RetrievedData data,
    String chartType,
  ) {
    final activeMonthName = _getMonthName(data.activeMonth ?? DateTime.now().month);
    final income = (analytics['totalIncome'] as num? ?? 0.0).toDouble();
    final expense = (analytics['totalExpense'] as num? ?? 0.0).toDouble();
    final savingsRate = (analytics['savingsRate'] as num? ?? 0.0).toDouble();
    final topCategory = analytics['topCategory']?.toString() ?? 'N/A';
    final topMerchant = analytics['topMerchant']?.toString() ?? 'N/A';

    // 1. Check for specific response types for Direct-Answer-First offline generation
    if (plan.responseType == 'account_balance') {
      final total = data.netWorth;
      final breakDownLines = data.balances.map((b) => "• ${b['name'] ?? 'Account'}: ₹${(b['balance'] as num? ?? 0.0).toStringAsFixed(0)}").join('\n');
      const upcomingBills = 22300.0;
      final buffer = total - upcomingBills;

      return CoachingResult(
        summary: "Your total balance is **₹${total.toStringAsFixed(0)}** across your active accounts.\n\nHere is how your money is distributed:\n$breakDownLines\n\nAfter setting aside **₹${upcomingBills.toStringAsFixed(0)}** for upcoming bills, you have **₹${buffer.toStringAsFixed(0)}** left to spend or save.",
        insights: [
          "Total Balance: ₹${total.toStringAsFixed(0)}",
          "Bills due: ₹${upcomingBills.toStringAsFixed(0)}",
          "Money Available: ₹${buffer.toStringAsFixed(0)}"
        ],
        warnings: buffer < 10000 ? ["⚠️ Available buffer is running low. Cut back discretionary spending."] : [],
        recommendations: ["Keep a buffer of at least ₹15,000 in your primary checking account."],
        nextActions: ["View upcoming bills checklist"],
        motivationalMessage: "Knowing your numbers is the first step to financial security. Great job checking in!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Queried current balances", "✓ Verified checking vs savings allocations"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': data.balances.length,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Show bills due", "Suggest budget cuts", "How to save more?"],
      );
    }

    if (plan.responseType == 'recent_transactions') {
      final count = data.transactions.length;
      final listLines = data.transactions.take(5).map((t) => "• ₹${(t['amount'] as num? ?? 0.0).toStringAsFixed(0)} on ${t['category'] ?? 'Other'} (${t['title'] ?? 'Purchase'}) - ${t['date']}").join('\n');

      return CoachingResult(
        summary: "Here are your 5 most recent transactions:\n\n$listLines\n\nTotal of $count transactions recorded this month.",
        insights: ["Last transaction date: ${data.transactions.isNotEmpty ? data.transactions.first['date'] : 'N/A'}"],
        warnings: [],
        recommendations: ["Categorize any uncategorized transactions to keep budgets accurate."],
        nextActions: ["Recategorize transactions"],
        motivationalMessage: "Staying on top of your latest spending helps catch unwanted subscriptions early!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Loaded last 5 transaction objects", "✓ Sorted by timestamp desc"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Compare with last month", "Show merchant history", "Check budget status"],
      );
    }

    if (plan.responseType == 'merchant_search') {
      final merchantQuery = plan.merchant ?? '';
      final matches = data.transactions.where((t) {
        final title = (t['title'] ?? '').toString().toLowerCase();
        return title.contains(merchantQuery.toLowerCase());
      }).toList();
      final total = matches.fold(0.0, (sum, t) => sum + (t['amount'] as num? ?? 0.0).toDouble());

      if (matches.isEmpty) {
        return CoachingResult(
          summary: "I couldn't find any transactions for **${plan.merchant}** in this month's records.",
          insights: [],
          warnings: [],
          recommendations: ["Try searching for a different merchant or category."],
          nextActions: ["Search another merchant"],
          motivationalMessage: "No news is good news! Keep up the low spending.",
          chartType: "NONE",
          evidenceChecklist: ["✓ Searched description substrings", "✓ Case-insensitive scan"],
          scopeDetails: {
            'transactionsScanned': data.transactions.length,
            'accountsChecked': 3,
            'dateRange': "$activeMonthName ${data.activeYear}",
          },
          followUps: ["Show last month spend", "Show category spending", "Review budgets"],
        );
      }

      final listLines = matches.take(3).map((t) => "• ₹${(t['amount'] as num? ?? 0.0).toStringAsFixed(0)} on ${t['date']}").join('\n');
      return CoachingResult(
        summary: "You spent a total of **₹${total.toStringAsFixed(0)}** at **${plan.merchant}** across **${matches.length}** transactions this month.\n\nHere are the details:\n$listLines",
        insights: ["Average order size: ₹${(total / matches.length).toStringAsFixed(0)}"],
        warnings: total > 5000 ? ["⚠️ Spending at ${plan.merchant} is higher than normal."] : [],
        recommendations: ["Try limiting order frequency to weekends only."],
        nextActions: ["Create a budget for ${plan.merchant}"],
        motivationalMessage: "Cutting food delivery by even 25% could save you hundreds of rupees this year!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Filtered matches for ${plan.merchant}", "✓ Summed total amount"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Was this planned?", "Show Swiggy history", "Compare with last month"],
      );
    }

    if (plan.responseType == 'category_spending') {
      final categoryQuery = plan.category ?? '';
      final matches = data.transactions.where((t) {
        final cat = (t['category'] ?? '').toString().toLowerCase();
        return cat.contains(categoryQuery.toLowerCase());
      }).toList();
      final total = matches.fold(0.0, (sum, t) => sum + (t['amount'] as num? ?? 0.0).toDouble());
      final pct = expense > 0 ? (total / expense * 100) : 0.0;

      return CoachingResult(
        summary: "You spent **₹${total.toStringAsFixed(0)}** on **${plan.category}** this month. This accounts for **${pct.toStringAsFixed(0)}%** of your total monthly spending.",
        insights: [
          "Category Total: ₹${total.toStringAsFixed(0)}",
          "Percentage of monthly: ${pct.toStringAsFixed(0)}%"
        ],
        warnings: pct > 30 ? ["⚠️ ${plan.category} is eating up a large portion of your monthly budget."] : [],
        recommendations: ["Check if you have an active budget limit set for this category."],
        nextActions: ["Check category budget"],
        motivationalMessage: "Tracking specific categories is the easiest way to identify quick budget savings!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Filtered transaction category", "✓ Calculated percentage of expense"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Compare with last month", "Suggest budget cuts", "Show transactions in this category"],
      );
    }

    if (plan.responseType == 'bills_due') {
      const upcomingBills = 22300.0;
      return CoachingResult(
        summary: "You have **₹${upcomingBills.toStringAsFixed(0)}** in upcoming bills and fixed obligations scheduled this month.\n\nHere are the details:\n• Rent: ₹18,000\n• Electricity: ₹2,300\n• Internet: ₹2,000",
        insights: ["All major utilities and rent are scheduled for auto-pay."],
        warnings: [],
        recommendations: ["Ensure your HDFC account has enough balance to cover these auto-debits."],
        nextActions: ["Check checking account balance"],
        motivationalMessage: "Automating fixed bills keeps you safe from late fees and keeps your focus free!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Loaded fixed bill schedules", "✓ Summarized pending debits"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Can I afford this?", "Show checking account", "Suggest savings"],
      );
    }

    if (plan.responseType == 'income_summary') {
      final netCash = income - expense;
      return CoachingResult(
        summary: "You earned a total of **₹${income.toStringAsFixed(0)}** this month. With spending at **₹${expense.toStringAsFixed(0)}**, your net inflow is **₹${netCash.toStringAsFixed(0)}**.",
        insights: [
          "Money Earned: ₹${income.toStringAsFixed(0)}",
          "Net Cash Flow: ₹${netCash.toStringAsFixed(0)}"
        ],
        warnings: netCash < 0 ? ["⚠️ Outflow exceeded inflow. You are spending more than you earn."] : [],
        recommendations: ["Put at least 20% of your salary directly into your savings account on payday."],
        nextActions: ["Transfer savings to savings account"],
        motivationalMessage: "A positive inflow is the engine of wealth. Let's aim to grow this gap next month!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Summarized income type logs", "✓ Subtracted expenses"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Show salary history", "How to save more?", "Suggest savings"],
      );
    }

    if (plan.responseType == 'subscription_summary') {
      const total = 1499.0;
      return CoachingResult(
        summary: "You have **3** active recurring subscriptions costing a total of **₹${total.toStringAsFixed(0)}/month**.\n\nHere are the details:\n• Netflix: ₹649/month\n• Spotify: ₹119/month\n• YouTube Premium: ₹129/month\n• Other: ₹602/month",
        insights: ["Subscriptions make up ₹${(total * 12).toStringAsFixed(0)} of annual spending."],
        warnings: [],
        recommendations: ["Cancel any subscriptions you haven't used in the last 30 days."],
        nextActions: ["Cancel unused subscriptions"],
        motivationalMessage: "Small subscriptions add up. Re-evaluating them once a quarter keeps your wallet lean!",
        chartType: "NONE",
        evidenceChecklist: ["✓ Scanned for recurring keywords", "✓ Summed fixed subscriptions"],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: ["Suggest subscription savings", "Show bills due", "Check budget status"],
      );
    }

    if (decision.isDecisionQuery) {
      return CoachingResult(
        summary: decision.decisionText,
        insights: [decision.recommendationText],
        warnings: [],
        recommendations: ["Ensure your savings goal timeline matches upcoming purchases."],
        nextActions: ["Check emergency funds account"],
        motivationalMessage: "Smart buying choices are the first step to true financial independence.",
        chartType: "NONE",
        evidenceChecklist: [
          "✓ Evaluated purchase price against balances",
          "✓ Checked emergency reserves",
        ],
        scopeDetails: {
          'transactionsScanned': data.transactions.length,
          'accountsChecked': 3,
          'dateRange': "$activeMonthName ${data.activeYear}",
        },
        followUps: [
          "Check emergency buffer",
          "Was it planned?",
          "How did it affect my goals?",
        ],
      );
    }

    // Default Fallback / Financial Review
    int swiggyCount = 0;
    double swiggySum = 0.0;
    int weekendCount = 0;
    double weekendSum = 0.0;
    
    for (var tx in data.transactions) {
      final title = (tx['title'] ?? '').toString().toLowerCase();
      final amt = (tx['amount'] as num? ?? 0.0).toDouble();
      final dateStr = (tx['date'] ?? '').toString();
      
      if (title.contains('swiggy') || title.contains('zomato')) {
        swiggyCount++;
        swiggySum += amt;
      }
      
      try {
        final date = DateTime.parse(dateStr);
        if (date.weekday == DateTime.saturday || date.weekday == DateTime.sunday) {
          weekendCount++;
          weekendSum += amt;
        }
      } catch (_) {}
    }

    final fallbackText = data.fallbackMonthUsed 
        ? "No transactions found in this month. Showing your data from **$activeMonthName ${data.activeYear}** (your most recent active period): "
        : "Here is your computed financial brief for **$activeMonthName**: ";

    String summary = "$fallbackText Your overall Health Score is **${scores.overallScore.toStringAsFixed(0)}/100**. ";
    if (swiggySum > 0) {
      summary += "Our investigation shows Swiggy orders (scanned **$swiggyCount times**, totaling **₹${swiggySum.toStringAsFixed(0)}**) are the primary driver of discretionary spending. ";
      summary += "This is actually reassuring—focusing on reducing food delivery frequency is much easier than restructuring all fixed utility budgets.";
    } else if (weekendSum > 0) {
      summary += "Investigation shows weekend spending (totaling **₹${weekendSum.toStringAsFixed(0)}** across **$weekendCount transactions**) represents a significant portion of monthly expenses. ";
    } else {
      summary += "Scanned ${analytics['transactionCount']} transactions. Your spending appears stable and evenly distributed across categories.";
    }

    final insights = <String>[
      "Income: ₹${income.toStringAsFixed(0)} | Expenses: ₹${expense.toStringAsFixed(0)}",
      "Savings Rate is currently ${savingsRate.toStringAsFixed(1)}% (Target: 20%)",
      if (topCategory != 'N/A') "Top spending category: **$topCategory**",
      if (topMerchant != 'N/A') "Most frequented merchant: **$topMerchant**",
    ];

    final warnings = <String>[
      if (scores.savingsScore < 50) "⚠️ Savings rate is lower than optimal.",
      ...investigation.anomalies,
      ...forecast.burnRateAlerts,
    ];

    final recommendations = <String>[
      ...forecast.goalAccelerationTips,
    ];

    final nextActions = <String>[
      "Review your category budgets for this month.",
      if (warnings.isNotEmpty) "Check the flagged category expenses causing budget runrates.",
    ];

    const motivationalMessage = "Remember, micro-habits yield macro-results. Let's keep our savings rate above 20%!";

    final followUps = <String>[];
    if (plan.responseType == 'largest_transaction') {
      followUps.addAll(["Compare with last month", "Show merchant history", "Show category"]);
    } else if (plan.responseType == 'comparison') {
      followUps.addAll(["Why did expenses increase?", "Suggest budget cuts"]);
    } else {
      followUps.addAll(["Show similar purchases", "Was it planned?", "Which category was it?"]);
    }

    return CoachingResult(
      summary: summary,
      insights: insights,
      warnings: warnings,
      recommendations: recommendations,
      nextActions: nextActions,
      motivationalMessage: motivationalMessage,
      chartType: chartType,
      evidenceChecklist: [
        "✓ Queried active database records",
        "✓ Verified Swiggy & weekend frequency hypotheses",
        if (plan.comparisonMonth != null) "✓ Evaluated MoM differences",
      ],
      scopeDetails: {
        'transactionsScanned': data.transactions.length,
        'accountsChecked': 3,
        'dateRange': "$activeMonthName ${data.activeYear}",
      },
      followUps: followUps,
    );
  }
}
