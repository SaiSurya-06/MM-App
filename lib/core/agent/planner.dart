import 'dart:convert';
import 'agent_service.dart';
import 'execution_plan.dart';

abstract class Planner {
  Future<ExecutionPlan> plan(String query, ConversationMemory memory);
}

class GeminiPlanner implements Planner {
  @override
  Future<ExecutionPlan> plan(String query, ConversationMemory memory) async {
    final plannerPrompt = '''
You are the Planner AI for a Financial Assistant.
Your only job is to analyze the user's natural language question and current conversation memory, and generate a structured JSON Execution Plan conforming to the schema.

Execution Plan Schema:
{
  "intent": "search" | "compare" | "balance" | "budget" | "advice" | "forecast",
  "responseType": "largest_transaction" | "comparison" | "budget_status" | "goal_progress" | "affordability" | "financial_review",
  "merchant": String (null if not specifying a merchant name like Swiggy, Zomato, Amazon, Netflix, etc.),
  "category": String (null if not specifying a category like Food, Rent, Salary, Transport, Entertainment, Utilities, etc.),
  "minAmount": double (null if not specifying a minimum transaction value),
  "maxAmount": double (null if not specifying a maximum transaction value),
  "targetMonth": int (1 to 12. Defaults to current month if not specified),
  "targetYear": int (e.g. 2026. Defaults to current year if not specified),
  "comparisonMonth": int (1 to 12. Set if user is comparing target month to another month),
  "comparisonYear": int (e.g. 2026. Set if user is comparing),
  "paymentMethod": "upi" | "cash" | "card" | null,
  "timeFilter": "weekend" | "night" | "evening" | null,
  "requiredTools": ["transaction", "budget", "goal", "account", "subscription"],
  "requiredStrategies": ["comparison", "anomaly", "trend", "root_cause"],
  "needsForecast": bool,
  "needsDecision": bool,
  "needsCoaching": bool,
  "confidence": double
}

Current Conversation Memory (Previous active plan):
${memory.lastPlan == null ? 'No previous context' : jsonEncode(memory.lastPlan!.toJson())}

User Question: "$query"

Instructions:
1. Ensure the output is strictly valid JSON conforming to the schema above.
2. Return ONLY the JSON object. Do not include markdown wraps (like ```json), commentary, or extra text.
3. Be precise with dates. Today is July 10, 2026.
''';

    final rawResponse = await AgentService.sendMessage(plannerPrompt);
    final cleanedJson = rawResponse.replaceAll(RegExp(r'```(json)?'), '').trim();
    final decoded = jsonDecode(cleanedJson) as Map<String, dynamic>;
    return ExecutionPlan.fromJson(decoded);
  }
}

class RulePlanner implements Planner {
  @override
  Future<ExecutionPlan> plan(String query, ConversationMemory memory) async {
    final clean = query.toLowerCase();

    // Context Parsing logic
    final now = DateTime.now();
    int? targetMonth;
    int? targetYear;
    int? comparisonMonth;
    int? comparisonYear;
    double? minAmount;
    double? maxAmount;
    String? category;
    String? merchant;
    String? paymentMethod;
    String? targetType;

    final monthsMap = {
      'january': 1, 'jan': 1,
      'february': 2, 'feb': 2,
      'march': 3, 'mar': 3,
      'april': 4, 'apr': 4,
      'may': 5,
      'june': 6, 'jun': 6,
      'july': 7, 'jul': 7,
      'august': 8, 'aug': 8,
      'september': 9, 'sep': 9,
      'october': 10, 'oct': 10,
      'november': 11, 'nov': 11,
      'december': 12, 'dec': 12,
    };

    for (var entry in monthsMap.entries) {
      if (clean.contains(entry.key)) {
        if (clean.contains("compare") || clean.contains("vs")) {
          if (targetMonth != null) {
            comparisonMonth = entry.value;
            comparisonYear = now.year;
          } else {
            targetMonth = entry.value;
            targetYear = now.year;
          }
        } else {
          targetMonth = entry.value;
          targetYear = now.year;
        }
      }
    }

    if (clean.contains("this month")) {
      targetMonth = now.month;
      targetYear = now.year;
    } else if (clean.contains("last month")) {
      final prev = DateTime(now.year, now.month - 1);
      targetMonth = prev.month;
      targetYear = prev.year;
    }

    if (targetMonth == null && targetYear == null) {
      targetMonth = now.month;
      targetYear = now.year;
    }

    if (clean.contains("compare") || clean.contains("vs")) {
      if (comparisonMonth == null && targetMonth != null) {
        final compDate = DateTime(targetYear ?? now.year, targetMonth - 1);
        comparisonMonth = compDate.month;
        comparisonYear = compDate.year;
      }
    }

    final amountReg = RegExp(
        r'(above|below|more than|less than|greater than|over|under|>|<|>=|<=)\s*(?:rs\.?|rs|rupees|inr|₹)?\s*(\d+)');
    final match = amountReg.firstMatch(clean);
    if (match != null) {
      final op = match.group(1)!;
      final val = double.tryParse(match.group(2)!) ?? 0.0;
      if (op.contains("above") || op.contains("more") || op.contains("greater") || op.contains("over") || op.contains(">")) {
        minAmount = val;
      } else {
        maxAmount = val;
      }
    }

    if (clean.contains("spend") || clean.contains("spent") || clean.contains("expense") || clean.contains("paid")) {
      targetType = 'expense';
    } else if (clean.contains("got") || clean.contains("received") || clean.contains("income") || clean.contains("salary")) {
      targetType = 'income';
    }

    if (clean.contains("upi")) {
      paymentMethod = 'upi';
    } else if (clean.contains("cash")) {
      paymentMethod = 'cash';
    } else if (clean.contains("card")) {
      paymentMethod = 'card';
    }

    final semanticSynonyms = {
      'Transport': ['goa', 'vacation', 'holiday', 'trip', 'fuel', 'flight', 'hotel', 'train', 'bus', 'uber', 'ola', 'travel', 'transport'],
      'Food': ['coffee', 'cafe', 'latte', 'starbucks', 'ccd', 'barista', 'swiggy', 'zomato', 'pizza', 'kfc', 'mcdonalds', 'burger', 'dining', 'restaurant', 'food', 'delivery'],
      'Utilities': ['electricity', 'water', 'gas', 'power', 'internet', 'wifi', 'recharge', 'bill', 'utilities'],
      'Entertainment': ['netflix', 'spotify', 'movie', 'cinema', 'youtube', 'prime', 'game', 'playstation', 'entertainment']
    };

    String? matchedCategory;
    for (var entry in semanticSynonyms.entries) {
      for (var syn in entry.value) {
        if (clean.contains(syn)) {
          matchedCategory = entry.key;
          break;
        }
      }
      if (matchedCategory != null) break;
    }

    if (matchedCategory != null) {
      category = matchedCategory;
    } else {
      final words = clean.split(RegExp(r'\s+'));
      final stopWords = {
        'how', 'much', 'did', 'i', 'get', 'got', 'in', 'the', 'month', 'of', 'on', 'at',
        'for', 'show', 'list', 'my', 'me', 'what', 'was', 'were', 'spend', 'spent',
        'salary', 'income', 'expense', 'expenses', 'balance', 'balances', 'account', 'accounts',
        'this', 'last', 'interest', 'money', 'transaction', 'transactions', 'to', 'from',
        'where', 'which', 'who', 'why', 'when', 'most', 'highest', 'least', 'lowest', 'total',
        'sum', 'all', 'any', 'average', 'avg', 'many', 'more', 'less', 'category', 'catagoy',
        'catagory', 'recent', 'save', 'saving', 'savings', 'tip', 'tips', 'blueprint',
        'only', 'compare', 'vs', 'comparison', 'above', 'below', 'waste', 'wasted',
        ...monthsMap.keys
      };

      final candidates = words.where((w) => !stopWords.contains(w) && w.length > 2).toList();
      if (candidates.isNotEmpty) {
        final name = candidates.first;
        final knownCategories = ['food', 'rent', 'salary', 'transport', 'entertainment', 'health', 'utilities', 'credit card payment', 'other'];
        if (knownCategories.contains(name)) {
          category = name;
        } else {
          merchant = name;
        }
      }
    }

    String intent = 'search';
    String responseType = 'financial_review';

    if (clean.contains("compare") || clean.contains("vs")) {
      intent = 'compare';
      responseType = 'comparison';
    } else if (clean.contains("balance") || clean.contains("net worth") || clean.contains("my money") || clean.contains("account balances")) {
      intent = 'balance';
      responseType = 'financial_review'; // Net worth is handled in standard brief
    } else if (clean.contains("budget")) {
      intent = 'budget';
      responseType = 'budget_status';
    } else if (clean.contains("goal") || clean.contains("save") || clean.contains("saving") || clean.contains("how to save")) {
      intent = 'budget';
      responseType = 'goal_progress';
    } else if (clean.contains("afford") || clean.contains("buy")) {
      intent = 'decision';
      responseType = 'affordability';
    } else if (clean.contains("big") || clean.contains("large") || clean.contains("max") || clean.contains("highest") || clean.contains("most expensive")) {
      intent = 'search';
      responseType = 'largest_transaction';
    }

    return ExecutionPlan(
      intent: intent,
      responseType: responseType,
      merchant: merchant,
      category: category,
      minAmount: minAmount,
      maxAmount: maxAmount,
      targetMonth: targetMonth,
      targetYear: targetYear,
      comparisonMonth: comparisonMonth,
      comparisonYear: comparisonYear,
      paymentMethod: paymentMethod,
      timeFilter: clean.contains("weekend") ? "weekend" : (clean.contains("night") ? "night" : null),
      targetType: targetType,
      requiredTools: ['transaction', 'budget', 'goal', 'account', 'subscription'],
      requiredStrategies: ['comparison', 'anomaly'],
      needsForecast: true,
      needsDecision: intent == 'decision',
      needsCoaching: true,
      confidence: 1.0,
    );
  }
}
