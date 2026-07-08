import 'dart:math' as math;
import '../../models/transaction.dart';
import '../../models/category.dart';

class AiCategorizationHelper {
  /// Local Naive Bayes dynamic machine learning classifier to auto-assign a category to a transaction
  static int? classify(String title, double amount, List<Transaction> history, List<Category> categories) {
    final cleanTitle = title.trim().toLowerCase();
    if (cleanTitle.isEmpty) return null;

    // Direct Category Name Match first
    for (var cat in categories) {
      final catName = cat.name.toLowerCase();
      if (cleanTitle == catName || cleanTitle.contains(catName)) {
        return cat.id;
      }
    }

    final tokens = _tokenize(cleanTitle);
    if (tokens.isEmpty) return null;

    // Fallback if history is insufficient
    if (history.length < 5) {
      return _keywordMatch(cleanTitle, categories);
    }

    // Train Naive Bayes model on-the-fly
    final categoryCounts = <int, int>{};
    final wordCountsPerCategory = <int, Map<String, int>>{};
    final totalWordsPerCategory = <int, int>{};
    final vocabulary = <String>{};

    int totalTransactions = 0;

    for (var tx in history) {
      final txCatId = tx.categoryId;
      categoryCounts[txCatId] = (categoryCounts[txCatId] ?? 0) + 1;
      totalTransactions++;

      final txTokens = _tokenize(tx.title);
      wordCountsPerCategory.putIfAbsent(txCatId, () => {});
      final wordMap = wordCountsPerCategory[txCatId]!;

      for (var token in txTokens) {
        wordMap[token] = (wordMap[token] ?? 0) + 1;
        totalWordsPerCategory[txCatId] = (totalWordsPerCategory[txCatId] ?? 0) + 1;
        vocabulary.add(token);
      }
    }

    final vocabSize = vocabulary.length;
    int? bestCategoryId;
    double maxLogProb = -double.infinity;

    for (var cat in categories) {
      if (cat.id == null) continue;
      final catId = cat.id!;

      // Prior probability with Laplace smoothing
      final catCount = categoryCounts[catId] ?? 0;
      final prior = (catCount + 1) / (totalTransactions + categories.length);
      double logProb = math.log(prior);

      // Word likelihoods
      final wordMap = wordCountsPerCategory[catId] ?? {};
      final totalWords = totalWordsPerCategory[catId] ?? 0;

      for (var token in tokens) {
        final count = wordMap[token] ?? 0;
        final likelihood = (count + 1) / (totalWords + vocabSize + 1);
        logProb += math.log(likelihood);
      }

      if (logProb > maxLogProb) {
        maxLogProb = logProb;
        bestCategoryId = catId;
      }
    }

    // Return prediction if found
    if (bestCategoryId != null) {
      return bestCategoryId;
    }

    return _keywordMatch(cleanTitle, categories);
  }

  static List<String> _tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length >= 2)
        .toList();
  }

  static int? _keywordMatch(String lowerTitle, List<Category> categories) {
    final fallbackKeywords = {
      'uber': 'Transport',
      'lyft': 'Transport',
      'cab': 'Transport',
      'taxi': 'Transport',
      'bus': 'Transport',
      'metro': 'Transport',
      'train': 'Transport',
      
      'starbucks': 'Food',
      'mcdonald': 'Food',
      'burger': 'Food',
      'pizza': 'Food',
      'cafe': 'Food',
      'coffee': 'Food',
      'dine': 'Food',
      'restaur': 'Food',
      'grocery': 'Food',
      'supermarket': 'Food',
      
      'netflix': 'Entertainment',
      'spotify': 'Entertainment',
      'steam': 'Entertainment',
      'hulu': 'Entertainment',
      'cinema': 'Entertainment',
      'movie': 'Entertainment',
      
      'salary': 'Salary',
      'payroll': 'Salary',
      'bonus': 'Salary',
      
      'rent': 'Rent',
      'landlord': 'Rent',
      
      'electric': 'Utilities',
      'power': 'Utilities',
      'water': 'Utilities',
      'gas': 'Utilities',
      'telecom': 'Utilities',
      'internet': 'Utilities',
      
      'hospital': 'Health',
      'doctor': 'Health',
      'clinic': 'Health',
      'pharmacy': 'Health',
      'dentist': 'Health',
    };

    for (var entry in fallbackKeywords.entries) {
      if (lowerTitle.contains(entry.key)) {
        final matchedCat = categories.firstWhere(
          (c) => c.name.toLowerCase().contains(entry.value.toLowerCase()),
          orElse: () => categories.firstWhere((c) => c.name.toLowerCase() == 'other', orElse: () => categories.first),
        );
        return matchedCat.id;
      }
    }
    return null;
  }
}
