import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('language'.tr()),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildLanguageTile(context, 'english'.tr(), const Locale('en')),
          const Divider(),
          _buildLanguageTile(context, 'indonesian'.tr(), const Locale('id')),
          const Divider(),
          _buildLanguageTile(context, 'japanese'.tr(), const Locale('ja')),
        ],
      ),
    );
  }

  Widget _buildLanguageTile(BuildContext context, String title, Locale locale) {
    final bool isSelected = context.locale == locale;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppTheme.primaryGreen : AppTheme.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppTheme.primaryGreen) : null,
      onTap: () {
        context.setLocale(locale);
        Navigator.pop(context); // Go back after selection
      },
    );
  }
}
