# EMI Reminder - Developer Quick Reference

## 🚀 Quick Commands

```bash
# Install dependencies
flutter pub get

# Generate Hive adapters
flutter pub run build_runner build --delete-conflicting-outputs

# Run app
flutter run

# Run tests
flutter test

# Build APK
flutter build apk --release

# Analyze code
flutter analyze

# Format code
dart format lib/

# Check for outdated packages
flutter pub outdated
```

---

## 📁 File Structure Quick Lookup

| Path | Purpose | Key Classes |
|------|---------|-------------|
| `lib/main.dart` | App initialization | EmiReminderApp, main() |
| `lib/models/loan.dart` | Loan data model | Loan, LoanAdapter |
| `lib/screens/home_screen.dart` | Main loan list | HomeScreen, _HomeScreenState |
| `lib/screens/add_loan_screen.dart` | Add/edit loan | AddLoanScreen, _AddLoanScreenState |
| `lib/screens/loan_detail_screen.dart` | Loan details | LoanDetailScreen |
| `lib/services/loan_storage_service.dart` | Database ops | LoanStorageService |
| `lib/services/notification_service.dart` | Notifications | NotificationService |
| `lib/widgets/loan_card.dart` | Loan UI card | LoanCard |
| `lib/utils/emi_calculator.dart` | EMI calculations | EMICalculator |

---

## 🔑 Key Methods Reference

### LoanStorageService
```dart
await storageService.init()                    // Initialize Hive
await storageService.addLoan(loan)             // Add new loan
await storageService.updateLoan(id, loan)      // Update existing
await storageService.deleteLoan(id)            // Delete loan
storageService.getLoanById(id)                 // Get by ID
storageService.getAllLoans()                   // Get all loans
storageService.getLoansDueSoon()               // Get due within 3 days
storageService.getOverdueLoans()               // Get overdue
storageService.watchLoans()                    // Watch for changes
```

### NotificationService
```dart
await notificationService.init()               // Initialize notifications
await notificationService.scheduleLoandReminders(loan)  // Schedule reminders
await notificationService.cancelLoanReminders(loanId)   // Cancel reminders
await notificationService.showTestNotification()        // Test notification
```

### Loan Model
```dart
loan.getNextDueDate()                          // Calculate next due
loan.daysUntilDue()                            // Days remaining
loan.shouldSendReminder()                      // Check if reminder needed
```

### EMICalculator
```dart
EMICalculator.calculateEMI(
  principal: 1000000,
  annualRate: 7.5,
  tenureMonths: 60
)

EMICalculator.calculateTotalInterest(
  principal: 1000000,
  annualRate: 7.5,
  tenureMonths: 60
)

EMICalculator.getLoanBreakdown(...)            // All calculations
```

---

## 🎨 Common UI Patterns

### Opening Add Loan Screen
```dart
final result = await Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => AddLoanScreen(
      storageService: _storageService,
      notificationService: _notificationService,
    ),
  ),
);

if (result != null) {
  // Loan was added
}
```

### Showing Bottom Sheet Menu
```dart
showModalBottomSheet(
  context: context,
  builder: (context) => Container(
    padding: const EdgeInsets.all(16),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: Icon(Icons.edit),
          title: Text('Edit'),
          onTap: () {
            Navigator.pop(context);
            // Handle edit
          },
        ),
      ],
    ),
  ),
);
```

### Real-time List Update
```dart
ValueListenableBuilder(
  valueListenable: Hive.box<Loan>('loans').listenable(),
  builder: (context, Box<Loan> box, _) {
    final loans = box.values.toList();
    return ListView.builder(
      itemCount: loans.length,
      itemBuilder: (context, index) => LoanCard(
        loan: loans[index],
      ),
    );
  },
)
```

### Form Validation
```dart
final _formKey = GlobalKey<FormState>();

Form(
  key: _formKey,
  child: Column(
    children: [
      TextFormField(
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          return null;
        },
      ),
    ],
  ),
)

// Before submit:
if (!_formKey.currentState!.validate()) return;
```

---

## 💾 Data Model Reference

### Loan Class
```dart
Loan {
  String id                    // Unique identifier
  String name                  // "Home Loan"
  double emiAmount             // Monthly payment
  int dueDay                   // 1-31
  DateTime startDate           // When loan started
  String? notes                // Optional notes
  double? loanAmount           // For calculator
  double? interestRate         // Annual %
  int? tenureMonths            // In months
  bool isPaid                  // Payment status
}
```

### Example Loan Object
```dart
Loan(
  id: '1234567_5678',
  name: 'Car Loan',
  emiAmount: 15000,
  dueDay: 15,
  startDate: DateTime(2024, 1, 1),
  notes: 'HDFC Bank, 5-year tenure',
  loanAmount: 900000,
  interestRate: 7.5,
  tenureMonths: 60,
  isPaid: false,
)
```

---

## 🎯 Common Tasks

### Add a New Loan Programmatically
```dart
final loan = Loan(
  id: DateTime.now().millisecondsSinceEpoch.toString(),
  name: 'Personal Loan',
  emiAmount: 5000,
  dueDay: 20,
  startDate: DateTime.now(),
);

await _storageService.addLoan(loan);
await _notificationService.scheduleLoandReminders(loan);
```

### Mark Loan as Paid
```dart
loan.isPaid = true;
await _storageService.updateLoan(loan.id, loan);
await _notificationService.cancelLoanReminders(loan.id);
```

### Delete a Loan
```dart
await _storageService.deleteLoan(loan.id);
await _notificationService.cancelLoanReminders(loan.id);
```

### Get All Loans Due Soon
```dart
final dueSoonLoans = _storageService.getLoansDueSoon();
// Returns loans due within 3 days, sorted
```

### Calculate EMI
```dart
final breakdown = EMICalculator.getLoanBreakdown(
  principal: 1200000,
  annualRate: 7.5,
  tenureMonths: 60,
);

print('EMI: ${breakdown['emi']}');
print('Total Interest: ${breakdown['totalInterest']}');
print('Total Amount: ${breakdown['totalAmount']}');
```

---

## 🐛 Debugging Tips

### Check Hive Box
```dart
// In IDE console:
// Add breakpoint in code:
final box = Hive.box<Loan>('loans');
print('Loans count: ${box.length}');
for (var loan in box.values) {
  print('${loan.name}: ${loan.emiAmount}');
}
```

### Test Notifications
```dart
// Call in any screen:
await notificationService.showTestNotification();
```

### Check Due Date Logic
```dart
final loan = ...;
print('Next due: ${loan.getNextDueDate()}');
print('Days until: ${loan.daysUntilDue()}');
```

### Verify EMI Calculation
```dart
final emi = EMICalculator.calculateEMI(
  principal: 1000000,
  annualRate: 7.5,
  tenureMonths: 60,
);
print('EMI: $emi');  // Should be ~23859
```

---

## 📊 Status Indicator Logic

```dart
int daysUntilDue = loan.daysUntilDue();

if (loan.isPaid) {
  status = "PAID"
  color = Colors.green
} else if (daysUntilDue < 0) {
  status = "OVERDUE"
  color = Colors.red
} else if (daysUntilDue == 0) {
  status = "DUE TODAY"
  color = Colors.orange
} else if (daysUntilDue <= 3) {
  status = "DUE SOON"
  color = Colors.orange
} else {
  status = "UPCOMING"
  color = Colors.blue
}
```

---

## 📱 Screen Navigation Map

```
HomeScreen (Entry Point)
├── Tap + FAB
│   └── AddLoanScreen
│       └── Save → back to HomeScreen
│
├── Tap Loan Card
│   └── Bottom Sheet Menu
│       ├── Edit Loan → AddLoanScreen (with existingLoan)
│       ├── Mark as Paid → Update & back
│       └── Delete Loan → Confirm & back
│
└── Tap View Details (if navigating)
    └── LoanDetailScreen
        ├── Edit button → AddLoanScreen
        └── Delete button → Confirm & back
```

---

## 🔐 Dependency Injection

### Initialize in main.dart
```dart
// Create services
final storageService = LoanStorageService();
await storageService.init();

final notificationService = NotificationService();
await notificationService.init();

// Pass to app
runApp(
  EmiReminderApp(
    storageService: storageService,
    notificationService: notificationService,
  ),
);
```

### Receive in Screens
```dart
class HomeScreen extends StatefulWidget {
  final LoanStorageService? storageService;
  final NotificationService? notificationService;

  const HomeScreen({
    this.storageService,
    this.notificationService,
  });
}
```

---

## 🧪 Testing Snippets

### Test EMI Calculator
```dart
test('Calculate EMI', () {
  final emi = EMICalculator.calculateEMI(
    principal: 1000000,
    annualRate: 7.5,
    tenureMonths: 60,
  );
  expect(emi, closeTo(23859, 1));
});
```

### Widget Test
```dart
testWidgets('Empty state displays', (tester) async {
  await tester.pumpWidget(MaterialApp(home: HomeScreen()));
  expect(find.text('No loans added yet'), findsOneWidget);
});
```

---

## 📋 Checklist for New Features

Adding a new loan field? Follow this:
1. [ ] Add field to Loan model in `loan.dart`
2. [ ] Regenerate Hive adapter: `flutter pub run build_runner build`
3. [ ] Update AddLoanScreen form with new field
4. [ ] Update LoanDetailScreen to display field
5. [ ] Update LoanCard if needed
6. [ ] Test data persistence with restart
7. [ ] Update documentation

---

## 🎯 Performance Tips

```dart
// ✅ GOOD: Efficient query
final loan = storageService.getLoanById(id);

// ❌ AVOID: Inefficient search
final loan = storageService.getAllLoans()
  .firstWhere((l) => l.id == id);

// ✅ GOOD: Sort once, cache result
final sortedLoans = box.values.toList()
  ..sort((a, b) => a.daysUntilDue().compareTo(b.daysUntilDue()));

// ❌ AVOID: Sort on every rebuild
loans.sort((a, b) => a.daysUntilDue().compareTo(b.daysUntilDue()));
```

---

## 🚨 Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Box not found: 'loans'` | Hive not initialized | Run init() before accessing |
| `The name 'Loan' isn't a class` | Adapter not generated | Run `flutter pub run build_runner build` |
| `Notifications not showing` | Permissions denied | Enable in device settings |
| `Data lost after uninstall` | Local-only storage | Data is device-local by design |
| `UI not updating` | Not using ValueListenableBuilder | Use reactive builder for Hive |

---

## 📞 Support Resources

```
Issues:                 → Check TROUBLESHOOTING.md
Architecture:           → Read ARCHITECTURE.md
User Guide:             → See QUICKSTART.md
Full Documentation:     → Review IMPLEMENTATION_SUMMARY.md
Code Examples:          → Check each file's comments
```

---

**Version:** 1.0.0  
**Last Updated:** January 17, 2026  
**Happy Coding!** 🚀
