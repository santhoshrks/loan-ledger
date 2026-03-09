import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
  _AppLocalizationsDelegate();

  String get appName {
    switch (locale.languageCode) {
      case 'ta': return 'EMI நினைவூட்டல்';
      case 'te': return 'EMI రిమైండర్';
      case 'hi': return 'EMI रिमाइंडर';
      default: return 'EMI Reminder';
    }
  }

  String get appFullName {
    switch (locale.languageCode) {
      case 'ta': return 'EMI நினைவூட்டல் மற்றும் கடன் கண்காணிப்பு';
      case 'te': return 'EMI రిమైండర్ మరియు రుణ ట్రాకర్';
      case 'hi': return 'EMI रिमाइंडर और ऋण ट्रैकर';
      default: return 'EMI Reminder & Loan Tracker';
    }
  }

  String get appTagline {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் கண்காணிப்பு';
      case 'te': return 'రుణ ట్రాకర్';
      case 'hi': return 'ऋण ट्रैकर';
      default: return 'Loan Tracker';
    }
  }

  String get addLoan {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் சேர்க்க';
      case 'te': return 'రుణాన్ని జోడించండి';
      case 'hi': return 'ऋण जोड़ें';
      default: return 'Add Loan';
    }
  }

  String get noLoans {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்கள் இல்லை';
      case 'te': return 'ఎటువంటి రుణాలు లేవు';
      case 'hi': return 'कोई ऋण नहीं';
      default: return 'No Loans';
    }
  }

  String get loadingYourLoans {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்கள் ஏற்றப்படுகின்றன...';
      case 'te': return 'మీ రుణాలు లోడ్ అవుతున్నాయి...';
      case 'hi': return 'आपके ऋण लोड हो रहे हैं...';
      default: return 'Loading your loans...';
    }
  }

  String get emiCalculator {
    switch (locale.languageCode) {
      case 'ta': return 'EMI கணக்கீடு';
      case 'te': return 'EMI కాలిక్యులేటర్';
      case 'hi': return 'EMI कैलकुलेटर';
      default: return 'EMI Calculator';
    }
  }

  String get calendar {
    switch (locale.languageCode) {
      case 'ta': return 'நாட்காட்டி';
      case 'te': return 'క్యాలెండర్';
      case 'hi': return 'कैलेंडर';
      default: return 'Calendar';
    }
  }

  String get progress {
    switch (locale.languageCode) {
      case 'ta': return 'முன்னேற்றம்';
      case 'te': return 'పురోగతి';
      case 'hi': return 'प्रगति';
      default: return 'Progress';
    }
  }

  String get backup {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி';
      case 'te': return 'బ్యాకప్';
      case 'hi': return 'बैकअप';
      default: return 'Backup';
    }
  }

  String get restore {
    switch (locale.languageCode) {
      case 'ta': return 'மீட்டெடு';
      case 'te': return 'పునరుద్ధరించండి';
      case 'hi': return 'पुनर्स्थापित करें';
      default: return 'Restore';
    }
  }

  String get settings {
    switch (locale.languageCode) {
      case 'ta': return 'அமைப்புகள்';
      case 'te': return 'సెట్టింగ్‌లు';
      case 'hi': return 'सेटिंग्स';
      default: return 'Settings';
    }
  }

  String get manageYourData {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் தரவை நிர்வகிக்கவும்';
      case 'te': return 'మీ డేటాను నిర్వహించండి';
      case 'hi': return 'अपना डेटा प्रबंधित करें';
      default: return 'Manage your data';
    }
  }

  String get backupAndRestore {
    switch (locale.languageCode) {
      case 'ta': return 'காப்பு & மீட்டெடு';
      case 'te': return 'బ్యాకప్ & పునరుద్ధరణ';
      case 'hi': return 'बैकअप और पुनर्स्थापना';
      default: return 'Backup & Restore';
    }
  }

  String get backupDescription {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் கடன் தரவை பாதுகாப்பாக வைக்க ஏற்றுமதி செய்து, தேவைப்படும்போது இறக்குமதி செய்யுங்கள்';
      case 'te': return 'మీ రుణ డేటాను సురక్షితంగా ఉంచడానికి ఎగుమతి చేసి, అవసరమైనప్పుడు దిగుమతి చేయండి';
      case 'hi': return 'अपने ऋण डेटा को सुरक्षित रखने के लिए निर्यात करें और जरूरत पड़ने पर आयात करें';
      default: return 'Export your loan data to keep it safe, and import when needed';
    }
  }

  String get currentData {
    switch (locale.languageCode) {
      case 'ta': return 'தற்போதைய தரவு';
      case 'te': return 'ప్రస్తుత డేటా';
      case 'hi': return 'वर्तमान डेटा';
      default: return 'Current Data';
    }
  }

  String get loansStored {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்கள் சேமிக்கப்பட்டுள்ளன';
      case 'te': return 'రుణాలు నిల్వ చేయబడ్డాయి';
      case 'hi': return 'ऋण संग्रहीत';
      default: return 'loans stored';
    }
  }

  String get exportBackup {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி ஏற்றுமதி';
      case 'te': return 'బ్యాకప్ ఎగుమతి';
      case 'hi': return 'बैकअप निर्यात करें';
      default: return 'Export Backup';
    }
  }

  String get exportBackupDescription {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் எல்லா கடன்களையும் JSON கோப்பாக சேமிக்கவும்';
      case 'te': return 'మీ అన్ని రుణాలను JSON ఫైల్‌గా సేవ్ చేయండి';
      case 'hi': return 'अपने सभी ऋणों को JSON फ़ाइल के रूप में सहेजें';
      default: return 'Save all your loans as a JSON file';
    }
  }

  String get importBackup {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி இறக்குமதி';
      case 'te': return 'బ్యాకప్ దిగుమతి';
      case 'hi': return 'बैकअप आयात करें';
      default: return 'Import Backup';
    }
  }

  String get importBackupDescription {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி கோப்பிலிருந்து கடன்களை மீட்டெடுக்கவும்';
      case 'te': return 'బ్యాకప్ ఫైల్ నుండి రుణాలను పునరుద్ధరించండి';
      case 'hi': return 'बैकअप फ़ाइल से ऋण पुनर्स्थापित करें';
      default: return 'Restore loans from a backup file';
    }
  }

  String get autoBackupTitle {
    switch (locale.languageCode) {
      case 'ta': return 'தானியங்கு Google காப்புப்பிரதி';
      case 'te': return 'ఆటో Google బ్యాకప్';
      case 'hi': return 'स्वचालित Google बैकअप';
      default: return 'Auto Google Backup';
    }
  }

  String get autoBackupDescription {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் தரவு தானாகவே Google Drive-க்கு காப்புப்பிரதி செய்யப்படும். ஆப்பை மீண்டும் நிறுவினால், உங்கள் தரவு தானாக மீட்டெடுக்கப்படும்.';
      case 'te': return 'మీ డేటా స్వయంచాలకంగా Google Driveకి బ్యాకప్ అవుతుంది. యాప్‌ని మళ్ళీ ఇన్‌స్టాల్ చేస్తే, మీ డేటా స్వయంచాలకంగా పునరుద్ధరించబడుతుంది.';
      case 'hi': return 'आपका डेटा स्वचालित रूप से Google Drive पर बैकअप होता है। ऐप को फिर से इंस्टॉल करने पर, आपका डेटा स्वचालित रूप से पुनर्स्थापित हो जाएगा।';
      default: return 'Your data is automatically backed up to Google Drive. If you reinstall the app, your data will be automatically restored.';
    }
  }

  String get changeLanguageFromDrawer {
    switch (locale.languageCode) {
      case 'ta': return 'மொழியை மாற்ற மேல் மெனுவைப் பயன்படுத்தவும்';
      case 'te': return 'భాషను మార్చడానికి పై మెనూని ఉపయోగించండి';
      case 'hi': return 'भाषा बदलने के लिए ऊपर मेनू का उपयोग करें';
      default: return 'Use the top menu to change language';
    }
  }

  String get backupCreatedSuccessfully {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி வெற்றிகரமாக உருவாக்கப்பட்டது';
      case 'te': return 'బ్యాకప్ విజయవంతంగా సృష్టించబడింది';
      case 'hi': return 'बैकअप सफलतापूर्वक बनाया गया';
      default: return 'Backup created successfully';
    }
  }

  String get backupFailed {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி தோல்வியடைந்தது';
      case 'te': return 'బ్యాకప్ విఫలమైంది';
      case 'hi': return 'बैकअप विफल';
      default: return 'Backup failed';
    }
  }

  String get importBackupConfirmation {
    switch (locale.languageCode) {
      case 'ta': return 'இது காப்புப்பிரதி கோப்பிலிருந்து கடன்களை இறக்குமதி செய்யும். தொடரவா?';
      case 'te': return 'ఇది బ్యాకప్ ఫైల్ నుండి రుణాలను దిగుమతి చేస్తుంది. కొనసాగించాలా?';
      case 'hi': return 'यह बैकअप फ़ाइल से ऋण आयात करेगा। जारी रखें?';
      default: return 'This will import loans from backup file. Continue?';
    }
  }

  String get import {
    switch (locale.languageCode) {
      case 'ta': return 'இறக்குமதி';
      case 'te': return 'దిగుమతి';
      case 'hi': return 'आयात';
      default: return 'Import';
    }
  }

  String get importedSuccessfully {
    switch (locale.languageCode) {
      case 'ta': return 'வெற்றிகரமாக இறக்குமதி செய்யப்பட்டது';
      case 'te': return 'విజయవంతంగా దిగుమతి చేయబడింది';
      case 'hi': return 'सफलतापूर्वक आयात किया गया';
      default: return 'Imported successfully';
    }
  }

  String get noLoansImported {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்கள் எதுவும் இறக்குமதி செய்யப்படவில்லை';
      case 'te': return 'రుణాలు దిగుమతి కాలేదు';
      case 'hi': return 'कोई ऋण आयात नहीं किया गया';
      default: return 'No loans imported';
    }
  }

  String get importFailed {
    switch (locale.languageCode) {
      case 'ta': return 'இறக்குமதி தோல்வியடைந்தது';
      case 'te': return 'దిగుమతి విఫలమైంది';
      case 'hi': return 'आयात विफल';
      default: return 'Import failed';
    }
  }

  String get backupReminder {
    switch (locale.languageCode) {
      case 'ta': return 'காப்புப்பிரதி நினைவூட்டல்';
      case 'te': return 'బ్యాకప్ రిమైండర్';
      case 'hi': return 'बैकअप रिमाइंडर';
      default: return 'Backup Reminder';
    }
  }

  String get backupReminderMessage {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் கடன் தரவை பாதுகாக்க காப்புப்பிரதி எடுக்கவும். ஆப்பை நீக்கினால் தரவு இழக்கப்படும்.';
      case 'te': return 'మీ రుణ డేటాను రక్షించడానికి బ్యాకప్ తీసుకోండి. యాప్‌ని అన్‌ఇన్‌స్టాల్ చేస్తే డేటా పోతుంది.';
      case 'hi': return 'अपने ऋण डेटा की सुरक्षा के लिए बैकअप लें। ऐप अनइंस्टॉल करने पर डेटा खो जाएगा।';
      default: return 'Backup your loan data to keep it safe. Data will be lost if you uninstall the app.';
    }
  }

  String get neverBackedUp {
    switch (locale.languageCode) {
      case 'ta': return 'நீங்கள் இதுவரை காப்புப்பிரதி எடுக்கவில்லை';
      case 'te': return 'మీరు ఇంకా బ్యాకప్ తీసుకోలేదు';
      case 'hi': return 'आपने अभी तक बैकअप नहीं लिया है';
      default: return 'You have not backed up yet';
    }
  }

  String get lastBackupDaysAgo {
    switch (locale.languageCode) {
      case 'ta': return 'நாட்களுக்கு முன் காப்புப்பிரதி எடுக்கப்பட்டது';
      case 'te': return 'రోజుల క్రితం బ్యాకప్ తీసుకున్నారు';
      case 'hi': return 'दिन पहले बैकअप लिया था';
      default: return 'days ago backup was taken';
    }
  }

  String get backupNow {
    switch (locale.languageCode) {
      case 'ta': return 'இப்போது காப்புப்பிரதி';
      case 'te': return 'ఇప్పుడు బ్యాకప్';
      case 'hi': return 'अभी बैकअप करें';
      default: return 'Backup Now';
    }
  }

  String get later {
    switch (locale.languageCode) {
      case 'ta': return 'பின்னர்';
      case 'te': return 'తర్వాత';
      case 'hi': return 'बाद में';
      default: return 'Later';
    }
  }

  String get loans {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்கள்';
      case 'te': return 'రుణాలు';
      case 'hi': return 'ऋण';
      default: return 'loans';
    }
  }

  String get language {
    switch (locale.languageCode) {
      case 'ta': return 'மொழி';
      case 'te': return 'భాష';
      case 'hi': return 'भाषा';
      default: return 'Language';
    }
  }

  String get cancel {
    switch (locale.languageCode) {
      case 'ta': return 'ரத்து செய்';
      case 'te': return 'రద్దు చేయండి';
      case 'hi': return 'रद्द करें';
      default: return 'Cancel';
    }
  }

  String get ok {
    switch (locale.languageCode) {
      case 'ta': return 'சரி';
      case 'te': return 'సరే';
      case 'hi': return 'ठीक है';
      default: return 'OK';
    }
  }

  String get addLoanTitle {
    switch (locale.languageCode) {
      case 'ta': return 'புதிய கடன் சேர்க்க';
      case 'te': return 'కొత్త రుణాన్ని జోడించండి';
      case 'hi': return 'नया ऋण जोड़ें';
      default: return 'Add New Loan';
    }
  }

  String get editLoanTitle {
    switch (locale.languageCode) {
      case 'ta': return 'கடனைத் திருத்து';
      case 'te': return 'రుణాన్ని సవరించండి';
      case 'hi': return 'ऋण संपादित करें';
      default: return 'Edit Loan';
    }
  }

  String get loanName {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் பெயர்';
      case 'te': return 'రుణం పేరు';
      case 'hi': return 'ऋण का नाम';
      default: return 'Loan Name';
    }
  }

  String get emiAmount {
    switch (locale.languageCode) {
      case 'ta': return 'EMI தொகை';
      case 'te': return 'EMI మొత్తం';
      case 'hi': return 'EMI राशि';
      default: return 'EMI Amount';
    }
  }

  String get save {
    switch (locale.languageCode) {
      case 'ta': return 'சேமி';
      case 'te': return 'సేవ్ చేయండి';
      case 'hi': return 'सहेजें';
      default: return 'Save';
    }
  }

  String get monthlyOverview {
    switch (locale.languageCode) {
      case 'ta': return 'மாதாந்திர மேலோட்டம்';
      case 'te': return 'నెలవారీ సమీక్ష';
      case 'hi': return 'मासिक अवलोकन';
      default: return 'Monthly Overview';
    }
  }

  String get totalMonthlyEmi {
    switch (locale.languageCode) {
      case 'ta': return 'மொத்த மாதாந்திர EMI';
      case 'te': return 'మొత్తం నెలవారీ EMI';
      case 'hi': return 'कुल मासिक EMI';
      default: return 'Total Monthly EMI';
    }
  }

  String get totalLoans {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்கள்';
      case 'te': return 'రుణాలు';
      case 'hi': return 'कुल ऋण';
      default: return 'Total Loans';
    }
  }

  String get dueSoon {
    switch (locale.languageCode) {
      case 'ta': return 'விரைவில்';
      case 'te': return 'త్వరలో';
      case 'hi': return 'जल्द देय';
      default: return 'Due Soon';
    }
  }

  String get paid {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தியது';
      case 'te': return 'చెల్లించినవి';
      case 'hi': return 'भुगतान';
      default: return 'Paid';
    }
  }

  String get yourLoans {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் கடன்கள்';
      case 'te': return 'మీ రుణాలు';
      case 'hi': return 'आपके ऋण';
      default: return 'Your Loans';
    }
  }

  String get filter {
    switch (locale.languageCode) {
      case 'ta': return 'வடிகட்டி';
      case 'te': return 'ఫిల్టర్';
      case 'hi': return 'फ़िल्टर';
      default: return 'Filter';
    }
  }

  String get sortAndFilter {
    switch (locale.languageCode) {
      case 'ta': return 'வரிசை & வடிகட்டி';
      case 'te': return 'క్రమం & ఫిల్టర్';
      case 'hi': return 'क्रम & फ़िल्टर';
      default: return 'Sort & Filter';
    }
  }

  String get sortBy {
    switch (locale.languageCode) {
      case 'ta': return 'வரிசைப்படுத்து';
      case 'te': return 'క్రమం';
      case 'hi': return 'क्रमबद्ध करें';
      default: return 'SORT BY';
    }
  }

  String get filterByStatus {
    switch (locale.languageCode) {
      case 'ta': return 'நிலை வடிகட்டி';
      case 'te': return 'స్థితి ఫిల్టర్';
      case 'hi': return 'स्थिति फ़िल्टर';
      default: return 'FILTER BY STATUS';
    }
  }

  String get dueDate {
    switch (locale.languageCode) {
      case 'ta': return 'தவணை தேதி';
      case 'te': return 'గడువు తేదీ';
      case 'hi': return 'देय तिथि';
      default: return 'Due Date';
    }
  }

  String get name {
    switch (locale.languageCode) {
      case 'ta': return 'பெயர்';
      case 'te': return 'పేరు';
      case 'hi': return 'नाम';
      default: return 'Name';
    }
  }

  String get amount {
    switch (locale.languageCode) {
      case 'ta': return 'தொகை';
      case 'te': return 'మొత్తం';
      case 'hi': return 'राशि';
      default: return 'Amount';
    }
  }

  String get all {
    switch (locale.languageCode) {
      case 'ta': return 'அனைத்தும்';
      case 'te': return 'అన్నీ';
      case 'hi': return 'सभी';
      default: return 'All';
    }
  }

  String get unpaid {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தாதவை';
      case 'te': return 'చెల్లించనివి';
      case 'hi': return 'अवैतनिक';
      default: return 'Unpaid';
    }
  }

  String get reset {
    switch (locale.languageCode) {
      case 'ta': return 'மீட்டமை';
      case 'te': return 'రీసెట్';
      case 'hi': return 'रीसेट';
      default: return 'Reset';
    }
  }

  String get done {
    switch (locale.languageCode) {
      case 'ta': return 'முடிந்தது';
      case 'te': return 'పూర్తి';
      case 'hi': return 'हो गया';
      default: return 'Done';
    }
  }


  String get addYourFirstLoan {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் முதல் கடனைச் சேர்க்கவும்\nஉங்கள் EMI-ஐக் கண்காணிக்கத் தொடங்குங்கள்';
      case 'te': return 'మీ మొదటి రుణాన్ని జోడించండి\nమీ EMI చెల్లింపులను ట్రాక్ చేయడం ప్రారంభించండి';
      case 'hi': return 'अपना पहला ऋण जोड़ें\nअपने EMI भुगतान को ट्रैक करना शुरू करें';
      default: return 'Add your first loan to start tracking\nyour EMI payments';
    }
  }

  String get loanType {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் வகை';
      case 'te': return 'రుణ రకం';
      case 'hi': return 'ऋण का प्रकार';
      default: return 'Loan Type';
    }
  }

  String get homeLoan {
    switch (locale.languageCode) {
      case 'ta': return 'வீட்டுக் கடன்';
      case 'te': return 'గృహ రుణం';
      case 'hi': return 'गृह ऋण';
      default: return 'Home Loan';
    }
  }

  String get carLoan {
    switch (locale.languageCode) {
      case 'ta': return 'வாகனக் கடன்';
      case 'te': return 'వాహన రుణం';
      case 'hi': return 'कार ऋण';
      default: return 'Car Loan';
    }
  }

  String get personalLoan {
    switch (locale.languageCode) {
      case 'ta': return 'தனிநபர் கடன்';
      case 'te': return 'వ్యక్తిగత రుణం';
      case 'hi': return 'व्यक्तिगत ऋण';
      default: return 'Personal Loan';
    }
  }

  String get educationLoan {
    switch (locale.languageCode) {
      case 'ta': return 'கல்விக் கடன்';
      case 'te': return 'విద్యా రుణం';
      case 'hi': return 'शिक्षा ऋण';
      default: return 'Education Loan';
    }
  }

  String get businessLoan {
    switch (locale.languageCode) {
      case 'ta': return 'தொழில் கடன்';
      case 'te': return 'వ్యాపార రుణం';
      case 'hi': return 'व्यापार ऋण';
      default: return 'Business Loan';
    }
  }

  String get goldLoan {
    switch (locale.languageCode) {
      case 'ta': return 'நகைக்கடன்';
      case 'te': return 'బంగారు రుణం';
      case 'hi': return 'स्वर्ण ऋण';
      default: return 'Gold Loan';
    }
  }

  String get creditCard {
    switch (locale.languageCode) {
      case 'ta': return 'கிரெடிட் கார்டு';
      case 'te': return 'క్రెడిట్ కార్డ్';
      case 'hi': return 'क्रेडिट कार्ड';
      default: return 'Credit Card';
    }
  }

  String get other {
    switch (locale.languageCode) {
      case 'ta': return 'இதர';
      case 'te': return 'ఇతర';
      case 'hi': return 'अन्य';
      default: return 'Other';
    }
  }

  String get loanDetails {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் விவரங்கள்';
      case 'te': return 'రుణ వివరాలు';
      case 'hi': return 'ऋण विवरण';
      default: return 'Loan Details';
    }
  }

  String get loanAmount {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் தொகை';
      case 'te': return 'రుణ మొత్తం';
      case 'hi': return 'ऋण राशि';
      default: return 'Loan Amount';
    }
  }

  String get interestRate {
    switch (locale.languageCode) {
      case 'ta': return 'வட்டி விகிதம்';
      case 'te': return 'వడ్డీ రేటు';
      case 'hi': return 'ब्याज दर';
      default: return 'Interest Rate';
    }
  }

  String get tenure {
    switch (locale.languageCode) {
      case 'ta': return 'கால அளவு (மாதங்கள்)';
      case 'te': return 'వ్యవధి (నెలలు)';
      case 'hi': return 'अवधि (महीने)';
      default: return 'Tenure (Months)';
    }
  }

  String get paymentSchedule {
    switch (locale.languageCode) {
      case 'ta': return 'பணம் செலுத்தும் அட்டவணை';
      case 'te': return 'చెల్లింపు షెడ్యూల్';
      case 'hi': return 'भुगतान अनुसूची';
      default: return 'Payment Schedule';
    }
  }

  String get dueDay {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்த வேண்டிய நாள்';
      case 'te': return 'గడువు తేదీ';
      case 'hi': return 'नियत दिन';
      default: return 'Due Day';
    }
  }

  String get startDate {
    switch (locale.languageCode) {
      case 'ta': return 'தொடக்க தேதி';
      case 'te': return 'ప్రారంభ తేదీ';
      case 'hi': return 'प्रारंभ तिथि';
      default: return 'Start Date';
    }
  }

  String get additionalDetails {
    switch (locale.languageCode) {
      case 'ta': return 'கூடுதல் விவரங்கள் (விருப்பமானது)';
      case 'te': return 'అదనపు వివరాలు (ఐచ్ఛికం)';
      case 'hi': return 'अतिरिक्त विवरण (वैकल्पिक)';
      default: return 'Additional Details (Optional)';
    }
  }

  String get notes {
    switch (locale.languageCode) {
      case 'ta': return 'குறிப்புகள்';
      case 'te': return 'గమనికలు';
      case 'hi': return 'नोट्स';
      default: return 'Notes';
    }
  }

  String get selectCurrency {
    switch (locale.languageCode) {
      case 'ta': return 'நாணயத்தைத் தேர்ந்தெடுக்கவும்';
      case 'te': return 'కరెన్సీని ఎంచుకోండి';
      case 'hi': return 'मुद्रा चुनें';
      default: return 'Select Currency';
    }
  }

  String get appTitle {
    switch (locale.languageCode) {
      case 'ta': return 'EMI நினைவூட்டல்';
      case 'te': return 'EMI రిమైండర్';
      case 'hi': return 'EMI रिमाइंडर';
      default: return 'EMI Reminder';
    }
  }

  String get trackYourEmiPayments {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் EMI பணப்பரிமாற்றங்களைக் கண்காணிக்கவும்';
      case 'te': return 'మీ EMI చెల్లింపులను ట్రాక్ చేయండి';
      case 'hi': return 'अपने EMI भुगतान को ट्रैक करें';
      default: return 'Track your EMI payments';
    }
  }

  String get updateLoanDetails {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் விவரங்களைப் புதுப்பிக்கவும்';
      case 'te': return 'రుణ వివరాలను అప్‌డేట్ చేయండి';
      case 'hi': return 'ऋण विवरण अपडेट करें';
      default: return 'Update loan details';
    }
  }

  String get notificationSettings {
    switch (locale.languageCode) {
      case 'ta': return 'அறிவிப்பு அமைப்புகள்';
      case 'te': return 'నోటిఫికేషన్ సెట్టింగ్‌లు';
      case 'hi': return 'अधिसूचना सेटिंग्स';
      default: return 'Notification Settings';
    }
  }

  String get notifications {
    switch (locale.languageCode) {
      case 'ta': return 'அறிவிப்புகள்';
      case 'te': return 'నోటిఫికేషన్లు';
      case 'hi': return 'सूचनाएं';
      default: return 'Notifications';
    }
  }

  String get exactAlarms {
    switch (locale.languageCode) {
      case 'ta': return 'துல்லியமான அலாரங்கள்';
      case 'te': return 'ఖచ్చితమైన అలారాలు';
      case 'hi': return 'सटीक अलार्म';
      default: return 'Exact Alarms';
    }
  }

  String get enabled {
    switch (locale.languageCode) {
      case 'ta': return 'இயக்கப்பட்டது';
      case 'te': return 'ప్రారంభించబడింది';
      case 'hi': return 'सक्षम';
      default: return 'Enabled';
    }
  }

  String get pendingReminders {
    switch (locale.languageCode) {
      case 'ta': return 'நிலுவையில் உள்ள நினைவூட்டல்கள்';
      case 'te': return 'పెండింగ్ రిమైండర్లు';
      case 'hi': return 'लंबित रिमाइंडर';
      default: return 'Pending Reminders';
    }
  }

  String get notificationsScheduled {
    switch (locale.languageCode) {
      case 'ta': return 'அறிவிப்புகள் திட்டமிடப்பட்டன';
      case 'te': return 'నోటిఫికేషన్లు షెడ్యూల్ చేయబడ్డాయి';
      case 'hi': return 'सूचनाएं शेड्यूल की गईं';
      default: return 'notifications scheduled';
    }
  }

  String get disabled {
    switch (locale.languageCode) {
      case 'ta': return 'முடக்கப்பட்டது';
      case 'te': return 'నిలిపివేయబడింది';
      case 'hi': return 'अक्षम';
      default: return 'Disabled';
    }
  }

  String get noRemindersScheduled {
    switch (locale.languageCode) {
      case 'ta': return 'நினைவூட்டல்கள் திட்டமிடப்படவில்லை';
      case 'te': return 'రిమైండర్లు షెడ్యూల్ చేయబడలేదు';
      case 'hi': return 'कोई रिमाइंडर शेड्यूल नहीं';
      default: return 'No reminders scheduled';
    }
  }

  String get openAppSettings {
    switch (locale.languageCode) {
      case 'ta': return 'ஆப் அமைப்புகளைத் திற';
      case 'te': return 'యాప్ సెట్టింగ్‌లను తెరవండి';
      case 'hi': return 'ऐप सेटिंग्स खोलें';
      default: return 'Open App Settings';
    }
  }

  String get manageNotificationPreferences {
    switch (locale.languageCode) {
      case 'ta': return 'அறிவிப்பு விருப்பங்களை நிர்வகிக்கவும்';
      case 'te': return 'నోటిఫికేషన్ ప్రాధాన్యతలను నిర్వహించండి';
      case 'hi': return 'अधिसूचना प्राथमिकताएं प्रबंधित करें';
      default: return 'Manage notification preferences';
    }
  }

  String get ensureYouReceiveReminders {
    switch (locale.languageCode) {
      case 'ta': return 'செயலி மூடப்பட்டிருந்தாலும் நினைவூட்டல்களைப் பெறுவதை உறுதிசெய்க';
      case 'te': return 'యాప్ మూసివేసినా రిమైండర్‌లను పొందేలా చూసుకోండి';
      case 'hi': return 'सुनिश्चित करें कि ऐप बंद होने पर भी आपको रिमाइंडर मिलें';
      default: return 'Ensure you receive EMI reminders even when app is closed';
    }
  }

  String get settings_header {
    switch (locale.languageCode) {
      case 'ta': return '⚙️ அமைப்புகள்';
      case 'te': return '⚙️ సెట్టింగ్‌లు';
      case 'hi': return '⚙️ सेटिंग्स';
      default: return '⚙️ Settings';
    }
  }

  String get tapToChangeAppLanguage {
    switch (locale.languageCode) {
      case 'ta': return 'மொழியை மாற்ற இங்கே தட்டவும்';
      case 'te': return 'యాప్ భాషను మార్చడానికి ట్యాప్ చేయండి';
      case 'hi': return 'ऐप की भाषा बदलने के लिए टैप करें';
      default: return 'Tap to change app language';
    }
  }


  String get englishLanguage {
    switch (locale.languageCode) {
      case 'ta': return 'ஆங்கிலம்';
      case 'te': return 'ఇంగ్లీష్';
      case 'hi': return 'अंग्रेज़ी';
      default: return 'English';
    }
  }

  String get tamilLanguage {
    switch (locale.languageCode) {
      case 'ta': return 'தமிழ்';
      case 'te': return 'తమిళం';
      case 'hi': return 'तमिल';
      default: return 'Tamil';
    }
  }

  String get teluguLanguage {
    switch (locale.languageCode) {
      case 'ta': return 'தெலுங்கு';
      case 'te': return 'తెలుగు';
      case 'hi': return 'तेलुगु';
      default: return 'Telugu';
    }
  }

  String get hindiLanguage {
    switch (locale.languageCode) {
      case 'ta': return 'இந்தி';
      case 'te': return 'హిందీ';
      case 'hi': return 'हिंदी';
      default: return 'Hindi';
    }
  }

  String get monthlyEmi {
    switch (locale.languageCode) {
      case 'ta': return 'மாதாந்திர EMI';
      case 'te': return 'నెలసరి EMI';
      case 'hi': return 'मासिक EMI';
      default: return 'Monthly EMI';
    }
  }

  String get nextDue {
    switch (locale.languageCode) {
      case 'ta': return 'அடுத்த தவணை';
      case 'te': return 'తదుపరి గడువు';
      case 'hi': return 'अगला देय';
      default: return 'Next Due';
    }
  }

  String get daysUntilDue {
    switch (locale.languageCode) {
      case 'ta': return 'தவணைக்கு இன்னும் உள்ள நாட்கள்';
      case 'te': return 'గడువు వరకు ఉన్న రోజులు';
      case 'hi': return 'देय होने तक दिन';
      default: return 'Days Until Due';
    }
  }

  String get today {
    switch (locale.languageCode) {
      case 'ta': return 'இன்று';
      case 'te': return 'ఈ రోజు';
      case 'hi': return 'आज';
      default: return 'Today';
    }
  }

  String get overdue {
    switch (locale.languageCode) {
      case 'ta': return 'தாமதமானது';
      case 'te': return 'గడువు ముగిసింది';
      case 'hi': return 'अतिदेय';
      default: return 'Overdue';
    }
  }

  String get days {
    switch (locale.languageCode) {
      case 'ta': return 'நாட்கள்';
      case 'te': return 'రోజులు';
      case 'hi': return 'दिन';
      default: return 'days';
    }
  }

  String get dueDay_label {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்த வேண்டிய நாள்';
      case 'te': return 'గడువు రోజు';
      case 'hi': return 'देय दिन';
      default: return 'Due Day';
    }
  }

  String get everyMonth {
    switch (locale.languageCode) {
      case 'ta': return 'ஒவ்வொரு மாதமும்';
      case 'te': return 'ప్రతి నెల';
      case 'hi': return 'हर महीने';
      default: return 'every month';
    }
  }

  String get loanDetails_header {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் விவரங்கள்';
      case 'te': return 'రుణ వివరాలు';
      case 'hi': return 'ऋण विवरण';
      default: return 'Loan Details';
    }
  }

  String get startDate_label {
    switch (locale.languageCode) {
      case 'ta': return 'தொடக்க தேதி';
      case 'te': return 'ప్రారంభ తేదీ';
      case 'hi': return 'प्रारंभ तिथि';
      default: return 'Start Date';
    }
  }

  String get loanAmount_label {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் தொகை';
      case 'te': return 'రుణ మొత్తం';
      case 'hi': return 'ऋण राशि';
      default: return 'Loan Amount';
    }
  }

  String get interestRate_label {
    switch (locale.languageCode) {
      case 'ta': return 'வட்டி விகிதம்';
      case 'te': return 'వడ్డీ రేటు';
      case 'hi': return 'ब्याज दर';
      default: return 'Interest Rate';
    }
  }

  String get perAnnum {
    switch (locale.languageCode) {
      case 'ta': return 'ஆண்டுக்கு';
      case 'te': return 'సంవత్సరానికి';
      case 'hi': return 'प्रति वर्ष';
      default: return 'p.a.';
    }
  }

  String get tenure_label {
    switch (locale.languageCode) {
      case 'ta': return 'கால அளவு';
      case 'te': return 'వ్యవధి';
      case 'hi': return 'अवधि';
      default: return 'Tenure';
    }
  }

  String get months {
    switch (locale.languageCode) {
      case 'ta': return 'மாதங்கள்';
      case 'te': return 'నెలలు';
      case 'hi': return 'महीने';
      default: return 'months';
    }
  }

  String get notes_label {
    switch (locale.languageCode) {
      case 'ta': return 'குறிப்புகள்';
      case 'te': return 'గమనికలు';
      case 'hi': return 'नोट्स';
      default: return 'Notes';
    }
  }

  String get edit {
    switch (locale.languageCode) {
      case 'ta': return 'திருத்து';
      case 'te': return 'సవరించు';
      case 'hi': return 'संपादन';
      default: return 'Edit';
    }
  }

  String get delete {
    switch (locale.languageCode) {
      case 'ta': return 'நீக்கு';
      case 'te': return 'తొలగించు';
      case 'hi': return 'हटाएं';
      default: return 'Delete';
    }
  }

  String get loanDetails_title {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் விவரங்கள்';
      case 'te': return 'రుణ వివరాలు';
      case 'hi': return 'ऋण विवरण';
      default: return 'Loan Details';
    }
  }

  String get overallProgress {
    switch (locale.languageCode) {
      case 'ta': return 'மொத்த முன்னேற்றம்';
      case 'te': return 'మొత్తం పురోగతి';
      case 'hi': return 'कुल प्रगति';
      default: return 'Overall Progress';
    }
  }

  String get loanWiseProgress {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் வாரியான முன்னேற்றம்';
      case 'te': return 'రుణం వారీగా పురోగతి';
      case 'hi': return 'ऋण-वार प्रगति';
      default: return 'Loan-wise Progress';
    }
  }

  String get totalEMI {
    switch (locale.languageCode) {
      case 'ta': return 'மொத்த EMI';
      case 'te': return 'మొత్తం EMI';
      case 'hi': return 'कुल EMI';
      default: return 'Total EMI';
    }
  }

  String get paidEMI {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தப்பட்ட EMI';
      case 'te': return 'చెల్లించిన EMI';
      case 'hi': return 'भुगतान की गई EMI';
      default: return 'Paid EMI';
    }
  }

  String get remaining {
    switch (locale.languageCode) {
      case 'ta': return 'மீதமுள்ளவை';
      case 'te': return 'మిగిలి ఉన్నవి';
      case 'hi': return 'शेष';
      default: return 'Remaining';
    }
  }

  String get status {
    switch (locale.languageCode) {
      case 'ta': return 'நிலை';
      case 'te': return 'స్థితి';
      case 'hi': return 'स्थिति';
      default: return 'Status';
    }
  }

  String get active {
    switch (locale.languageCode) {
      case 'ta': return 'செயலில் உள்ளது';
      case 'te': return 'క్రియాశీలకంగా ఉంది';
      case 'hi': return 'सक्रिय';
      default: return 'Active';
    }
  }

  String get completed {
    switch (locale.languageCode) {
      case 'ta': return 'முடிந்தது';
      case 'te': return 'పూర్తయింది';
      case 'hi': return 'पूर्ण';
      default: return 'Completed';
    }
  }

  String get dueIn {
    switch (locale.languageCode) {
      case 'ta': return 'இன்னும்';
      case 'te': return 'గడువు ఇంకా';
      case 'hi': return 'बाकी समय';
      default: return 'Due In';
    }
  }

  // Loan Card Status Strings
  String get paidStatus {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தப்பட்டது';
      case 'te': return 'చెల్లించబడింది';
      case 'hi': return 'भुगतान किया';
      default: return 'PAID';
    }
  }

  String get overdueStatus {
    switch (locale.languageCode) {
      case 'ta': return 'தாமதமானது';
      case 'te': return 'గడువు మించినది';
      case 'hi': return 'अतिदेय';
      default: return 'OVERDUE';
    }
  }

  String get dueTodayStatus {
    switch (locale.languageCode) {
      case 'ta': return 'இன்று செலுத்த வேண்டும்';
      case 'te': return 'ఈరోజే గడువు';
      case 'hi': return 'आज देय';
      default: return 'DUE TODAY';
    }
  }

  String get dueTomorrowStatus {
    switch (locale.languageCode) {
      case 'ta': return 'நாளை செலுத்த வேண்டும்';
      case 'te': return 'రేపే గడువు';
      case 'hi': return 'कल देय';
      default: return 'DUE TOMORROW';
    }
  }

  String get dueSoonStatus {
    switch (locale.languageCode) {
      case 'ta': return 'விரைவில் செலுத்த வேண்டும்';
      case 'te': return 'త్వరలో గడువు';
      case 'hi': return 'जल्द देय';
      default: return 'DUE SOON';
    }
  }

  String get thisWeekStatus {
    switch (locale.languageCode) {
      case 'ta': return 'இந்த வாரம்';
      case 'te': return 'ఈ వారం';
      case 'hi': return 'इस सप्ताह';
      default: return 'THIS WEEK';
    }
  }

  String get upcomingStatus {
    switch (locale.languageCode) {
      case 'ta': return 'வரவிருப்பவை';
      case 'te': return 'రాబోయేవి';
      case 'hi': return 'आगामी';
      default: return 'UPCOMING';
    }
  }

  String get nextDueLabel {
    switch (locale.languageCode) {
      case 'ta': return 'அடுத்த தவணை';
      case 'te': return 'తదుపరి గడువు';
      case 'hi': return 'अगला देय';
      default: return 'Next Due';
    }
  }

  String get overdueLabel {
    switch (locale.languageCode) {
      case 'ta': return 'தாமதமானது';
      case 'te': return 'గడువు మించినది';
      case 'hi': return 'अतिदेय';
      default: return 'Overdue';
    }
  }

  String get dueLabel {
    switch (locale.languageCode) {
      case 'ta': return 'தவணை';
      case 'te': return 'గడువు';
      case 'hi': return 'देय';
      default: return 'Due';
    }
  }

  String get daysOverdue {
    switch (locale.languageCode) {
      case 'ta': return 'நாட்கள் தாமதம்';
      case 'te': return 'రోజులు గడువు మించాయి';
      case 'hi': return 'दिन अतिदेय';
      default: return 'days overdue';
    }
  }

  String get dueTodayLabel {
    switch (locale.languageCode) {
      case 'ta': return 'இன்று செலுத்த வேண்டும்';
      case 'te': return 'ఈరోజే గడువు';
      case 'hi': return 'आज देय';
      default: return 'Due today';
    }
  }

  String get dueTomorrowLabel {
    switch (locale.languageCode) {
      case 'ta': return 'நாளை செலுத்த வேண்டும்';
      case 'te': return 'రేపే గడువు';
      case 'hi': return 'कल देय';
      default: return 'Due tomorrow';
    }
  }

  String get daysLeft {
    switch (locale.languageCode) {
      case 'ta': return 'நாட்கள் மீதம்';
      case 'te': return 'రోజులు మిగిలి ఉన్నాయి';
      case 'hi': return 'दिन बाकी';
      default: return 'days left';
    }
  }

  String get nextIn {
    switch (locale.languageCode) {
      case 'ta': return 'அடுத்தது';
      case 'te': return 'తదుపరి';
      case 'hi': return 'अगले';
      default: return 'Next in';
    }
  }

  String get markPaid {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தப்பட்டதாகக் குறி';
      case 'te': return 'చెల్లించినట్లు గుర్తించు';
      case 'hi': return 'भुगतान किया गया चिह्नित करें';
      default: return 'Mark Paid';
    }
  }

  String get markUnpaid {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தப்படாததாகக் குறி';
      case 'te': return 'చెల్లించనిదిగా గుర్తించు';
      case 'hi': return 'अवैतनिक चिह्नित करें';
      default: return 'Mark Unpaid';
    }
  }

  String get viewDetails {
    switch (locale.languageCode) {
      case 'ta': return 'விவரங்களைப் பார்';
      case 'te': return 'వివరాలు చూడండి';
      case 'hi': return 'विवरण देखें';
      default: return 'View Details';
    }
  }

  // EMI Progress Screen
  String get emiProgress {
    switch (locale.languageCode) {
      case 'ta': return 'EMI முன்னேற்றம்';
      case 'te': return 'EMI పురోగతి';
      case 'hi': return 'EMI प्रगति';
      default: return 'EMI Progress';
    }
  }

  String get refresh {
    switch (locale.languageCode) {
      case 'ta': return 'புதுப்பி';
      case 'te': return 'రిఫ్రెష్';
      case 'hi': return 'रिफ्रेश';
      default: return 'Refresh';
    }
  }

  String get noLoansToTrack {
    switch (locale.languageCode) {
      case 'ta': return 'கண்காணிக்கக் கடன்கள் இல்லை';
      case 'te': return 'ట్రాక్ చేయడానికి రుణాలు లేవు';
      case 'hi': return 'ट्रैक करने के लिए कोई ऋण नहीं';
      default: return 'No loans to track';
    }
  }

  String get addLoanToSeeProgress {
    switch (locale.languageCode) {
      case 'ta': return 'முன்னேற்றத்தைப் பார்க்கக் கடனைச் சேர்க்கவும்';
      case 'te': return 'పురోగతిని చూడటానికి రుణాన్ని జోడించండి';
      case 'hi': return 'प्रगति देखने के लिए ऋण जोड़ें';
      default: return 'Add a loan to see your progress';
    }
  }

  String get emisPaid {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்தப்பட்ட தவணைகள்';
      case 'te': return 'చెల్లించిన EMIలు';
      case 'hi': return 'चुकाई गई EMIs';
      default: return 'EMIs Paid';
    }
  }

  String get emisLeft {
    switch (locale.languageCode) {
      case 'ta': return 'மீதமுள்ள தவணைகள்';
      case 'te': return 'మిగిలిన EMIలు';
      case 'hi': return 'शेष EMIs';
      default: return 'EMIs Left';
    }
  }

  String get perMonth {
    switch (locale.languageCode) {
      case 'ta': return 'மாதத்திற்கு';
      case 'te': return 'నెలకు';
      case 'hi': return 'प्रति माह';
      default: return 'per month';
    }
  }

  String get month {
    switch (locale.languageCode) {
      case 'ta': return 'மாதம்';
      case 'te': return 'నెల';
      case 'hi': return 'महीना';
      default: return 'month';
    }
  }

  // Loan Actions
  String get editLoan {
    switch (locale.languageCode) {
      case 'ta': return 'கடனைத் திருத்து';
      case 'te': return 'రుణాన్ని సవరించండి';
      case 'hi': return 'ऋण संपादित करें';
      default: return 'Edit Loan';
    }
  }

  String get modifyLoanDetails {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் விவரங்களை மாற்றவும்';
      case 'te': return 'రుణ వివరాలను మార్చండి';
      case 'hi': return 'ऋण विवरण संशोधित करें';
      default: return 'Modify loan details';
    }
  }

  String get recordThisMonthsPayment {
    switch (locale.languageCode) {
      case 'ta': return 'இந்த மாதப் பணப்பரிமாற்றத்தைப் பதிவு செய்க';
      case 'te': return 'ఈ నెల చెల్లింపును రికార్డ్ చేయండి';
      case 'hi': return 'इस महीने का भुगतान रिकॉर्ड करें';
      default: return 'Record this month\'s payment';
    }
  }

  String get testNotification {
    switch (locale.languageCode) {
      case 'ta': return 'சோதனை அறிவிப்பு';
      case 'te': return 'టెస్ట్ నోటిఫికేషన్';
      case 'hi': return 'टेस्ट नोटिफिकेशन';
      default: return 'Test Notification';
    }
  }

  String get sendTestReminder {
    switch (locale.languageCode) {
      case 'ta': return 'சோதனை நினைவூட்டலை அனுப்பு';
      case 'te': return 'టెస్ట్ రిమైండర్ పంపండి';
      case 'hi': return 'टेस्ट रिमाइंडर भेजें';
      default: return 'Send a test reminder';
    }
  }

  String get testNotificationSent {
    switch (locale.languageCode) {
      case 'ta': return 'சோதனை அறிவிப்பு அனுப்பப்பட்டது!';
      case 'te': return 'టెస్ట్ నోటిఫికేషన్ పంపబడింది!';
      case 'hi': return 'टेस्ट नोटिफिकेशन भेजा गया!';
      default: return 'Test notification sent!';
    }
  }

  String get deleteLoan {
    switch (locale.languageCode) {
      case 'ta': return 'கடனை நீக்கு';
      case 'te': return 'రుణాన్ని తొలగించండి';
      case 'hi': return 'ऋण हटाएं';
      default: return 'Delete Loan';
    }
  }

  String get removeThisLoanPermanently {
    switch (locale.languageCode) {
      case 'ta': return 'இந்தக் கடனை நிரந்தரமாக நீக்கு';
      case 'te': return 'ఈ రుణాన్ని శాశ్వతంగా తొలగించండి';
      case 'hi': return 'इस ऋण को स्थायी रूप से हटाएं';
      default: return 'Remove this loan permanently';
    }
  }

  String get noLoansMatchFilter {
    switch (locale.languageCode) {
      case 'ta': return 'வடிகட்டிக்கு ஏற்ற கடன்கள் இல்லை';
      case 'te': return 'ఫిల్టర్‌కు సరిపోయే రుణాలు లేవు';
      case 'hi': return 'फ़िल्टर से मेल खाने वाले कोई ऋण नहीं';
      default: return 'No loans match your filter';
    }
  }

  String get clearFilters {
    switch (locale.languageCode) {
      case 'ta': return 'வடிகட்டிகளை அகற்று';
      case 'te': return 'ఫిల్టర్లను క్లియర్ చేయండి';
      case 'hi': return 'फ़िल्टर साफ़ करें';
      default: return 'Clear Filters';
    }
  }

  String get loanSummary {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் சுருக்கம்';
      case 'te': return 'రుణ సారాంశం';
      case 'hi': return 'ऋण सारांश';
      default: return 'Loan Summary';
    }
  }

  String get totalPayment {
    switch (locale.languageCode) {
      case 'ta': return 'மொத்த தொகை';
      case 'te': return 'మొత్తం చెల్లింపు';
      case 'hi': return 'कुल भुगतान';
      default: return 'Total Payment';
    }
  }

  String get home {
    switch (locale.languageCode) {
      case 'ta': return 'வீடு';
      case 'te': return 'ఇల్లు';
      case 'hi': return 'घर';
      default: return 'Home';
    }
  }

  String get car {
    switch (locale.languageCode) {
      case 'ta': return 'வாகனம்';
      case 'te': return 'వాహనం';
      case 'hi': return 'गाड़ी';
      default: return 'Car';
    }
  }

  String get personal {
    switch (locale.languageCode) {
      case 'ta': return 'தனிநபர்';
      case 'te': return 'వ్యక్తిగత';
      case 'hi': return 'व्यक्तिगत';
      default: return 'Personal';
    }
  }

  String get education {
    switch (locale.languageCode) {
      case 'ta': return 'கல்வி';
      case 'te': return 'విద్య';
      case 'hi': return 'शिक्षा';
      default: return 'Education';
    }
  }

  String get business {
    switch (locale.languageCode) {
      case 'ta': return 'வணிகம்';
      case 'te': return 'వ్యాపారం';
      case 'hi': return 'व्यापार';
      default: return 'Business';
    }
  }

  String get gold {
    switch (locale.languageCode) {
      case 'ta': return 'தங்கம்';
      case 'te': return 'బంగారం';
      case 'hi': return 'सोना';
      default: return 'Gold';
    }
  }

  String get credit {
    switch (locale.languageCode) {
      case 'ta': return 'கிரெடிட்';
      case 'te': return 'క్రెడిట్';
      case 'hi': return 'क्रेडिट';
      default: return 'Credit';
    }
  }

  // EMI Calculator Screen
  String get calculateYourLoanEmi {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் கடன் EMI-ஐ கணக்கிடுங்கள்';
      case 'te': return 'మీ రుణ EMIని లెక్కించండి';
      case 'hi': return 'अपना ऋण EMI गणना करें';
      default: return 'Calculate your loan EMI';
    }
  }

  String get enterLoanDetails {
    switch (locale.languageCode) {
      case 'ta': return 'கடன் விவரங்களை உள்ளிடவும்';
      case 'te': return 'రుణ వివరాలను నమోదు చేయండి';
      case 'hi': return 'ऋण विवरण दर्ज करें';
      default: return 'Enter Loan Details';
    }
  }

  String get loanAmountHint {
    switch (locale.languageCode) {
      case 'ta': return 'எ.கா., 5,00,000';
      case 'te': return 'ఉదా., 5,00,000';
      case 'hi': return 'उदा., 5,00,000';
      default: return 'e.g., 5,00,000';
    }
  }

  String get interestRatePerAnnum {
    switch (locale.languageCode) {
      case 'ta': return 'வட்டி விகிதம் (% ஆண்டுக்கு)';
      case 'te': return 'వడ్డీ రేటు (% సంవత్సరానికి)';
      case 'hi': return 'ब्याज दर (% प्रति वर्ष)';
      default: return 'Interest Rate (% per annum)';
    }
  }

  String get tenureMonthsLabel {
    switch (locale.languageCode) {
      case 'ta': return 'கால அளவு (மாதங்கள்)';
      case 'te': return 'వ్యవధి (నెలలు)';
      case 'hi': return 'अवधि (महीने)';
      default: return 'Tenure (Months)';
    }
  }

  String get calculate {
    switch (locale.languageCode) {
      case 'ta': return 'கணக்கிடு';
      case 'te': return 'లెక్కించు';
      case 'hi': return 'गणना करें';
      default: return 'Calculate';
    }
  }


  String get emiResults {
    switch (locale.languageCode) {
      case 'ta': return 'EMI முடிவுகள்';
      case 'te': return 'EMI ఫలితాలు';
      case 'hi': return 'EMI परिणाम';
      default: return 'EMI Results';
    }
  }

  String get monthlyEmiLabel {
    switch (locale.languageCode) {
      case 'ta': return 'மாதாந்திர EMI';
      case 'te': return 'నెలసరి EMI';
      case 'hi': return 'मासिक EMI';
      default: return 'Monthly EMI';
    }
  }

  String get totalInterest {
    switch (locale.languageCode) {
      case 'ta': return 'மொத்த வட்டி';
      case 'te': return 'మొత్తం వడ్డీ';
      case 'hi': return 'कुल ब्याज';
      default: return 'Total Interest';
    }
  }

  String get totalAmountPayable {
    switch (locale.languageCode) {
      case 'ta': return 'செலுத்த வேண்டிய மொத்த தொகை';
      case 'te': return 'చెల్లించాల్సిన మొత్తం';
      case 'hi': return 'कुल देय राशि';
      default: return 'Total Amount Payable';
    }
  }

  String get principalAmount {
    switch (locale.languageCode) {
      case 'ta': return 'அசல் தொகை';
      case 'te': return 'అసలు మొత్తం';
      case 'hi': return 'मूल राशि';
      default: return 'Principal Amount';
    }
  }

  String get pleaseEnterValidAmount {
    switch (locale.languageCode) {
      case 'ta': return 'சரியான தொகையை உள்ளிடவும்';
      case 'te': return 'సరైన మొత్తం నమోదు చేయండి';
      case 'hi': return 'कृपया सही राशि दर्ज करें';
      default: return 'Please enter a valid amount';
    }
  }

  String get pleaseEnterValidRate {
    switch (locale.languageCode) {
      case 'ta': return 'சரியான வட்டி விகிதத்தை உள்ளிடவும்';
      case 'te': return 'సరైన వడ్డీ రేటు నమోదు చేయండి';
      case 'hi': return 'कृपया सही ब्याज दर दर्ज करें';
      default: return 'Please enter a valid interest rate';
    }
  }

  String get pleaseEnterValidTenure {
    switch (locale.languageCode) {
      case 'ta': return 'சரியான கால அளவை உள்ளிடவும்';
      case 'te': return 'సరైన వ్యవధి నమోదు చేయండి';
      case 'hi': return 'कृपया सही अवधि दर्ज करें';
      default: return 'Please enter a valid tenure';
    }
  }

  // Compound Interest
  String get compound {
    switch (locale.languageCode) {
      case 'ta': return 'கூட்டு வட்டி';
      case 'te': return 'సమ్మేళన వడ్డీ';
      case 'hi': return 'चक्रवृद्धि ब्याज';
      default: return 'Compound';
    }
  }

  String get yearsLabel {
    switch (locale.languageCode) {
      case 'ta': return 'ஆண்டுகள்';
      case 'te': return 'సంవత్సరాలు';
      case 'hi': return 'वर्ष';
      default: return 'Years';
    }
  }

  String get compoundsPerYear {
    switch (locale.languageCode) {
      case 'ta': return 'ஆண்டுக்கு கூட்டும் முறை';
      case 'te': return 'సంవత్సరానికి సమ్మేళనం';
      case 'hi': return 'प्रति वर्ष चक्रवृद्धि';
      default: return 'Compounds per Year';
    }
  }

  String get futureValue {
    switch (locale.languageCode) {
      case 'ta': return 'எதிர்கால மதிப்பு';
      case 'te': return 'భవిష్యత్తు విలువ';
      case 'hi': return 'भविष्य मूल्य';
      default: return 'Future Value';
    }
  }

  // SIP
  String get sipCalculator {
    switch (locale.languageCode) {
      case 'ta': return 'SIP கணக்கிடு';
      case 'te': return 'SIP కాలిక్యులేటర్';
      case 'hi': return 'SIP कैलकुलेटर';
      default: return 'SIP Calculator';
    }
  }

  String get monthlyInvestment {
    switch (locale.languageCode) {
      case 'ta': return 'மாதாந்திர முதலீடு';
      case 'te': return 'నెలసరి పెట్టుబడి';
      case 'hi': return 'मासिक निवेश';
      default: return 'Monthly Investment';
    }
  }

  String get investmentPeriodMonths {
    switch (locale.languageCode) {
      case 'ta': return 'முதலீட்டு காலம் (மாதங்கள்)';
      case 'te': return 'పెట్టుబడి కాలం (నెలలు)';
      case 'hi': return 'निवेश अवधि (महीने)';
      default: return 'Investment Period (Months)';
    }
  }

  String get missedMonths {
    switch (locale.languageCode) {
      case 'ta': return 'தவறவிட்ட மாதங்கள்';
      case 'te': return 'మిస్ అయిన నెలలు';
      case 'hi': return 'छूटे हुए महीने';
      default: return 'Missed Months';
    }
  }

  String get totalInvested {
    switch (locale.languageCode) {
      case 'ta': return 'மொத்த முதலீடு';
      case 'te': return 'మొత్తం పెట్టుబడి';
      case 'hi': return 'कुल निवेश';
      default: return 'Total Invested';
    }
  }

  String get estimatedReturns {
    switch (locale.languageCode) {
      case 'ta': return 'மதிப்பிடப்பட்ட வருமானம்';
      case 'te': return 'అంచనా వేసిన రాబడి';
      case 'hi': return 'अनुमानित रिटर्न';
      default: return 'Estimated Returns';
    }
  }

  // Calendar Screen
  String get emiCalendar {
    switch (locale.languageCode) {
      case 'ta': return 'EMI நாட்காட்டி';
      case 'te': return 'EMI క్యాలెండర్';
      case 'hi': return 'EMI कैलेंडर';
      default: return 'EMI Calendar';
    }
  }

  String get trackYourEmiDueDates {
    switch (locale.languageCode) {
      case 'ta': return 'உங்கள் EMI தவணை தேதிகளை கண்காணிக்கவும்';
      case 'te': return 'మీ EMI గడువు తేదీలను ట్రాక్ చేయండి';
      case 'hi': return 'अपनी EMI देय तिथियों को ट्रैक करें';
      default: return 'Track your EMI due dates';
    }
  }

  String get loansOnThisDay {
    switch (locale.languageCode) {
      case 'ta': return 'இந்த நாளில் கடன்கள்';
      case 'te': return 'ఈ రోజున రుణాలు';
      case 'hi': return 'इस दिन के ऋण';
      default: return 'Loans on this day';
    }
  }

  String get noEmiDueOnThisDay {
    switch (locale.languageCode) {
      case 'ta': return 'இந்த நாளில் EMI தவணை இல்லை';
      case 'te': return 'ఈ రోజున EMI గడువు లేదు';
      case 'hi': return 'इस दिन कोई EMI देय नहीं';
      default: return 'No EMI due on this day';
    }
  }

  String get selectDateToViewLoans {
    switch (locale.languageCode) {
      case 'ta': return 'கடன்களைப் பார்க்க தேதியைத் தேர்ந்தெடுக்கவும்';
      case 'te': return 'రుణాలను చూడటానికి తేదీని ఎంచుకోండి';
      case 'hi': return 'ऋण देखने के लिए तारीख चुनें';
      default: return 'Select a date to view loans';
    }
  }

  // Part 2 Correction Logic Starts Here
  String getLoanTypeName(String englishName) {
    switch (englishName) {
      case 'Home Loan':
        return locale.languageCode == 'ta' ? 'வீட்டுக் கடன்'
            : locale.languageCode == 'te' ? 'గృహ రుణం'
            : locale.languageCode == 'hi' ? 'गृह ऋण'
            : 'Home Loan';
      case 'Car Loan':
        return locale.languageCode == 'ta' ? 'வாகனக் கடன்'
            : locale.languageCode == 'te' ? 'వాహన రుణం'
            : locale.languageCode == 'hi' ? 'कार ऋण'
            : 'Car Loan';
      case 'Personal Loan':
        return locale.languageCode == 'ta' ? 'தனிநபர் கடன்'
            : locale.languageCode == 'te' ? 'వ్యక్తిగత రుణం'
            : locale.languageCode == 'hi' ? 'व्यक्तिगत ऋण'
            : 'Personal Loan';
      case 'Education Loan':
        return locale.languageCode == 'ta' ? 'கல்விக் கடன்'
            : locale.languageCode == 'te' ? 'విద్యా రుణం'
            : locale.languageCode == 'hi' ? 'शिक्षा ऋण'
            : 'Education Loan';
      case 'Business Loan':
        return locale.languageCode == 'ta' ? 'தொழில் கடன்'
            : locale.languageCode == 'te' ? 'వ్యాపార రుణం'
            : locale.languageCode == 'hi' ? 'व्यापार ऋण'
            : 'Business Loan';
      case 'Gold Loan':
        return locale.languageCode == 'ta' ? 'நகைக்கடன்'
            : locale.languageCode == 'te' ? 'బంగారు రుణం'
            : locale.languageCode == 'hi' ? 'स्वर्ण ऋण'
            : 'Gold Loan';
      case 'Credit Card':
        return locale.languageCode == 'ta' ? 'கிரெடிட் கார்டு'
            : locale.languageCode == 'te' ? 'క్రెడిట్ కార్డ్'
            : locale.languageCode == 'hi' ? 'क्रेडिट कार्ड'
            : 'Credit Card';
      case 'Other':
        return locale.languageCode == 'ta' ? 'இதர'
            : locale.languageCode == 'te' ? 'ఇతర'
            : locale.languageCode == 'hi' ? 'अन्य'
            : 'Other';
      default:
        return englishName;
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ta', 'te', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}