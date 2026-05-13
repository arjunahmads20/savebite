import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('terms_of_use').tr(),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Terms of Use',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: May 2026\n\n'
              'Please read these Terms of Use carefully before using the SaveBite mobile application.\n\n'
              '1. Acceptance of Terms\n'
              'By accessing or using our App, you agree to be bound by these Terms. If you disagree with any part of the terms, then you may not access the App.\n\n'
              '2. Purpose of the Platform\n'
              'SaveBite is a platform designed to reduce food waste by connecting individuals who have surplus food (Givers) with those who can consume it (Pickers). We do not own, sell, or guarantee the quality of the food shared on the platform.\n\n'
              '3. User Responsibilities\n'
              '• Givers must ensure that the food they share is safe to consume and accurately described.\n'
              '• Pickers must inspect the food before consumption. SaveBite is not liable for any health issues arising from consumed goods.\n'
              '• You must treat all users with respect. Abuse or harassment in the chat or in person will result in account termination.\n\n'
              '4. Prohibited Items\n'
              'You may not share expired food, alcohol, illegal substances, or any non-food items masquerading as food.\n\n'
              '5. Accounts\n'
              'When you create an account with us, you must provide information that is accurate, complete, and current at all times. Failure to do so constitutes a breach of the Terms, which may result in immediate termination of your account.\n\n'
              '6. Intellectual Property\n'
              'The App and its original content, features, and functionality are and will remain the exclusive property of SaveBite and its licensors.\n\n'
              '7. Changes to Terms\n'
              'We reserve the right, at our sole discretion, to modify or replace these Terms at any time. What constitutes a material change will be determined at our sole discretion.\n\n'
              '8. Contact Us\n'
              'If you have any questions about these Terms, please contact us.',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
                height: 1.5,
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
