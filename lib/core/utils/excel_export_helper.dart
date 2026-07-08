import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../models/transaction.dart';

class ExcelExportHelper {
  static Future<void> exportTransactionsToExcel({
    required List<Transaction> transactions,
    required Map<int, String> categoryNames,
    required Map<int, String> accountNames,
    required String currency,
    required String dateRangeStr,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Transactions'];
    excel.delete('Sheet1'); // Delete default sheet

    // Header cells style
    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    // Headers row
    final headers = ['Date', 'Title', 'Amount', 'Type', 'Category', 'Account', 'Note', 'Recurrence', 'Tags', 'Is Private'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    // Data rows
    for (int rowIdx = 0; rowIdx < transactions.length; rowIdx++) {
      final tx = transactions[rowIdx];
      final category = categoryNames[tx.categoryId] ?? 'Other';
      final account = accountNames[tx.accountId] ?? 'Account';
      final privateStr = tx.isPrivate ? 'Yes' : 'No';

      final List<CellValue> values = [
        TextCellValue(tx.date.toIso8601String().substring(0, 10)),
        TextCellValue(tx.title),
        DoubleCellValue(tx.amount),
        TextCellValue(tx.type),
        TextCellValue(category),
        TextCellValue(account),
        TextCellValue(tx.note ?? ''),
        TextCellValue(tx.recurrence),
        TextCellValue(tx.tags),
        TextCellValue(privateStr),
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx + 1));
        cell.value = values[col];
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/money_manager_transactions.xlsx');
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Transactions Export ($dateRangeStr)',
      );
    }
  }

  static Future<void> exportBudgetsToExcel({
    required Map<String, dynamic> budgetData,
    required String currency,
    required String dateRangeStr,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Budgets'];
    excel.delete('Sheet1');

    final CellStyle headerStyle = CellStyle(
      bold: true,
      fontSize: 11,
      fontFamily: getFontFamily(FontFamily.Calibri),
    );

    final headers = ['Category', 'Limit', 'Spent', 'Remaining', 'Group', 'Period'];
    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.value = TextCellValue(headers[col]);
      cell.cellStyle = headerStyle;
    }

    final List<dynamic> rows = budgetData['rows'] ?? [];
    for (int rowIdx = 0; rowIdx < rows.length; rowIdx++) {
      final row = rows[rowIdx] as Map;
      final List<CellValue> values = [
        TextCellValue(row['category']?.toString() ?? ''),
        TextCellValue(row['limit']?.toString() ?? ''),
        TextCellValue(row['spent']?.toString() ?? ''),
        TextCellValue(row['remaining']?.toString() ?? ''),
        TextCellValue(row['group']?.toString() ?? ''),
        TextCellValue(row['period']?.toString() ?? ''),
      ];

      for (int col = 0; col < values.length; col++) {
        final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: rowIdx + 1));
        cell.value = values[col];
      }
    }

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/money_manager_budgets.xlsx');
    
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')],
        subject: 'Budgets Export ($dateRangeStr)',
      );
    }
  }
}
