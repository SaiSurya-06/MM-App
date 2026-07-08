import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/material.dart';
import '../../models/transaction.dart';
import 'currency_formatter.dart';

class ExportHelper {
  static Future<void> exportBudgetReport({
    required String dateRangeStr,
    required List<Map<String, dynamic>> budgetRows,
    required String currency,
    String themeName = 'classic',
  }) async {
    final pdf = pw.Document();

    PdfColor primaryColor;
    PdfColor cardBg;
    switch (themeName.toLowerCase()) {
      case 'modern_blue':
        primaryColor = PdfColors.indigo900;
        cardBg = PdfColors.indigo50;
        break;
      case 'minimalist':
        primaryColor = PdfColors.grey900;
        cardBg = PdfColors.grey100;
        break;
      case 'premium_gold':
        primaryColor = PdfColors.orange900;
        cardBg = PdfColors.orange50;
        break;
      case 'classic':
      default:
        primaryColor = PdfColors.red900;
        cardBg = PdfColors.grey50;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('MONEY MANAGER', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                    pw.Text('Budget Report - ${themeName.toUpperCase()} STYLE', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text('Period: $dateRangeStr', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text('Generated: ${DateTime.now().toIso8601String().substring(0, 10)}', style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Divider(thickness: 1, color: primaryColor),
            pw.SizedBox(height: 16),
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
              columnWidths: const {
                0: pw.FlexColumnWidth(3),
                1: pw.FlexColumnWidth(2),
                2: pw.FlexColumnWidth(2),
                3: pw.FlexColumnWidth(2),
                4: pw.FlexColumnWidth(1.5),
              },
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: ['CATEGORY', 'LIMIT', 'SPENT', 'REMAINING', 'GROUP'].map((h) =>
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)))
                  ).toList(),
                ),
                ...budgetRows.map((row) => pw.TableRow(
                  children: [
                    row['category'] ?? '',
                    row['limit'] ?? '',
                    row['spent'] ?? '',
                    row['remaining'] ?? '',
                    row['group'] ?? '',
                  ].map((val) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(val.toString(), style: const pw.TextStyle(fontSize: 8)),
                  )).toList(),
                )),
              ],
            ),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/money_manager_budget_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Budget Report ($dateRangeStr)',
    );
  }

  static Future<void> exportAccountReport({
    required List<Map<String, dynamic>> accounts,
    required String currency,
    required String dateRangeStr,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            pw.Text('ACCOUNT COMPARISON REPORT', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
            pw.Text('Period: $dateRangeStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            pw.Divider(color: PdfColors.red900),
            pw.SizedBox(height: 12),
            pw.Table(
              border: const pw.TableBorder(
                bottom: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
              ),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: ['ACCOUNT', 'TYPE', 'BALANCE', 'INCOME', 'EXPENSES', 'NET'].map((h) =>
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(h, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)))
                  ).toList(),
                ),
                ...accounts.map((a) => pw.TableRow(
                  children: [
                    a['name'] ?? '',
                    a['type'] ?? '',
                    a['balance'] ?? '',
                    a['income'] ?? '',
                    a['expenses'] ?? '',
                    a['net'] ?? '',
                  ].map((val) => pw.Padding(
                    padding: const pw.EdgeInsets.all(6),
                    child: pw.Text(val.toString(), style: const pw.TextStyle(fontSize: 8)),
                  )).toList(),
                )),
              ],
            ),
          ];
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/money_manager_account_report.pdf');
    await file.writeAsBytes(await pdf.save());
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/pdf')],
      subject: 'Account Report ($dateRangeStr)',
    );
  }
}
