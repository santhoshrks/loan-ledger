import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';

class PdfExportService {
  static Future<void> exportLoansSummary({
    required BuildContext context,
    required List<Loan> loans,
  }) async {
    final pdf = pw.Document();
    final now = DateTime.now();
    final dateStr = DateFormat('MMMM d, yyyy').format(now);

    // Load bundled Roboto fonts — valid static TTF, supports ₹ and all symbols, works offline
    final regularData = await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldData = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final ttf = pw.Font.ttf(regularData);
    final ttfBold = pw.Font.ttf(boldData);

    // Colors
    const primary = PdfColor.fromInt(0xFF6366F1);
    const primaryLight = PdfColor.fromInt(0xFFEEF2FF);
    const success = PdfColor.fromInt(0xFF10B981);
    const warning = PdfColor.fromInt(0xFFF59E0B);
    const danger = PdfColor.fromInt(0xFFEF4444);
    const textDark = PdfColor.fromInt(0xFF111827);
    const textGrey = PdfColor.fromInt(0xFF6B7280);
    const bgGrey = PdfColor.fromInt(0xFFF9FAFB);
    const white = PdfColors.white;

    final totalEmi = loans.fold<double>(0, (s, l) => s + l.emiAmount);
    final paidLoans = loans.where((l) => l.isPaid).length;
    final overdueLoans = loans.where((l) => l.isOverdue()).length;
    final currencySymbol = loans.isNotEmpty ? loans.first.currencySymbol : '₹';
    // PDF-safe currency symbol — replace special unicode glyphs with ASCII equivalents
    final pdfCurrency = _pdfSafeCurrency(currencySymbol);

    String fmt(double v) {
      if (v >= 10000000) return '$pdfCurrency${(v / 10000000).toStringAsFixed(2)} Cr';
      if (v >= 100000) return '$pdfCurrency${(v / 100000).toStringAsFixed(2)} L';
      return '$pdfCurrency${NumberFormat('#,##,###').format(v)}';
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _buildHeader(dateStr, ttf, ttfBold),
        footer: (ctx) => _buildFooter(ctx, ttf),
        build: (ctx) => [
          pw.SizedBox(height: 20),
          _sectionTitle('Monthly Overview', primary, ttfBold),
          pw.SizedBox(height: 10),
          pw.Row(children: [
            _summaryCard('Total Monthly EMI', fmt(totalEmi), primary, primaryLight, ttf, ttfBold),
            pw.SizedBox(width: 10),
            _summaryCard('Total Loans', '${loans.length}', primary, primaryLight, ttf, ttfBold),
            pw.SizedBox(width: 10),
            _summaryCard('Paid This Month', '$paidLoans', success, const PdfColor.fromInt(0xFFECFDF5), ttf, ttfBold),
            pw.SizedBox(width: 10),
            _summaryCard('Overdue', '$overdueLoans', danger, const PdfColor.fromInt(0xFFFEF2F2), ttf, ttfBold),
          ]),

          pw.SizedBox(height: 24),
          _sectionTitle('Loan Details', primary, ttfBold),
          pw.SizedBox(height: 10),

          // Table header
          pw.Container(
            decoration: const pw.BoxDecoration(color: primary),
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: pw.Row(children: [
              pw.Expanded(flex: 3, child: pw.Text('Loan Name', style: pw.TextStyle(font: ttfBold, fontSize: 10, color: white))),
              pw.Expanded(flex: 2, child: pw.Text('EMI Amount', style: pw.TextStyle(font: ttfBold, fontSize: 10, color: white))),
              pw.Expanded(flex: 2, child: pw.Text('Due Date', style: pw.TextStyle(font: ttfBold, fontSize: 10, color: white))),
              pw.Expanded(flex: 2, child: pw.Text('Progress', style: pw.TextStyle(font: ttfBold, fontSize: 10, color: white))),
              pw.Expanded(flex: 2, child: pw.Text('Status', style: pw.TextStyle(font: ttfBold, fontSize: 10, color: white))),
            ]),
          ),

          // Table rows
          ...loans.asMap().entries.map((entry) {
            final i = entry.key;
            final loan = entry.value;
            final isEven = i % 2 == 0;
            final daysUntil = loan.daysUntilDue();
            final isOverdue = loan.isOverdue();

            PdfColor statusColor;
            String statusText;
            if (loan.isPaid) { statusColor = success; statusText = 'Paid'; }
            else if (isOverdue) { statusColor = danger; statusText = 'Overdue'; }
            else if (daysUntil <= 3) { statusColor = warning; statusText = 'Due Soon'; }
            else { statusColor = primary; statusText = 'Upcoming'; }

            final progress = (loan.tenureMonths != null && loan.tenureMonths! > 0)
                ? '${loan.emisPaidCount}/${loan.tenureMonths}'
                : '-';

            return pw.Container(
              color: isEven ? bgGrey : white,
              padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: pw.Row(children: [
                pw.Expanded(flex: 3, child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(loan.name, style: pw.TextStyle(font: ttfBold, fontSize: 10, color: textDark)),
                    if (loan.bankName != null)
                      pw.Text(loan.bankName!, style: pw.TextStyle(font: ttf, fontSize: 8, color: textGrey)),
                  ],
                )),
                pw.Expanded(flex: 2, child: pw.Text(fmt(loan.emiAmount), style: pw.TextStyle(font: ttfBold, fontSize: 10, color: textDark))),
                pw.Expanded(flex: 2, child: pw.Text('${_ordinal(loan.dueDay)} of month', style: pw.TextStyle(font: ttf, fontSize: 10, color: textGrey))),
                pw.Expanded(flex: 2, child: pw.Text(progress, style: pw.TextStyle(font: ttf, fontSize: 10, color: textGrey))),
                pw.Expanded(flex: 2, child: pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: PdfColor(statusColor.red, statusColor.green, statusColor.blue, 0.12),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  ),
                  child: pw.Text(statusText,
                      style: pw.TextStyle(font: ttfBold, fontSize: 9, color: statusColor),
                      textAlign: pw.TextAlign.center),
                )),
              ]),
            );
          }),

          pw.SizedBox(height: 24),
          _sectionTitle('Loan Details Breakdown', primary, ttfBold),
          pw.SizedBox(height: 10),
          ...loans.map((loan) => _loanDetailCard(loan, fmt, primary, primaryLight, textDark, textGrey, success, warning, danger, ttf, ttfBold)),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'EMI_Summary_${DateFormat('yyyyMMdd').format(now)}.pdf',
    );
  }

  static pw.Widget _buildHeader(String date, pw.Font ttf, pw.Font ttfBold) {
    return pw.Container(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF6366F1)),
      padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text('EMI Reminder', style: pw.TextStyle(font: ttfBold, fontSize: 20, color: PdfColors.white)),
            pw.Text('Loan Summary Report', style: pw.TextStyle(font: ttf, fontSize: 11, color: const PdfColor.fromInt(0xCCFFFFFF))),
          ]),
          pw.Text(date, style: pw.TextStyle(font: ttf, fontSize: 10, color: const PdfColor.fromInt(0xCCFFFFFF))),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context ctx, pw.Font ttf) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColor.fromInt(0xFFE5E7EB))),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text('Generated by EMI Reminder App', style: pw.TextStyle(font: ttf, fontSize: 8, color: const PdfColor.fromInt(0xFF9CA3AF))),
          pw.Text('Page ${ctx.pageNumber} of ${ctx.pagesCount}', style: pw.TextStyle(font: ttf, fontSize: 8, color: const PdfColor.fromInt(0xFF9CA3AF))),
        ],
      ),
    );
  }

  static pw.Widget _sectionTitle(String title, PdfColor color, pw.Font ttfBold) {
    return pw.Row(children: [
      pw.Container(
        width: 4, height: 18,
        decoration: pw.BoxDecoration(color: color, borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2))),
      ),
      pw.SizedBox(width: 8),
      pw.Text(title, style: pw.TextStyle(font: ttfBold, fontSize: 14, color: const PdfColor.fromInt(0xFF111827))),
    ]);
  }

  static pw.Widget _summaryCard(String label, String value, PdfColor color, PdfColor bg, pw.Font ttf, pw.Font ttfBold) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: bg,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          border: pw.Border.all(color: PdfColor(color.red, color.green, color.blue, 0.2)),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(value, style: pw.TextStyle(font: ttfBold, fontSize: 18, color: color)),
          pw.SizedBox(height: 4),
          pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 9, color: const PdfColor.fromInt(0xFF6B7280))),
        ]),
      ),
    );
  }

  static pw.Widget _loanDetailCard(Loan loan, String Function(double) fmt,
      PdfColor primary, PdfColor primaryLight, PdfColor textDark, PdfColor textGrey,
      PdfColor success, PdfColor warning, PdfColor danger, pw.Font ttf, pw.Font ttfBold) {
    final daysUntil = loan.daysUntilDue();
    final isOverdue = loan.isOverdue();
    PdfColor statusColor;
    if (loan.isPaid) { statusColor = success; }
    else if (isOverdue) { statusColor = danger; }
    else if (daysUntil <= 3) { statusColor = warning; }
    else { statusColor = primary; }

    final hasDetails = loan.loanAmount != null || loan.interestRate != null || loan.tenureMonths != null;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFE5E7EB)),
      ),
      child: pw.Column(children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: primaryLight,
            borderRadius: const pw.BorderRadius.only(topLeft: pw.Radius.circular(10), topRight: pw.Radius.circular(10)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text(loan.name, style: pw.TextStyle(font: ttfBold, fontSize: 12, color: textDark)),
                if (loan.bankName != null)
                  pw.Text(loan.bankName!, style: pw.TextStyle(font: ttf, fontSize: 9, color: textGrey)),
              ]),
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
                pw.Text(fmt(loan.emiAmount), style: pw.TextStyle(font: ttfBold, fontSize: 14, color: primary)),
                pw.Text('per month', style: pw.TextStyle(font: ttf, fontSize: 8, color: textGrey)),
              ]),
            ],
          ),
        ),
        if (hasDetails)
          pw.Padding(
            padding: const pw.EdgeInsets.all(14),
            child: pw.Row(children: [
              if (loan.loanAmount != null) ...[
                _detailCell('Principal', fmt(loan.loanAmount!), textDark, textGrey, ttf, ttfBold),
                pw.SizedBox(width: 16),
              ],
              if (loan.interestRate != null) ...[
                _detailCell('Interest Rate', '${loan.interestRate}% p.a.', textDark, textGrey, ttf, ttfBold),
                pw.SizedBox(width: 16),
              ],
              if (loan.tenureMonths != null) ...[
                _detailCell('Tenure', '${loan.tenureMonths} months', textDark, textGrey, ttf, ttfBold),
                pw.SizedBox(width: 16),
              ],
              if (loan.loanAmount != null && loan.tenureMonths != null)
                _detailCell('Total Paid', fmt(loan.emiAmount * loan.emisPaidCount), statusColor, textGrey, ttf, ttfBold),
            ]),
          ),
        if (loan.notes != null && loan.notes!.isNotEmpty)
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: pw.Text('Note: ${loan.notes}', style: pw.TextStyle(font: ttf, fontSize: 9, color: textGrey)),
          ),
      ]),
    );
  }

  static pw.Widget _detailCell(String label, String value, PdfColor valueColor, PdfColor labelColor, pw.Font ttf, pw.Font ttfBold) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(label, style: pw.TextStyle(font: ttf, fontSize: 8, color: labelColor)),
      pw.SizedBox(height: 2),
      pw.Text(value, style: pw.TextStyle(font: ttfBold, fontSize: 10, color: valueColor)),
    ]);
  }

  static String _ordinal(int n) {
    if (n >= 11 && n <= 13) return '${n}th';
    switch (n % 10) {
      case 1: return '${n}st';
      case 2: return '${n}nd';
      case 3: return '${n}rd';
      default: return '${n}th';
    }
  }

  /// Maps unicode currency symbols → PDF-safe ASCII so no glyph boxes appear
  static String _pdfSafeCurrency(String symbol) {
    const map = {
      '₹': 'Rs.',  // Indian Rupee
      '₩': 'KRW ', // Korean Won
      '₪': 'ILS ', // Israeli Shekel
      '₦': 'NGN ', // Nigerian Naira
      '₫': 'VND ', // Vietnamese Dong
      '₭': 'LAK ', // Lao Kip
      '₮': 'MNT ', // Mongolian Tugrik
      '₱': 'PHP ', // Philippine Peso
      '₲': 'PYG ', // Paraguayan Guarani
      '₴': 'UAH ', // Ukrainian Hryvnia
      '₵': 'GHS ', // Ghanaian Cedi
    };
    return map[symbol] ?? symbol; // $, €, £, ¥ are in the font already
  }
}






