import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/database/daos/category_dao.dart';
import '../core/database/database.dart';
import '../models/category.dart';
import 'transactions_provider.dart';

class CategoriesState {
  final List<Category> categories;
  final bool isLoading;
  final String? errorMessage;

  CategoriesState({
    required this.categories,
    this.isLoading = false,
    this.errorMessage,
  });

  CategoriesState copyWith({
    List<Category>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoriesState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class CategoriesNotifier extends StateNotifier<CategoriesState> {
  final CategoryDao _categoryDao = CategoryDao();
  final Ref _ref;

  CategoriesNotifier(this._ref) : super(CategoriesState(categories: [], isLoading: true)) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      state = state.copyWith(isLoading: true);
      final list = await _categoryDao.getAllCategories();
      state = CategoriesState(categories: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to load categories: $e');
    }
  }

  Future<int?> addCategory(Category category) async {
    try {
      final id = await _categoryDao.insertCategory(category);
      await loadCategories();
      return id;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to add category: $e');
      return null;
    }
  }

  Future<bool> updateCategory(Category category) async {
    try {
      await _categoryDao.updateCategory(category);
      await loadCategories();
      return true;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to update category: $e');
      return false;
    }
  }

  Future<bool> deleteCategory(int id) async {
    try {
      final remaining = state.categories.where((c) => c.id != id).toList();
      if (remaining.isEmpty) {
        state = state.copyWith(errorMessage: 'Cannot delete the only remaining category.');
        return false;
      }
      final fallbackId = remaining.first.id!;
      
      final db = await AppDatabase.instance.database;
      // Reassign transactions to fallback
      await db.update('transaction_log', {'category_id': fallbackId}, where: 'category_id = ?', whereArgs: [id]);
      // Reassign budgets to fallback
      await db.update('budget', {'category_id': fallbackId}, where: 'category_id = ?', whereArgs: [id]);

      final rowsDeleted = await _categoryDao.deleteCategory(id);
      if (rowsDeleted > 0) {
        await loadCategories();
        // Refresh transaction list since category mapping has changed
        _ref.read(transactionsProvider.notifier).loadTransactions();
        return true;
      }
      state = state.copyWith(errorMessage: 'Failed to delete category.');
      return false;
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to delete category: $e');
      return false;
    }
  }
}

final categoriesProvider = StateNotifierProvider<CategoriesNotifier, CategoriesState>((ref) {
  return CategoriesNotifier(ref);
});
