import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/diagnostic_profile.dart';
import '../../models/diagnostic_report.dart';
import '../analytics/financial_engine.dart';

class DiagnosticPdfService {
  static Future<void> printReport(
    DiagnosticProfile profile,
    DiagnosticReport report,
    String currencyCode,
  ) async {
    final pdf = pw.Document();

    final brandRed = PdfColor.fromHex('#E53935');
    final darkGrey = PdfColor.fromHex('#212121');
    final lightGrey = PdfColor.fromHex('#F5F5F5');
    
    // Load logo if possible
    pw.MemoryImage? logoImage;
    try {
      final logoData = await rootBundle.load('assets/logo.png');
      logoImage = pw.MemoryImage(logoData.buffer.asUint8List());
    } catch (_) {
      // Fallback if logo not found
    }

    String formatAmount(double val) {
      return '$currencyCode ${val.toStringAsFixed(2)}';
    }

    PdfColor getVerdictColor(DiagnosticVerdict verdict) {
      switch (verdict) {
        case DiagnosticVerdict.excellent:
          return PdfColors.green900;
        case DiagnosticVerdict.good:
          return PdfColors.amber900;
        case DiagnosticVerdict.needsAttention:
          return PdfColors.orange900;
        case DiagnosticVerdict.critical:
          return PdfColors.red900;
      }
    }

    PdfColor getVerdictBgColor(DiagnosticVerdict verdict) {
      switch (verdict) {
        case DiagnosticVerdict.excellent:
          return PdfColor.fromHex('#E8F5E9');
        case DiagnosticVerdict.good:
          return PdfColor.fromHex('#FFF8E1');
        case DiagnosticVerdict.needsAttention:
          return PdfColor.fromHex('#FFF3E0');
        case DiagnosticVerdict.critical:
          return PdfColor.fromHex('#FFEBEE');
      }
    }

    String getVerdictLabel(DiagnosticVerdict verdict) {
      switch (verdict) {
        case DiagnosticVerdict.excellent:
          return 'Excellent Health';
        case DiagnosticVerdict.good:
          return 'Good Health';
        case DiagnosticVerdict.needsAttention:
          return 'Needs Attention';
        case DiagnosticVerdict.critical:
          return 'Critical / Financial Distress';
      }
    }

    // --- Page 1: Cover Page ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(40),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    if (logoImage != null)
                      pw.Container(
                        height: 50,
                        width: 50,
                        child: pw.Image(logoImage),
                      )
                    else
                      pw.Text(
                        'MM',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                          color: brandRed,
                        ),
                      ),
                    pw.Text(
                      'MONEY MANAGER',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGrey,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      height: 5,
                      width: 80,
                      color: brandRed,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Text(
                      'PERSONAL FINANCIAL\nDIAGNOSTIC REPORT',
                      style: pw.TextStyle(
                        fontSize: 28,
                        fontWeight: pw.FontWeight.bold,
                        color: darkGrey,
                      ),
                    ),
                    pw.SizedBox(height: 12),
                    pw.Text(
                      'A comprehensive review of cash flows, debt repayment, coverage gaps, and milestones.',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.all(20),
                  decoration: pw.BoxDecoration(
                    color: lightGrey,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('PREPARED FOR:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          pw.Text('DATE GENERATED:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            profile.you.name.toUpperCase(),
                            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkGrey),
                          ),
                          pw.Text(
                            report.generatedAt.toIso8601String().substring(0, 10),
                            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 16),
                      pw.Container(height: 1, color: PdfColors.grey300),
                      pw.SizedBox(height: 12),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('FINANCIAL HEALTH VERDICT:', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: pw.BoxDecoration(
                              color: getVerdictBgColor(report.verdict),
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                            ),
                            child: pw.Text(
                              getVerdictLabel(report.verdict).toUpperCase(),
                              style: pw.TextStyle(
                                fontSize: 10,
                                fontWeight: pw.FontWeight.bold,
                                color: getVerdictColor(report.verdict),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // --- Page 2: Executive Summary ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final topActions = report.checklist.take(3).toList();
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('EXECUTIVE SUMMARY', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandRed)),
                pw.Divider(color: brandRed, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(color: lightGrey, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('NET WORTH', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 4),
                            pw.Text(formatAmount(report.netWorth), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: report.netWorth >= 0 ? PdfColors.green900 : PdfColors.red900)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(color: lightGrey, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('MONTHLY SURPLUS', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 4),
                            pw.Text(formatAmount(report.monthlySurplus), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: report.monthlySurplus >= 0 ? PdfColors.green900 : PdfColors.red900)),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(color: lightGrey, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('EMERGENCY BUFFER', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 4),
                            pw.Text('${report.emergencyFundTargetMonths} MONTHS', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Text('TOP PRIORITIES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                pw.SizedBox(height: 12),
                if (topActions.isEmpty)
                  pw.Text('No immediate actions required! Your financial diagnostics look solid.', style: const pw.TextStyle(fontSize: 10))
                else
                  pw.Column(
                    children: topActions.map((item) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        padding: const pw.EdgeInsets.all(12),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(left: pw.BorderSide(color: brandRed, width: 4)),
                          color: PdfColors.grey50,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  'PRIORITY ${item.priority}: ${item.title}',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGrey),
                                ),
                                if (item.monetaryTarget != null)
                                  pw.Text(
                                    'Target: ${formatAmount(item.monetaryTarget!)}',
                                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: brandRed),
                                  ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(item.description, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey800)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );

    // --- Page 3: Cash Flow Analysis ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CASH FLOW ANALYSIS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandRed)),
                pw.Divider(color: brandRed, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Visualizing your monthly cash outflow share. Balanced cash flow allocates a healthy chunk to savings/growth while minimizing debt.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 24),
                pw.Column(
                  children: report.cashFlowBreakdown.map((item) {
                    final color = item.category == 'Growth/Savings'
                        ? PdfColors.green800
                        : (item.category == 'Protection/Insurance'
                            ? PdfColors.blue800
                            : (item.category == 'Debt Payments' ? PdfColors.red800 : PdfColors.amber800));

                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 16),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(item.category, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                              pw.Text(
                                '${formatAmount(item.amount)} (${item.percentage.toStringAsFixed(1)}%)',
                                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGrey),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 6),
                          pw.Stack(
                            children: [
                              pw.Container(
                                height: 8,
                                width: double.infinity,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColors.grey200,
                                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                                ),
                              ),
                              pw.Container(
                                height: 8,
                                width: 480 * (item.percentage / 100).clamp(0.0, 1.0),
                                decoration: pw.BoxDecoration(
                                  color: color,
                                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                pw.SizedBox(height: 32),
                pw.Text('SURPLUS / DEFICIT BREAKDOWN', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                pw.SizedBox(height: 12),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  color: report.monthlySurplus >= 0 ? PdfColors.green50 : PdfColors.red50,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        report.monthlySurplus >= 0 ? 'Monthly Surplus Available to Invest' : 'Monthly Deficit (Overspending)',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: report.monthlySurplus >= 0 ? PdfColors.green900 : PdfColors.red900,
                        ),
                      ),
                      pw.Text(
                        formatAmount(report.monthlySurplus),
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: report.monthlySurplus >= 0 ? PdfColors.green900 : PdfColors.red900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    // --- Page 4: Debt Payoff Simulation ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final lCount = profile.loans.loans.length;
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('DEBT ANALYSIS & PAYOFF', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandRed)),
                pw.Divider(color: brandRed, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(color: lightGrey, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('TOTAL OUTSTANDING', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              formatAmount(profile.loans.loans.map((l) => l.outstandingPrincipal).fold(0.0, (a, b) => a + b)),
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 12),
                    pw.Expanded(
                      child: pw.Container(
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(color: lightGrey, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4))),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('MONTHLY EMI BLEND', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              formatAmount(profile.loans.loans.map((l) => l.monthlyEMI).fold(0.0, (a, b) => a + b)),
                              style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 24),
                pw.Text('AVALANCHE VS SNOWBALL COMPARISON', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                pw.SizedBox(height: 8),
                if (lCount == 0)
                  pw.Text('No outstanding loans. You are debt free!', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
                else ...[
                  pw.Table(
                    border: const pw.TableBorder(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                      horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('METHOD', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('MONTHS TO PAYOFF', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOTAL INTEREST PAID', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Avalanche (Highest Rate first)', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${report.debtPayoff.avalancheMonths} Months', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(report.debtPayoff.totalInterestAvalanche), style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Snowball (Smallest Balance first)', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${report.debtPayoff.snowballMonths} Months', style: const pw.TextStyle(fontSize: 9))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(report.debtPayoff.totalInterestSnowball), style: const pw.TextStyle(fontSize: 9))),
                        ],
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 24),
                  pw.Text('LOAN ENTRIES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: const pw.TableBorder(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                      horizontalInside: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('LABEL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('PRINCIPAL', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('RATE', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('EMI', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      ...profile.loans.loans.map((loan) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(loan.label, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(loan.outstandingPrincipal), style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${loan.annualInterestRate}%', style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(loan.monthlyEMI), style: const pw.TextStyle(fontSize: 8))),
                          ],
                        );
                      }),
                    ],
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );

    // --- Page 5: Protection Analysis ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final termGap = report.termCoverGap;
          final healthGap = report.healthCoverGap;
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('PROTECTION GAPS & INSURANCE', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandRed)),
                pw.Divider(color: brandRed, thickness: 1),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Adequate insurance is the foundation of any financial plan. Underinsurance can wipe out years of savings in seconds.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800),
                ),
                pw.SizedBox(height: 24),
                pw.Table(
                  border: const pw.TableBorder(
                    bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                    horizontalInside: pw.BorderSide(color: PdfColors.grey200, width: 0.5),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('INSURANCE TYPE', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('REQUIRED COVER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('CURRENT COVER', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('GAP', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Term Life Cover', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(FinancialEngine.requiredTermCover(profile)), style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            formatAmount(profile.lifeCover.personalTermCoverAmount +
                                profile.lifeCover.corporateGroupTermAmount +
                                profile.lifeCover.personalEndowmentCoverAmount),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            termGap > 0 ? formatAmount(termGap) : 'No Gap (Adequate)',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: termGap > 0 ? PdfColors.red900 : PdfColors.green900),
                          ),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Health Insurance', style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(FinancialEngine.requiredHealthCover(profile)), style: const pw.TextStyle(fontSize: 9))),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            formatAmount(profile.healthCover.personalHealthCoverAmount + profile.healthCover.corporateHealthCoverAmount),
                            style: const pw.TextStyle(fontSize: 9),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(6),
                          child: pw.Text(
                            healthGap > 0 ? formatAmount(healthGap) : 'No Gap (Adequate)',
                            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: healthGap > 0 ? PdfColors.red900 : PdfColors.green900),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 32),
                pw.Text('ADDITIONAL INSURANCE POLICIES', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                pw.SizedBox(height: 12),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Comprehensive Vehicle Cover:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      profile.otherInsurance.hasComprehensiveVehicleCover ? 'ACTIVE' : 'INACTIVE / MISSING',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: profile.otherInsurance.hasComprehensiveVehicleCover ? PdfColors.green900 : PdfColors.orange900),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Home Structure Insurance:', style: const pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      profile.otherInsurance.hasHomeStructureInsurance ? 'ACTIVE' : 'INACTIVE / MISSING',
                      style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: profile.otherInsurance.hasHomeStructureInsurance ? PdfColors.green900 : PdfColors.orange900),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    // --- Page 6: Goals & Projections ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final hasRetirement = profile.goals.targetRetirementAge != null;
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('GOALS & FUTURE PROJECTIONS', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandRed)),
                pw.Divider(color: brandRed, thickness: 1),
                pw.SizedBox(height: 20),
                if (hasRetirement) ...[
                  pw.Text('RETIREMENT CORPUS PROJECTION', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(color: lightGrey, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6))),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Projected retirement pool at age ${profile.goals.targetRetirementAge}:', style: const pw.TextStyle(fontSize: 10)),
                        pw.Text(
                          formatAmount(FinancialEngine.projectedRetirementCorpus(profile)),
                          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 24),
                ],
                pw.Text('LUMP SUM GOAL SHORTFALLS', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: darkGrey)),
                pw.SizedBox(height: 8),
                if (report.goalFunding.isEmpty)
                  pw.Text('No lump sum goals or child milestones set.', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700))
                else
                  pw.Table(
                    border: const pw.TableBorder(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
                      horizontalInside: pw.BorderSide(color: PdfColors.grey100, width: 0.5),
                    ),
                    children: [
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('GOAL NAME', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TARGET', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('YEARS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('PROJECTED SAVINGS', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('GAP', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                        ],
                      ),
                      ...report.goalFunding.map((goal) {
                        return pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(goal.name, style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(goal.targetAmount), style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${goal.yearsNeeded} yrs', style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(formatAmount(goal.projectedSavings), style: const pw.TextStyle(fontSize: 8))),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(6),
                              child: pw.Text(
                                goal.fundingGap > 0 ? formatAmount(goal.fundingGap) : 'Funded',
                                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: goal.fundingGap > 0 ? PdfColors.red900 : PdfColors.green900),
                              ),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );

    // --- Page 7: Action Checklist ---
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(32),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FULL PRIORITIZED ACTION CHECKLIST', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: brandRed)),
                pw.Divider(color: brandRed, thickness: 1),
                pw.SizedBox(height: 20),
                if (report.checklist.isEmpty)
                  pw.Text('No action items generated! Your finances are in pristine condition.', style: const pw.TextStyle(fontSize: 10))
                else
                  pw.Column(
                    children: report.checklist.map((item) {
                      final priorityColor = item.priority == 1
                          ? PdfColors.red800
                          : (item.priority == 2
                              ? PdfColors.orange
                              : (item.priority == 3 ? PdfColors.amber800 : PdfColors.green800));

                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 12),
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          border: pw.Border(left: pw.BorderSide(color: priorityColor, width: 4)),
                          color: PdfColors.grey50,
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Text(
                                  '${item.priority}. ${item.title}',
                                  style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: darkGrey),
                                ),
                                if (item.monetaryTarget != null)
                                  pw.Text(
                                    'Target: ${formatAmount(item.monetaryTarget!)}',
                                    style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: priorityColor),
                                  ),
                              ],
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              item.description,
                              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );

    // Print PDF
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Money_Manager_Diagnostic_Report_${profile.you.name}.pdf',
    );
  }
}
