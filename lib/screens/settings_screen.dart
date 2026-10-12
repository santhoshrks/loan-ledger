import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_settings/app_settings.dart';
import '../models/loan.dart';
import '../theme/app_theme.dart';
import '../localization/app_localizations.dart';
import '../services/backup_service.dart';
import '../services/backup_reminder_service.dart';
import '../services/loan_storage_service.dart';
import '../services/language_provider.dart';
import '../services/notification_service.dart';
import '../services/region_preferences_service.dart';
import '../services/auth_provider.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final LoanStorageService storageService;
  final BackupService backupService;
  final NotificationService? notificationService;
  final VoidCallback onDataChanged;

  const SettingsScreen({
    super.key,
    required this.storageService,
    required this.backupService,
    this.notificationService,
    required this.onDataChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  String? _selectedCurrencyOverride;

  @override
  void initState() {
    super.initState();
    _loadCurrencyOverride();
  }

  Future<void> _loadCurrencyOverride() async {
    final selected = await RegionPreferencesService.getPreferredCurrency();
    if (!mounted) return;
    setState(() {
      _selectedCurrencyOverride = selected;
    });
  }

  void _handleLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout? Your data will be saved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final authProvider = context.read<AuthProvider>();
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final loans = widget.storageService.getAllLoans();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: Text(l.settings),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.settings_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.manageYourData,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Backup & Restore Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l.backupAndRestore,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l.backupDescription,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),

                  // Current Data Info Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.storage_rounded,
                            color: AppTheme.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.currentData,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppTheme.textDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${loans.length} ${l.loansStored}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Export Button
                  _buildActionCard(
                    icon: Icons.upload_rounded,
                    iconColor: Colors.green,
                    title: l.exportBackup,
                    subtitle: l.exportBackupDescription,
                    isLoading: _isExporting,
                    onTap: loans.isEmpty ? null : _exportBackup,
                  ),

                  const SizedBox(height: 12),

                  // Import Button
                  _buildActionCard(
                    icon: Icons.download_rounded,
                    iconColor: Colors.blue,
                    title: l.importBackup,
                    subtitle: l.importBackupDescription,
                    isLoading: _isImporting,
                    onTap: _importBackup,
                  ),

                  const SizedBox(height: 24),

                  // Auto Backup Info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: Colors.blue[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l.autoBackupTitle,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l.autoBackupDescription,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Language Section
                  Text(
                    l.language,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Language Selector
                  _buildLanguageSelector(context),

                  const SizedBox(height: 24),

                  const Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCurrencyOverrideCard(),

                  const SizedBox(height: 24),

                  // Notification Settings Section
                  Text(
                    l.notificationSettings,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Notification Settings Card
                  _buildNotificationSettingsCard(context, l),

                  const SizedBox(height: 40),

                  // User Account Section
                  Text(
                    'Account',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // User Info Card
                  Consumer<AuthProvider>(
                    builder: (context, authProvider, _) {
                      final user = authProvider.user;
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.account_circle_rounded,
                                    color: AppTheme.primaryColor,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        user?.displayName ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        user?.email ?? user?.phoneNumber ?? 'No email',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[600],
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _handleLogout(context),
                              icon: const Icon(Icons.logout),
                              label: const Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(double.infinity, 48),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool isLoading,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                      ),
                    )
                  : Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: onTap == null ? Colors.grey : AppTheme.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: onTap == null ? Colors.grey[300] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context) {
    final languages = [
      {'code': 'en', 'name': 'English', 'nativeName': 'English'},
      {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
      {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
      {'code': 'te', 'name': 'Telugu', 'nativeName': 'తెలుగు'},
      {'code': 'kn', 'name': 'Kannada', 'nativeName': 'ಕನ್ನಡ'},
      {'code': 'ml', 'name': 'Malayalam', 'nativeName': 'മലയാളം'},
      {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
      {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
      {'code': 'gu', 'name': 'Gujarati', 'nativeName': 'ગુજરાતી'},
      {'code': 'ur', 'name': 'Urdu', 'nativeName': 'اردو'},
      {'code': 'id', 'name': 'Bahasa Indonesia', 'nativeName': 'Indonesia'},
      {'code': 'fil', 'name': 'Filipino', 'nativeName': 'Filipino'},
      {'code': 'es', 'name': 'Spanish', 'nativeName': 'Español'},
    ];

    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, _) {
        final currentCode = languageProvider.currentLocale.languageCode;

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: languages.map((lang) {
              final isSelected = currentCode == lang['code'];
              return InkWell(
                onTap: () async {
                  languageProvider.setLanguage(lang['code']!);
                  // Reschedule notifications in new language
                  await _rescheduleNotificationsForLanguageChange();
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryColor.withValues(alpha: 0.08)
                        : null,
                    border: Border(
                      bottom: lang != languages.last
                          ? BorderSide(
                              color: Colors.grey.withValues(alpha: 0.1),
                            )
                          : BorderSide.none,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryColor.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Center(
                          child: Text(
                            lang['nativeName']!.substring(0, 1),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? AppTheme.primaryColor
                                  : Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang['nativeName']!,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: isSelected
                                    ? AppTheme.primaryColor
                                    : AppTheme.textDark,
                              ),
                            ),
                            Text(
                              lang['name']!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppTheme.primaryColor,
                          size: 22,
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _buildCurrencyOverrideCard() {
    final currencies = CurrencyHelper.supportedCurrencies..sort();
    final dropdownItems = <DropdownMenuItem<String?>>[
      const DropdownMenuItem<String?>(
        value: null,
        child: Text('Auto (device locale)'),
      ),
      ...currencies.map(
        (code) => DropdownMenuItem<String?>(
          value: code,
          child: Text('$code - ${CurrencyHelper.getName(code)}'),
        ),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Default currency for new loans',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Set a currency for your country or keep auto-detection.',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            initialValue: _selectedCurrencyOverride,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: dropdownItems,
            onChanged: _onCurrencyOverrideChanged,
          ),
        ],
      ),
    );
  }

  Future<void> _onCurrencyOverrideChanged(String? value) async {
    await RegionPreferencesService.setPreferredCurrency(value);
    if (!mounted) return;
    setState(() {
      _selectedCurrencyOverride = value;
    });
  }

  Widget _buildNotificationSettingsCard(
    BuildContext context,
    AppLocalizations l,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Notifications Status - Tap to open notification settings
          InkWell(
            onTap: () =>
                AppSettings.openAppSettings(type: AppSettingsType.notification),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: FutureBuilder<bool>(
              future: _checkNotificationPermission(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? true;
                return _buildNotificationItem(
                  icon: Icons.notifications_active_rounded,
                  iconColor: isEnabled ? Colors.green : Colors.red,
                  title: l.notifications,
                  subtitle: isEnabled ? l.enabled : l.disabled,
                  showArrow: true,
                  statusIcon: isEnabled ? Icons.check_circle : Icons.error,
                  statusColor: isEnabled ? Colors.green : Colors.red,
                );
              },
            ),
          ),

          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),

          // Exact Alarms - Tap to open alarm settings
          InkWell(
            onTap: () =>
                AppSettings.openAppSettings(type: AppSettingsType.alarm),
            child: FutureBuilder<bool>(
              future: _checkExactAlarmPermission(),
              builder: (context, snapshot) {
                final isEnabled = snapshot.data ?? true;
                return _buildNotificationItem(
                  icon: Icons.alarm_rounded,
                  iconColor: isEnabled ? Colors.blue : Colors.red,
                  title: l.exactAlarms,
                  subtitle: isEnabled ? l.enabled : l.disabled,
                  showArrow: true,
                  statusIcon: isEnabled ? Icons.check_circle : Icons.error,
                  statusColor: isEnabled ? Colors.blue : Colors.red,
                );
              },
            ),
          ),

          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),

          // Pending Reminders - Tap to show list
          InkWell(
            onTap: () => _showPendingReminders(context, l),
            child: FutureBuilder<int>(
              future: _getPendingRemindersCount(),
              builder: (context, snapshot) {
                final count = snapshot.data ?? 0;
                return _buildNotificationItem(
                  icon: Icons.schedule_rounded,
                  iconColor: Colors.orange,
                  title: l.pendingReminders,
                  subtitle: '$count ${l.notificationsScheduled}',
                  showArrow: true,
                  statusIcon: null,
                  statusColor: null,
                );
              },
            ),
          ),

          Divider(height: 1, color: Colors.grey.withValues(alpha: 0.1)),

          // Open App Settings
          InkWell(
            onTap: () => AppSettings.openAppSettings(),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: _buildNotificationItem(
              icon: Icons.settings_rounded,
              iconColor: AppTheme.primaryColor,
              title: l.openAppSettings,
              subtitle: l.manageNotificationPreferences,
              showArrow: true,
              statusIcon: null,
              statusColor: null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool showArrow,
    IconData? statusIcon,
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (statusIcon != null) ...[
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                    ],
                    Expanded(
                      child: Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: statusColor ?? Colors.grey[500],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (showArrow)
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey[400],
            ),
        ],
      ),
    );
  }

  Future<bool> _checkNotificationPermission() async {
    if (widget.notificationService == null) return true;
    try {
      return await widget.notificationService!.checkPermissions();
    } catch (e) {
      return true;
    }
  }

  Future<bool> _checkExactAlarmPermission() async {
    if (widget.notificationService == null) return true;
    try {
      return await widget.notificationService!.checkExactAlarmPermission();
    } catch (e) {
      return true;
    }
  }

  Future<void> _showPendingReminders(
    BuildContext context,
    AppLocalizations l,
  ) async {
    if (widget.notificationService == null) return;

    try {
      final pending = await widget.notificationService!
          .getPendingNotifications();

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (context) => Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      color: Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${l.pendingReminders} (${pending.length})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              const Divider(),
              // List
              Expanded(
                child: pending.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.notifications_off_rounded,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              l.noRemindersScheduled,
                              style: TextStyle(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: pending.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final notification = pending[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.orange.withValues(
                                  alpha: 0.1,
                                ),
                                child: const Icon(
                                  Icons.notifications_rounded,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                notification.title ?? 'EMI Reminder',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                notification.body ?? '',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading reminders: $e')));
      }
    }
  }

  Future<int> _getPendingRemindersCount() async {
    if (widget.notificationService == null) return 0;
    try {
      final pending = await widget.notificationService!
          .getPendingNotifications();
      return pending.length;
    } catch (e) {
      return 0;
    }
  }

  /// Reschedule all notifications when language changes
  Future<void> _rescheduleNotificationsForLanguageChange() async {
    if (widget.notificationService == null) return;

    try {
      // Cancel all existing notifications
      await widget.notificationService!.cancelAllNotifications();

      // Get all loans and reschedule notifications in new language
      final loans = widget.storageService.getAllLoans();
      for (final loan in loans) {
        if (!loan.isPaid) {
          await widget.notificationService!.scheduleLoadReminders(loan);
        }
      }

      debugPrint('✅ Notifications rescheduled for language change');
    } catch (e) {
      debugPrint('❌ Error rescheduling notifications: $e');
    }
  }

  Future<void> _exportBackup() async {
    setState(() => _isExporting = true);

    try {
      final savedPath = await widget.backupService.exportLoans();

      // Record backup date
      await BackupReminderService.setLastBackupDate();

      if (mounted) {
        if (savedPath != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context).backupCreatedSuccessfully,
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).backupFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _importBackup() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).importBackup),
        content: Text(AppLocalizations.of(context).importBackupConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: Text(AppLocalizations.of(context).import),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final importedCount = await widget.backupService.importLoans();

      if (mounted) {
        if (importedCount > 0) {
          widget.onDataChanged();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context).importedSuccessfully}: $importedCount ${AppLocalizations.of(context).loans}',
              ),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).noLoansImported),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context).importFailed}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isImporting = false);
    }
  }
}
