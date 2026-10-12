import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import '../models/loan.dart';

class ShareService {
  static const playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.santhosh.p2preminder';

  /// Share the app on Play Store — drives organic installs
  static Future<void> shareApp() async {
    const message =
        '''💰 EMI Reminder — Never miss a loan payment!

✅ Track all your EMIs in one place
🔔 Smart reminders before due dates
📊 Loan analytics & health score
📄 Export PDF summary
🆓 Free & works offline

📲 Download now:
${ShareService.playStoreUrl}

#EMIReminder #LoanTracker #PersonalFinance''';

    await Share.share(message, subject: 'EMI Reminder App — Free Loan Tracker');
  }

  /// Share a single loan summary — viral loop
  static Future<void> shareLoanSummary(Loan loan) async {
    final fmt = NumberFormat('#,##,###');
    final symbol = loan.currencySymbol;
    final daysLeft = loan.daysUntilDue();
    final progress = (loan.tenureMonths != null && loan.tenureMonths! > 0)
        ? '${loan.emisPaidCount}/${loan.tenureMonths} EMIs paid (${((loan.emisPaidCount / loan.tenureMonths!) * 100).toStringAsFixed(0)}%)'
        : 'Tracking active';

    final totalPaid = loan.emiAmount * loan.emisPaidCount;
    final totalLoan = loan.loanAmount;

    final buffer = StringBuffer();
    buffer.writeln('📊 *${loan.name} — Loan Summary*');
    buffer.writeln('');
    buffer.writeln(
      '💳 EMI Amount: *$symbol${fmt.format(loan.emiAmount)}/month*',
    );
    if (loan.bankName != null) {
      buffer.writeln('🏦 Bank: ${loan.bankName}');
    }
    buffer.writeln('📅 Next Due: ${_formatDate(loan.getNextDueDate())}');
    if (daysLeft > 0) {
      buffer.writeln('⏳ Days Left: $daysLeft days');
    } else if (daysLeft == 0) {
      buffer.writeln('⚠️ Due TODAY!');
    } else {
      buffer.writeln('🚨 Overdue by ${daysLeft.abs()} days');
    }
    buffer.writeln('');
    buffer.writeln('📈 Progress: $progress');
    if (totalPaid > 0) {
      buffer.writeln('💰 Total Paid So Far: $symbol${fmt.format(totalPaid)}');
    }
    if (totalLoan != null) {
      buffer.writeln('🏷️ Principal Amount: $symbol${fmt.format(totalLoan)}');
    }
    if (loan.interestRate != null) {
      buffer.writeln('📉 Interest Rate: ${loan.interestRate}% p.a.');
    }
    if (loan.tenureMonths != null) {
      final years = loan.tenureMonths! ~/ 12;
      final months = loan.tenureMonths! % 12;
      final tenure = years > 0
          ? '$years yr${years > 1 ? 's' : ''}${months > 0 ? ' $months mo' : ''}'
          : '$months months';
      buffer.writeln('🗓️ Tenure: $tenure');
    }
    buffer.writeln('');
    buffer.writeln('_Tracked with EMI Reminder App 📱_');
    buffer.writeln(ShareService.playStoreUrl);

    await Share.share(
      buffer.toString(),
      subject: '${loan.name} — Loan Summary',
    );
  }

  /// Share all loans overview — monthly summary
  static Future<void> shareMonthlyOverview(List<Loan> loans) async {
    if (loans.isEmpty) return;
    final fmt = NumberFormat('#,##,###');
    final symbol = loans.first.currencySymbol;
    final totalEmi = loans.fold<double>(0, (s, l) => s + l.emiAmount);
    final paid = loans.where((l) => l.isPaid).length;
    final overdue = loans.where((l) => l.isOverdue()).length;
    final dueSoon = loans
        .where((l) => !l.isPaid && l.daysUntilDue() <= 3)
        .length;

    final buffer = StringBuffer();
    buffer.writeln('📊 *My Monthly EMI Overview*');
    buffer.writeln('🗓️ ${DateFormat('MMMM yyyy').format(DateTime.now())}');
    buffer.writeln('');
    buffer.writeln('💳 *Total EMI: $symbol${fmt.format(totalEmi)}/month*');
    buffer.writeln('📋 Total Loans: ${loans.length}');
    buffer.writeln('✅ Paid: $paid');
    if (dueSoon > 0) buffer.writeln('⚠️ Due Soon: $dueSoon');
    if (overdue > 0) buffer.writeln('🚨 Overdue: $overdue');
    buffer.writeln('');
    buffer.writeln('*Loan Breakdown:*');
    for (final loan in loans) {
      final status = loan.isPaid
          ? '✅'
          : loan.isOverdue()
          ? '🚨'
          : '⏳';
      buffer.writeln(
        '$status ${loan.name}: $symbol${fmt.format(loan.emiAmount)}',
      );
    }
    buffer.writeln('');
    buffer.writeln('_Tracked with EMI Reminder App 📱_');
    buffer.writeln(ShareService.playStoreUrl);

    await Share.share(buffer.toString(), subject: 'My Monthly EMI Overview');
  }

  static String _formatDate(DateTime date) {
    return DateFormat('MMM d, yyyy').format(date);
  }
}
