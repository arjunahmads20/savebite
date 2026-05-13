import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('privacy_policy').tr(),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Last updated: May 2026\n\n'
              'Welcome to SaveBite. We are committed to protecting your personal information and your right to privacy. If you have any questions or concerns about this privacy notice, or our practices with regards to your personal information, please contact us.\n\n'
              '1. What Information Do We Collect?\n'
              'We collect personal information that you voluntarily provide to us when you register on the App, express an interest in obtaining information about us or our products and Services, when you participate in activities on the App or otherwise when you contact us.\n\n'
              '2. How Do We Use Your Information?\n'
              'We use personal information collected via our App for a variety of business purposes described below. We process your personal information for these purposes in reliance on our legitimate business interests, in order to enter into or perform a contract with you, with your consent, and/or for compliance with our legal obligations.\n\n'
              '3. Will Your Information Be Shared With Anyone?\n'
              'We only share information with your consent, to comply with laws, to provide you with services, to protect your rights, or to fulfill business obligations. For example, when you participate in picking up a good, the giver may see your username to facilitate the transaction.\n\n'
              '4. How Long Do We Keep Your Information?\n'
              'We keep your information for as long as necessary to fulfill the purposes outlined in this privacy notice unless otherwise required by law.\n\n'
              '5. How Do We Keep Your Information Safe?\n'
              'We aim to protect your personal information through a system of organizational and technical security measures.\n\n'
              '6. Do We Collect Information From Minors?\n'
              'We do not knowingly solicit data from or market to children under 18 years of age. By using the App, you represent that you are at least 18 or that you are the parent or guardian of such a minor and consent to such minor dependent’s use of the App.\n\n'
              '7. What Are Your Privacy Rights?\n'
              'You may review, change, or terminate your account at any time. Upon your request to terminate your account, we will deactivate or delete your account and information from our active databases.',
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
