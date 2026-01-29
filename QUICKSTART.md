# EMI Reminder - Quick Start Guide

## 🚀 Getting Started

### Step 1: Install Dependencies
```bash
flutter pub get
```

### Step 2: Generate Hive Adapters
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Step 3: Run the App
```bash
flutter run
```

---

## 📋 App Walkthrough

### First Launch
- App opens with empty state: "No loans added yet"
- Tap the **green + button** to add your first loan

### Adding Your First Loan

**Basic Information:**
- **Loan Name**: "Home Loan" / "Car Loan" / "Personal Loan"
- **EMI Amount**: Enter the monthly payment amount (₹)
- **Due Day**: Day of the month when payment is due (1-31)
- **Start Date**: When you took the loan (use date picker)

**Optional Information:**
- **Notes**: Any additional details about the loan
- **Loan Calculator Details** (expand section):
  - Loan Amount (₹)
  - Interest Rate (% per annum)
  - Tenure (months)

**Example:**
```
Name:        Home Loan
EMI:         ₹25,000
Due Day:     5
Start Date:  Jan 1, 2024
Notes:       5-year home loan from HDFC Bank
Loan Amt:    ₹12,00,000
Rate:        7.5%
Tenure:      60 months
```

### Automatic Reminders
Once saved, the app will automatically schedule reminders:
- 📱 **3 days before** due date
- 📱 **1 day before** due date
- 📱 **Due date morning** at 9 AM

You'll see notifications even if the app is closed!

---

## 🎯 Using the App

### Home Screen Overview
```
┌─────────────────────────────────┐
│        EMI REMINDER      [menu]  │
├─────────────────────────────────┤
│  💳 Home Loan                     │
│     Due: Jan 5, 2026  │ 2 days   │
│     ₹25,000           │ DUE SOON │
│  ─────────────────────────────    │
│  💳 Car Loan                      │
│     Due: Jan 15, 2026 │ 12 days  │
│     ₹15,000           │ UPCOMING │
├─────────────────────────────────┤
│              [+ Add Loan]         │
└─────────────────────────────────┘
```

### Color Codes
- 🔴 **Red** = Overdue (past due date)
- 🟠 **Orange** = Due Soon (within 3 days)
- 🟢 **Green** = Upcoming (more than 3 days)
- ✅ **Green** = Paid

### Quick Actions
Tap on any loan card to see options:
- ✏️ **Edit Loan** - Modify details
- ✔️ **Mark as Paid** - Remove from active loans
- 🗑️ **Delete Loan** - Permanently remove

---

## 📊 EMI Calculator

If you provide loan details, the app calculates:

**Given:**
- Loan Amount: ₹12,00,000
- Interest Rate: 7.5% p.a.
- Tenure: 60 months

**Calculated:**
- EMI: ₹23,859
- Total Interest: ₹431,540
- Total Amount: ₹14,31,540

View this in the **Loan Details** screen under "EMI Breakdown"

---

## ⚙️ Settings & Options

### View Loan Details
1. Tap any loan → **View Details** (if not shown in card tap)
2. See complete information and EMI breakdown
3. Use **Edit** or **Delete** buttons

### Edit a Loan
1. Tap loan → **Edit Loan**
2. Modify any field
3. Tap **Update Loan**
4. Reminders automatically reschedule

### Delete a Loan
1. Tap loan → **Delete Loan**
2. Confirm deletion
3. Reminders automatically cancelled

### Data Storage
- All data is saved locally on your device
- No cloud or internet needed
- Data persists even after app closes
- No login required

---

## 🔔 Notifications

### How They Work
- Reminders trigger automatically on scheduled dates
- Show even when app is closed
- Use device notifications (respects do-not-disturb)

### To Receive Notifications
1. Enable notifications for the app:
   - Go to **Settings** → **Apps** → **EMI Reminder**
   - Tap **Notifications**
   - Enable "Allow notifications"
2. Ensure device notifications are enabled

### Testing Notifications
- Add a loan with due date = tomorrow
- You should receive notifications at scheduled times

---

## 📝 Example Workflows

### Workflow 1: Managing Monthly EMI
```
1. Add Loan: "Car Loan"
   - EMI: ₹15,000
   - Due: 15th of every month
   
2. Receive reminders:
   - Jan 12 (3 days before)
   - Jan 14 (1 day before)
   - Jan 15 (due date morning)
   
3. After paying:
   - Tap loan → "Mark as Paid"
   - Status changes to "PAID"
   - Reminders stop
   
4. Next cycle:
   - Loan automatically resets to next month
   - Add a new entry or edit existing
```

### Workflow 2: Comparing Multiple Loans
```
1. Add all loans to the app
2. Home screen shows them sorted by due date
3. Tap each loan to see:
   - EMI breakdown
   - Total interest
   - Remaining tenure
   
4. Make informed decisions about:
   - Which loan to prioritize
   - Prepayment opportunities
```

### Workflow 3: Loan Planning
```
1. Use EMI Calculator to test scenarios:
   - Different loan amounts
   - Different rates
   - Different tenures
   
2. Add the chosen loan to track
3. Get automatic reminders
```

---

## ❓ FAQ

**Q: Can I edit a loan after adding it?**
A: Yes! Tap the loan → Edit Loan → Make changes → Update

**Q: What if I miss a payment?**
A: The app will show it as "OVERDUE" in red. Edit or delete when you pay.

**Q: How are due dates calculated?**
A: Due date = [Due Day] of the current/next month
  - Example: If due day is 15 and today is 20th → Due is 15th next month

**Q: Will reminders work if app is closed?**
A: Yes! Reminders are scheduled system-wide and work offline.

**Q: Can I sync data to cloud?**
A: Not currently. All data is stored locally. Future versions may support cloud sync.

**Q: How do I backup my data?**
A: Currently, data is stored in device local storage. Factory reset will delete data.

**Q: Can I export my loans?**
A: Not in current version. Future versions will support CSV/PDF export.

---

## 🐛 Troubleshooting

### Problem: Reminders not showing
**Solution:**
1. Check Settings → Apps → EMI Reminder → Notifications
2. Enable "Allow notifications"
3. Disable device battery saver/power-saving mode
4. Restart app

### Problem: Data disappeared
**Solution:**
1. Check if app was uninstalled or data cleared
2. Reinstall app if needed
3. Add loans again (data is device-local)

### Problem: EMI calculation looks wrong
**Solution:**
1. Verify interest rate is annual (not monthly)
2. Verify tenure is in months (not years)
3. Recalculate manually: EMI = P×r×(1+r)^n / ((1+r)^n - 1)

---

## 🎨 UI Tips

- **Swipe left** on list items for quick delete (if supported)
- **Long press** on loan card for quick actions
- **Tap AppBar** to scroll to top of list
- **Use device back** button to go back between screens

---

**Version**: 1.0.0  
**Last Updated**: January 2026  

Enjoy tracking your EMIs! 📊💰
