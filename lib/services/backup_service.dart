import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import '../models/loan.dart';
import 'loan_storage_service.dart';

class BackupService {
  final LoanStorageService _storageService;

  BackupService(this._storageService);

  /// Export all loans to a JSON file and share it
  Future<String?> exportLoans() async {
    try {
      final loans = _storageService.getAllLoans();

      if (loans.isEmpty) {
        return null;
      }

      // Convert loans to JSON
      final loansJson = loans.map((loan) => _loanToJson(loan)).toList();
      final backupData = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'loans': loansJson,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Try to save to Downloads folder first, fallback to app directory
      String? savedPath;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'emi_backup_$timestamp.json';

      try {
        // Try external storage (Downloads) on Android
        final downloadDir = await getExternalStorageDirectory();
        if (downloadDir != null) {
          // Go up to root external storage and then to Download
          final pathParts = downloadDir.path.split('/');
          final androidIndex = pathParts.indexOf('Android');
          if (androidIndex > 0) {
            final downloadPath = '${pathParts.sublist(0, androidIndex).join('/')}/Download';
            final downloadFolder = Directory(downloadPath);
            if (await downloadFolder.exists()) {
              final file = File('$downloadPath/$fileName');
              await file.writeAsString(jsonString);
              savedPath = file.path;
              debugPrint('Saved to Downloads: $savedPath');
            }
          }
        }
      } catch (e) {
        debugPrint('Could not save to Downloads: $e');
      }

      // Fallback: save to app's documents directory
      if (savedPath == null) {
        final directory = await getApplicationDocumentsDirectory();
        final file = File('${directory.path}/$fileName');
        await file.writeAsString(jsonString);
        savedPath = file.path;
        debugPrint('Saved to app directory: $savedPath');
      }

      // Also share the file so user can save to Drive, etc.
      await Share.shareXFiles(
        [XFile(savedPath)],
        subject: 'EMI Reminder Backup',
        text: 'My EMI Reminder backup - ${loans.length} loans',
      );

      return savedPath;
    } catch (e) {
      debugPrint('Error exporting loans: $e');
      rethrow;
    }
  }

  /// Save backup to a user-selected location
  Future<String?> saveBackupToLocation() async {
    try {
      final loans = _storageService.getAllLoans();

      if (loans.isEmpty) {
        return null;
      }

      // Convert loans to JSON
      final loansJson = loans.map((loan) => _loanToJson(loan)).toList();
      final backupData = {
        'version': 1,
        'exportDate': DateTime.now().toIso8601String(),
        'loans': loansJson,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final bytes = utf8.encode(jsonString);

      // Let user pick save location
      final result = await FilePicker.platform.saveFile(
        dialogTitle: 'Save EMI Backup',
        fileName: 'emi_backup_${DateTime.now().millisecondsSinceEpoch}.json',
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(bytes),
      );

      return result;
    } catch (e) {
      debugPrint('Error saving backup: $e');
      rethrow;
    }
  }

  /// Import loans from a JSON file
  Future<int> importLoans({bool replaceExisting = false}) async {
    try {
      // Pick a JSON file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true, // Important: read file bytes on Android
      );

      if (result == null || result.files.isEmpty) {
        return 0;
      }

      final pickedFile = result.files.single;
      String jsonString;

      // Try to read from bytes first (Android), then from path (iOS/Desktop)
      if (pickedFile.bytes != null) {
        jsonString = String.fromCharCodes(pickedFile.bytes!);
      } else if (pickedFile.path != null) {
        final file = File(pickedFile.path!);
        jsonString = await file.readAsString();
      } else {
        throw Exception('Could not read file');
      }

      debugPrint('Backup file content length: ${jsonString.length}');
      debugPrint('Backup file preview: ${jsonString.substring(0, jsonString.length > 200 ? 200 : jsonString.length)}');

      final dynamic decodedData = json.decode(jsonString);

      List<dynamic> loansJson;

      // Handle different backup formats
      if (decodedData is Map<String, dynamic>) {
        debugPrint('Parsed as Map. Keys: ${decodedData.keys.toList()}');
        // Format 1: { "loans": [...] } or { "version": 1, "loans": [...] }
        if (decodedData.containsKey('loans')) {
          loansJson = decodedData['loans'] as List<dynamic>;
        }
        // Format 2: Single loan object { "id": "...", "name": "...", ... }
        else if (decodedData.containsKey('name') &&
                 (decodedData.containsKey('emiAmount') || decodedData.containsKey('emi_amount'))) {
          loansJson = [decodedData];
        }
        else {
          throw Exception('Invalid backup file format. Keys found: ${decodedData.keys.toList()}');
        }
      }
      // Format 3: Direct array of loans [{ ... }, { ... }]
      else if (decodedData is List<dynamic>) {
        debugPrint('Parsed as List with ${decodedData.length} items');
        loansJson = decodedData;
      }
      else {
        throw Exception('Invalid backup file format. Type: ${decodedData.runtimeType}');
      }

      if (loansJson.isEmpty) {
        debugPrint('No loans found in backup');
        return 0;
      }

      debugPrint('Found ${loansJson.length} loans to import');

      // Clear existing loans if replacing
      if (replaceExisting) {
        final existingLoans = _storageService.getAllLoans();
        for (var loan in existingLoans) {
          await _storageService.deleteLoan(loan.id);
        }
      }

      // Import loans
      int importedCount = 0;
      for (var loanJson in loansJson) {
        try {
          final loan = _jsonToLoan(loanJson as Map<String, dynamic>);

          // Generate new ID to avoid conflicts
          final newId = '${DateTime.now().millisecondsSinceEpoch}_$importedCount';
          final newLoan = Loan(
            id: newId,
            name: loan.name,
            emiAmount: loan.emiAmount,
            dueDay: loan.dueDay,
            startDate: loan.startDate,
            notes: loan.notes,
            loanAmount: loan.loanAmount,
            interestRate: loan.interestRate,
            tenureMonths: loan.tenureMonths,
            isPaid: loan.isPaid,
            currencyCode: loan.currencyCode,
            emisPaidCount: loan.emisPaidCount,
          );

          await _storageService.addLoan(newLoan);
          importedCount++;
          debugPrint('Imported loan: ${newLoan.name}');
        } catch (e) {
          debugPrint('Error importing individual loan: $e');
        }
      }

      return importedCount;
    } catch (e) {
      debugPrint('Error importing loans: $e');
      rethrow;
    }
  }

  /// Convert Loan to JSON map
  Map<String, dynamic> _loanToJson(Loan loan) {
    return {
      'id': loan.id,
      'name': loan.name,
      'emiAmount': loan.emiAmount,
      'dueDay': loan.dueDay,
      'startDate': loan.startDate.toIso8601String(),
      'notes': loan.notes,
      'loanAmount': loan.loanAmount,
      'interestRate': loan.interestRate,
      'tenureMonths': loan.tenureMonths,
      'isPaid': loan.isPaid,
      'currencyCode': loan.currencyCode,
      'emisPaidCount': loan.emisPaidCount,
    };
  }

  /// Convert JSON map to Loan
  Loan _jsonToLoan(Map<String, dynamic> json) {
    // Parse startDate - handle different formats
    DateTime startDate;
    if (json['startDate'] is String) {
      startDate = DateTime.parse(json['startDate'] as String);
    } else if (json['startDate'] is int) {
      startDate = DateTime.fromMillisecondsSinceEpoch(json['startDate'] as int);
    } else {
      startDate = DateTime.now();
    }

    // Parse dueDay
    int dueDay = 1;
    if (json['dueDay'] != null) {
      dueDay = json['dueDay'] is int ? json['dueDay'] as int : int.tryParse(json['dueDay'].toString()) ?? 1;
    }

    // Parse emiAmount
    double emiAmount = 0;
    if (json['emiAmount'] != null) {
      emiAmount = json['emiAmount'] is num
          ? (json['emiAmount'] as num).toDouble()
          : double.tryParse(json['emiAmount'].toString()) ?? 0;
    }

    return Loan(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Unnamed Loan',
      emiAmount: emiAmount,
      dueDay: dueDay,
      startDate: startDate,
      notes: json['notes']?.toString(),
      loanAmount: json['loanAmount'] != null
          ? (json['loanAmount'] is num ? (json['loanAmount'] as num).toDouble() : double.tryParse(json['loanAmount'].toString()))
          : null,
      interestRate: json['interestRate'] != null
          ? (json['interestRate'] is num ? (json['interestRate'] as num).toDouble() : double.tryParse(json['interestRate'].toString()))
          : null,
      tenureMonths: json['tenureMonths'] != null
          ? (json['tenureMonths'] is int ? json['tenureMonths'] as int : int.tryParse(json['tenureMonths'].toString()))
          : null,
      isPaid: json['isPaid'] == true || json['isPaid'] == 'true',
      currencyCode: json['currencyCode']?.toString() ?? 'INR',
      emisPaidCount: json['emisPaidCount'] != null
          ? (json['emisPaidCount'] is int ? json['emisPaidCount'] as int : int.tryParse(json['emisPaidCount'].toString()) ?? 0)
          : 0,
    );
  }
}
