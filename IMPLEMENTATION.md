# EMI Reminder App

A Flutter-based Android application to help users track loans, EMIs, and upcoming due dates with local notifications and offline functionality.

## Features

### 1. **Home Screen**
- Display list of all loans sorted by due date
- Show EMI amount and next due date for each loan
- Color-coded status indicators:
  - 🔴 **Overdue** - Red (past due date)
  - 🟠 **Due Soon** - Orange (3 days or less)
  - 🟢 **Upcoming** - Green/Blue (more than 3 days)
  - ✅ **Paid** - Green
- Empty state with helpful message when no loans exist
- Quick actions (edit, delete, mark as paid) via bottom sheet

### 2. **Add/Edit Loan Screen**
- Input fields for:
  - Loan name
  - EMI amount (₹)
  - Due day of month (1-31)
  - Start date (date picker)
  - Optional notes
  - Optional loan details (for EMI calculator):
    - Loan amount
    - Interest rate
    - Tenure (months)
- Form validation for required fields
- Edit existing loans
- Automatic reminder scheduling

### 3. **Loan Details Screen**
- View complete loan information
- Color-coded header with loan name and EMI amount
- Due date details with days until due
- EMI breakdown calculator (if loan details provided):
  - Calculated EMI
  - Total interest
  - Total amount payable
- Quick edit/delete buttons

### 4. **EMI Calculator**
- Calculate EMI using standard formula: `EMI = P * r * (1 + r)^n / ((1 + r)^n - 1)`
- Where:
  - P = Principal (Loan Amount)
  - r = Monthly Interest Rate
  - n = Tenure in months
- Calculate total interest and total amount payable
- Integrated into Add Loan screen (optional fields)

### 5. **Local Notifications**
- Reminders scheduled at:
  - 3 days before due date
  - 1 day before due date
  - Due date morning (9 AM)
- Works completely offline
- No push notifications or cloud dependency
- Automatic reminder updates when loans are modified

### 6. **Local Storage**
- Uses Hive for fast, offline data persistence
- Auto-saves all changes locally
- Data persists across app restarts
- No cloud backend or login required

## Project Structure

```
lib/
├── main.dart                          # App entry point, initialization
├── models/
│   └── loan.dart                      # Loan model with Hive adapter
├── screens/
│   ├── home_screen.dart               # Main home screen with loan list
│   ├── add_loan_screen.dart           # Add/edit loan form
│   └── loan_detail_screen.dart        # Loan details view
├── services/
│   ├── loan_storage_service.dart      # Hive database operations
│   └── notification_service.dart      # Local notification scheduling
├── widgets/
│   └── loan_card.dart                 # Reusable loan card widget
└── utils/
    └── emi_calculator.dart            # EMI calculation utilities
```

## Technical Stack

- **Framework**: Flutter (Android only)
- **Language**: Dart 3.10+
- **Storage**: Hive (local key-value store)
- **Notifications**: flutter_local_notifications
- **Date/Time**: intl package
- **Code Generation**: build_runner + hive_generator

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  flutter_local_notifications: ^14.1.1
  intl: ^0.19.0
  get_it: ^7.6.0
  uuid: ^4.0.0

dev_dependencies:
  build_runner: ^2.4.6
  hive_generator: ^2.0.1
```

## Installation & Setup

### Prerequisites
- Flutter SDK (3.10+)
- Android Studio with Android SDK
- Android Emulator or physical device

### Steps

1. **Clone/Extract Project**
   ```bash
   cd emi_reminder
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive Adapters**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the App**
   ```bash
   flutter run
   ```

## How to Use

### Adding a Loan
1. Tap the **+ (Add)** button on Home Screen
2. Fill in loan details:
   - Name: "Car Loan"
   - EMI: ₹15,000
   - Due Day: 15
   - Start Date: Select date
3. (Optional) Add notes
4. (Optional) Provide loan details for EMI breakdown
5. Tap **Add Loan**
6. Reminders will be scheduled automatically

### Viewing Loan Details
1. Tap on any loan card on Home Screen
2. Select **View Details** from bottom sheet
3. See full loan information and EMI breakdown

### Editing a Loan
1. Tap on a loan card
2. Select **Edit Loan**
3. Modify details
4. Tap **Update Loan**
5. Reminders will be rescheduled

### Marking as Paid
1. Tap on a loan card
2. Select **Mark as Paid**
3. Loan status changes to "PAID" and reminders are cancelled

### Deleting a Loan
1. Tap on a loan card
2. Select **Delete Loan**
3. Confirm deletion
4. Reminders will be cancelled

## Key Features Explained

### Due Date Calculation
- Due date is calculated as the **Nth day of the current month** (where N is the due day)
- If the due day has passed, it moves to next month
- Example: If due day is 15 and today is 20th, next due is 15th of next month

### EMI Formula
```
EMI = P × r × (1 + r)^n / ((1 + r)^n - 1)

P = Principal amount
r = Monthly interest rate (Annual rate / 12 / 100)
n = Tenure in months

Total Interest = (EMI × n) - P
Total Amount = EMI × n
```

### Notification Timing
- Notifications are scheduled using system timezone
- They persist even if app is closed
- Works with device's do-not-disturb settings
- No internet connection required

## Data Storage

All data is stored locally in Hive boxes:
- **Box name**: 'loans'
- **Data type**: Loan objects
- **Location**: App's document directory (Android internal storage)
- **Security**: No encryption (local device only)

## Future Enhancements

Potential features for future versions:
- Cloud sync (Firebase/Supabase)
- Loan payment tracking
- Payment history
- Export data to CSV/PDF
- Recurring payment reminders
- Multiple currencies
- Dark mode
- Loan comparison tool
- Budget tracking

## Testing

Run widget tests:
```bash
flutter test
```

## Troubleshooting

### Notifications Not Showing
- Check device notification settings for the app
- Ensure notification channel is created
- Check device battery saver/power-saving mode
- Restart app if testing immediately after installation

### Data Not Persisting
- Ensure app has write permissions (Android 6+)
- Clear app cache/data from device settings
- Rebuild database: `flutter clean && flutter pub get`

### EMI Calculator Showing Wrong Values
- Verify interest rate format (should be annual percentage)
- Check tenure is in months
- Ensure principal amount is positive

## License

This project is private and for personal use.

## Contact & Support

For issues or feature requests, contact the developer.

---

**Version**: 1.0.0  
**Last Updated**: January 2026  
**Platform**: Android Only
