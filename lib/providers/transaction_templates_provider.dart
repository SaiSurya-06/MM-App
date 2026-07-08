import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/database.dart';
import '../models/transaction_template.dart';

class TransactionTemplatesState {
  final List<TransactionTemplate> templates;
  final bool isLoading;
  final String? errorMessage;

  TransactionTemplatesState({
    required this.templates,
    this.isLoading = false,
    this.errorMessage,
  });

  TransactionTemplatesState copyWith({
    List<TransactionTemplate>? templates,
    bool? isLoading,
    String? errorMessage,
  }) {
    return TransactionTemplatesState(
      templates: templates ?? this.templates,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class TransactionTemplatesNotifier extends StateNotifier<TransactionTemplatesState> {
  TransactionTemplatesNotifier() : super(TransactionTemplatesState(templates: [], isLoading: true)) {
    loadTemplates();
  }

  Future<void> loadTemplates() async {
    try {
      state = state.copyWith(isLoading: true);
      final db = await AppDatabase.instance.database;
      final List<Map<String, dynamic>> maps = await db.query('transaction_template');
      final templates = maps.map((m) => TransactionTemplate.fromMap(m)).toList();
      state = TransactionTemplatesState(templates: templates, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load templates: $e');
    }
  }

  Future<bool> addTemplate({
    required String title,
    required double amount,
    required String type,
    required int categoryId,
    required int accountId,
  }) async {
    try {
      final db = await AppDatabase.instance.database;
      final template = TransactionTemplate(
        title: title,
        amount: amount,
        type: type,
        categoryId: categoryId,
        accountId: accountId,
      );
      await db.insert('transaction_template', template.toMap());
      await loadTemplates();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add template: $e');
      return false;
    }
  }

  Future<bool> deleteTemplate(int id) async {
    try {
      final db = await AppDatabase.instance.database;
      await db.delete(
        'transaction_template',
        where: 'id = ?',
        whereArgs: [id],
      );
      await loadTemplates();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete template: $e');
      return false;
    }
  }
}

final transactionTemplatesProvider = StateNotifierProvider<TransactionTemplatesNotifier, TransactionTemplatesState>((ref) {
  return TransactionTemplatesNotifier();
});
