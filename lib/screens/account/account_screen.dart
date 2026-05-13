import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../theme/app_theme.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../policy/privacy_policy_screen.dart';
import '../policy/terms_of_use_screen.dart';
import '../settings/language_screen.dart';
import 'edit_profile_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  int get _currentUserId => context.read<AuthProvider>().currentUserId ?? 0;

  final ApiService _api = ApiService();
  final AuthService _auth = AuthService();

  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _api.fetchUserProfile(_currentUserId);
    if (mounted) setState(() {
      _profile = data;
      _loading = false;
    });
  }

  String get _fullName {
    if (_profile == null) return 'User';
    final first = _profile!['first_name'] as String? ?? '';
    final last  = _profile!['last_name']  as String? ?? '';
    final full  = '$first $last'.trim();
    return full.isNotEmpty ? full : (_profile!['username'] as String? ?? 'User');
  }

  String get _initials {
    final parts = _fullName.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _fullName.isNotEmpty ? _fullName[0].toUpperCase() : '?';
  }

  String get _email    => _profile?['email']        as String? ?? '—';
  String get _phone    => _profile?['phone_number']  as String? ?? '—';
  String? get _avatar  => _profile?['avatar_url']    as String?;

  // ── Logout ────────────────────────────────────────────────────────────

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('log_out').tr(context: context),
        content: Text('are_you_sure_you_want_to_log_out').tr(context: context),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel').tr(context: context),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Log Out',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _auth.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : CustomScrollView(
              slivers: [
                // ── Header ────────────────────────────────────────────
                SliverToBoxAdapter(child: _buildHeader()),
                // ── Menu ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionLabel('navigation'.tr(context: context)),
                        _buildMenuCard([
                          _menuItem(
                            icon: Icons.inventory_2_outlined,
                            label: 'my_good_list'.tr(context: context),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<NavigationProvider>().goToTab(3);
                            },
                          ),
                          _menuItem(
                            icon: Icons.chat_bubble_outline,
                            label: 'chat_list'.tr(context: context),
                            onTap: () {
                              Navigator.pop(context);
                              context.read<NavigationProvider>().goToTab(4);
                            },
                          ),
                          _menuItem(
                            icon: Icons.card_giftcard_outlined,
                            label: 'redeem_list'.tr(context: context),
                            onTap: () => _comingSoon('redeem_list'.tr(context: context)),
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _sectionLabel('preferences'.tr(context: context)),
                        _buildMenuCard([
                          _menuItem(
                            icon: Icons.language_outlined,
                            label: 'language'.tr(context: context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const LanguageScreen()),
                              );
                            },
                          ),
                          _menuItem(
                            icon: Icons.settings_outlined,
                            label: 'settings'.tr(context: context),
                            onTap: () => _comingSoon('settings'.tr(context: context)),
                          ),
                          _menuItem(
                            icon: Icons.privacy_tip_outlined,
                            label: 'privacy_policy'.tr(context: context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                              );
                            },
                          ),
                          _menuItem(
                            icon: Icons.description_outlined,
                            label: 'terms_of_use'.tr(context: context),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const TermsOfUseScreen()),
                              );
                            },
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _sectionLabel('account'.tr(context: context)),
                        _buildMenuCard([
                          _menuItem(
                            icon: Icons.logout,
                            label: 'logout'.tr(context: context),
                            iconColor: Colors.red,
                            labelColor: Colors.red,
                            onTap: _logout,
                            showChevron: false,
                          ),
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Profile Header ────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        boxShadow: [BoxShadow(color: Color(0x0D000000), blurRadius: 12, offset: Offset(0, 4))],
      ),
      padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 16, 24, 28),
      child: Column(
        children: [
          // App bar row
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              Text(
                'account'.tr(context: context),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Avatar
          Stack(
            children: [
              _avatar != null && _avatar!.isNotEmpty
                  ? CircleAvatar(
                      radius: 44,
                      backgroundImage: NetworkImage(_avatar!),
                    )
                  : CircleAvatar(
                      radius: 44,
                      backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
                      child: Text(
                        _initials,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGreen,
                        ),
                      ),
                    ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () async {
                    if (_profile == null) return;
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: _profile!)),
                    );
                    if (result == true) _loadProfile(); // refresh if updated
                  },
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Name
          Text(
            _fullName,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          // Email
          Text(
            _email,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
          const SizedBox(height: 20),
          // Info chips row
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 8,
            children: [
              _infoPill(Icons.phone_outlined, _phone),
              _infoPill(Icons.email_outlined, _email),
            ],
          ),
          const SizedBox(height: 20),
          // Statistics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _statColumn(
                Icons.eco, 
                '${(_profile?['goods_saved_count'] as num?)?.toInt() ?? 0}', 
                'goods_saved'.tr(context: context)
              ),
              Container(width: 1, height: 36, color: Colors.grey.shade300),
              _statColumn(
                Icons.account_balance_wallet_outlined, 
                'Rp ${(_profile?['nominal_loss_prevented'] as num?)?.toStringAsFixed(0) ?? '0'}', 
                'loss_prevented'.tr(context: context)
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Edit Profile button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                if (_profile == null) return;
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => EditProfileScreen(initialProfile: _profile!)),
                );
                if (result == true) _loadProfile(); // refresh if updated
              },
              icon: const Icon(Icons.edit_outlined, size: 16),
              label: Text('edit_profile'.tr(context: context)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.primaryGreen,
                side: const BorderSide(color: AppTheme.primaryGreen),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _statColumn(IconData icon, String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryGreen),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _infoPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppTheme.textSecondary),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: AppTheme.textSecondary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          return Column(
            children: [
              items[i],
              if (i < items.length - 1)
                const Divider(height: 1, indent: 56, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    bool showChevron = true,
  }) {
    final fg = iconColor ?? AppTheme.primaryGreen;
    final textColor = labelColor ?? AppTheme.textPrimary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: fg.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 18, color: fg),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
            ),
            if (showChevron)
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _comingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('$feature — ${'coming_soon'.tr(context: context)}'),
      backgroundColor: AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}
