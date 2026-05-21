import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/good_detail.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../good_detail/good_detail_screen.dart';

class MyGoodListScreen extends StatefulWidget {
  const MyGoodListScreen({super.key});

  @override
  State<MyGoodListScreen> createState() => _MyGoodListScreenState();
}

class _MyGoodListScreenState extends State<MyGoodListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _api = ApiService();

  int get _userId => context.read<AuthProvider>().currentUserId ?? 0;

  List<GoodDetail> _mySharedGoods = [];
  List<GoodTakenModel> _myTakenGoods = [];
  bool _loadingShared = true;
  bool _loadingTaken = true;
  String? _sharedError;
  String? _takenError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadShared();
    _loadTaken();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadShared() async {
    setState(() {
      _loadingShared = true;
      _sharedError = null;
    });
    try {
      final raw = await _api.fetchMyGoods(_userId);
      setState(() {
        _mySharedGoods = raw.map(GoodDetail.fromJson).toList();
        _loadingShared = false;
      });
    } catch (e) {
      setState(() {
        _sharedError = e.toString();
        _loadingShared = false;
      });
    }
  }

  Future<void> _loadTaken() async {
    setState(() {
      _loadingTaken = true;
      _takenError = null;
    });
    try {
      final raw = await _api.fetchMyTakenGoods(_userId);
      setState(() {
        _myTakenGoods = raw.map(GoodTakenModel.fromJson).toList();
        _loadingTaken = false;
      });
    } catch (e) {
      setState(() {
        _takenError = e.toString();
        _loadingTaken = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('my_goods').tr(),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryGreen,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryGreen,
          indicatorWeight: 3,
          tabs: [
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.volunteer_activism, size: 16),
                  const SizedBox(width: 6),
                  Text('${'shared'.tr()} (${_mySharedGoods.length})'),
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shopping_bag_outlined, size: 16),
                  const SizedBox(width: 6),
                  Text('${'taken'.tr()} (${_myTakenGoods.length})'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildSharedList(),
          _buildTakenList(),
        ],
      ),
    );
  }

  // ── Shared Goods Tab ────────────────────────────────────────────────
  Widget _buildSharedList() {
    if (_loadingShared) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    if (_sharedError != null) {
      return _errorState(_sharedError!, onRetry: _loadShared);
    }
    if (_mySharedGoods.isEmpty) {
      return _emptyState(
        icon: Icons.volunteer_activism,
        title: 'no_goods_shared_yet'.tr(context: context),
        subtitle: 'tap_the_button_to_share_your_first_good'.tr(context: context),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadShared,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _mySharedGoods.length,
        itemBuilder: (_, i) => _GoodCard(
          good: _mySharedGoods[i],
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => GoodDetailScreen(
                good: _mySharedGoods[i],
                detailContext: GoodDetailContext.myShared,
              ),
            ),
          ).then((_) => _loadShared()), // Refresh after returning from detail
        ),
      ),
    );
  }

  // ── Taken Goods Tab ─────────────────────────────────────────────────
  Widget _buildTakenList() {
    if (_loadingTaken) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }
    if (_takenError != null) {
      return _errorState(_takenError!, onRetry: _loadTaken);
    }
    if (_myTakenGoods.isEmpty) {
      return _emptyState(
        icon: Icons.shopping_bag_outlined,
        title: 'no_goods_taken_yet'.tr(context: context),
        subtitle: 'explore_shared_goods_and_request_to_pick_one'.tr(context: context),
      );
    }
    return RefreshIndicator(
      color: AppTheme.primaryGreen,
      onRefresh: _loadTaken,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _myTakenGoods.length,
        itemBuilder: (_, i) {
          final taken = _myTakenGoods[i];
          final good = taken.goodDetail;
          if (good == null) return const SizedBox.shrink();
          return _GoodCard(
            good: good,
            badge: 'Qty: ${taken.quantity}',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => GoodDetailScreen(
                  good: good,
                  detailContext: GoodDetailContext.myTaken,
                  takenRecord: taken,
                ),
              ),
            ).then((_) => _loadTaken()),
          );
        },
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────
  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _errorState(String error, {required VoidCallback onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text('Failed to load', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text('retry').tr(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reusable Good Card Widget ────────────────────────────────────────────
class _GoodCard extends StatelessWidget {
  final GoodDetail good;
  final VoidCallback onTap;
  final String? badge;

  const _GoodCard({required this.good, required this.onTap, this.badge});

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available':
        return AppTheme.primaryGreen;
      case 'taken':
        return Colors.blue;
      case 'expired':
        return Colors.orange;
      case 'cancelled':
        return Colors.red;
      default:
        return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Picture
              ClipRRect(
                borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
                child: Image.network(
                  good.pictureUrl,
                  width: 120,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 120,
                    color: Colors.grey.shade200,
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 12.0, top: 12.0, bottom: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status badge
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _statusColor(good.status).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            good.status.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: _statusColor(good.status),
                            ),
                          ),
                        ),
                        if (badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Name
                    Text(
                      good.goodName,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Category + business badge
                    Row(
                      children: [
                        const Icon(Icons.category_outlined,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            good.goodCategoryName,
                            style: const TextStyle(
                                fontSize: 12, color: AppTheme.textSecondary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (good.ownerIsBusiness)
                          Flexible(
                            child: Container(
                              margin: const EdgeInsets.only(left: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6F00)
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFFF6F00)
                                        .withValues(alpha: 0.4)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.storefront_outlined,
                                      size: 10, color: Color(0xFFFF6F00)),
                                  const SizedBox(width: 3),
                                  Flexible(
                                    child: Text(
                                      good.ownerBusinessName ?? 'Toko / Warung',
                                      style: const TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFFF6F00),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Expiry
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 13, color: AppTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          good.datetimeExpiry != null
                              ? 'Expires ${_formatDate(good.datetimeExpiry!)}'
                              : 'No expiry',
                          style: TextStyle(
                            fontSize: 12,
                            color: good.datetimeExpiry != null &&
                                    good.datetimeExpiry!
                                        .isBefore(DateTime.now())
                                ? Colors.red
                                : AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Price
                    if (good.isFree)
                      Row(
                        children: [
                          const Icon(Icons.volunteer_activism,
                              size: 12, color: AppTheme.primaryGreen),
                          const SizedBox(width: 4),
                          const Text(
                            'Free',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ],
                      )
                    else
                      Builder(builder: (context) {
                        final pct = good.actualPrice > 0
                            ? ((good.actualPrice - good.discountedPrice) /
                                    good.actualPrice *
                                    100)
                                .round()
                            : 0;
                        return Row(
                          children: [
                            const Icon(Icons.local_offer_outlined,
                                size: 12, color: AppTheme.primaryGreen),
                            const SizedBox(width: 4),
                            Text(
                              'Rp ${good.discountedPrice.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryGreen,
                              ),
                            ),
                            if (good.actualPrice > good.discountedPrice) ...[
                              const SizedBox(width: 6),
                              Text(
                                'Rp ${good.actualPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textSecondary,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              if (pct > 0) ...[
                                const SizedBox(width: 5),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade600,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '-$pct%',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        );
                      }),
                  ],
                ),
              ),
            ),
            // Chevron
            const Padding(
              padding: EdgeInsets.only(right: 12),
              child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
            ),
          ],
        ),
        ),
      ),
    );
  }
}
