import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/user_good.dart';
import '../../models/good_detail.dart';
import '../../models/good_category.dart';
import '../../models/request_model.dart';
import '../../services/api_service.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../good_detail/good_detail_screen.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final ApiService _apiService = ApiService();

  int get _currentUserId => context.read<AuthProvider>().currentUserId ?? 0;

  
  List<UserGood> _goods = [];
  List<GoodCategory> _categories = [];
  
  bool _isLoadingGoods = true;
  bool _isLoadingCategories = true;
  
  String _activeCategory = "All";
  bool _isMapView = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchGoods();
  }

  Future<void> _fetchCategories() async {
    try {
      final categories = await _apiService.fetchCategories();
      setState(() {
        _categories = categories;
        _isLoadingCategories = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingCategories = false;
        // Mock fallback if db is empty or error
        _categories = [
          GoodCategory(id: 1, name: 'Fruits', color: '#4CAF50'),
          GoodCategory(id: 2, name: 'Vegetables', color: '#4CAF50'),
          GoodCategory(id: 3, name: 'Bakery', color: '#4CAF50'),
        ];
      });
    }
  }

  Future<void> _fetchGoods() async {
    setState(() {
      _isLoadingGoods = true;
    });
    try {
      final all = await _apiService.fetchSharedGoods(categoryName: _activeCategory);
      // Show only Available goods that belong to OTHER users
      final filtered = all
          .where((g) => g.userId != _currentUserId && g.status == 'Available')
          .toList();
      setState(() {
        _goods = filtered;
        _isLoadingGoods = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingGoods = false;
      });
    }
  }

  void _onCategorySelected(String category) {
    setState(() {
      _activeCategory = category;
    });
    _fetchGoods();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('nav_explore').tr(),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  _buildToggleBtn(title: 'list'.tr(context: context), isActive: !_isMapView, onTap: () => setState(() => _isMapView = false)),
                  _buildToggleBtn(title: 'map'.tr(context: context), isActive: _isMapView, onTap: () => setState(() => _isMapView = true)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filters
          _buildFilterSection(),
          
          const SizedBox(height: 16),

          // Content
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn({required String title, required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.white : AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterSection() {
    if (_isLoadingCategories) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(height: 40, child: Center(child: CircularProgressIndicator())),
      );
    }

    final allCategories = ['All', ..._categories.map((c) => c.name)];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: allCategories.length,
        itemBuilder: (context, index) {
          final cat = allCategories[index];
          final isActive = cat == _activeCategory;
          final displayText = cat == 'All' ? 'all'.tr() : cat;
          return GestureDetector(
            onTap: () => _onCategorySelected(cat),
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? AppTheme.primaryGreen : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                displayText,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildListView() {
    if (_isLoadingGoods) {
      return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    if (_goods.isEmpty) {
      return Center(child: Text('no_goods_found_for_this_category').tr());
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _goods.length,
      itemBuilder: (context, index) {
        final good = _goods[index];
        return GestureDetector(
          onTap: () async {
            try {
              final raw = await _apiService.fetchGoodDetail(good.id);
              final detail = GoodDetail.fromJson(raw);
              // Check if current user already has a request for this good
              final existingRaw = await _apiService.fetchMyRequestForGood(
                  good.id, _currentUserId);
              final existing = existingRaw != null
                  ? RequestModel.fromJson(existingRaw)
                  : null;
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoodDetailScreen(
                      good: detail,
                      detailContext: GoodDetailContext.explore,
                      myRequest: existing,
                    ),
                  ),
                ).then((_) => _fetchGoods());
              }
            } catch (_) {
              final detail = GoodDetail(
                id: good.id,
                userId: good.userId,
                goodName: good.goodName,
                goodCategoryName: good.goodCategory,
                pictureUrl: good.pictureUrl,
                datetimeExpiry: good.datetimeExpiry,
                status: good.status,
                goodPrice: good.goodPrice,
              );
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GoodDetailScreen(
                      good: detail,
                      detailContext: GoodDetailContext.explore,
                    ),
                  ),
                );
              }
            }
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                  child: Image.network(
                    good.pictureUrl,
                    height: 100,
                    width: 100,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 100, width: 100, color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(good.goodName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text(good.goodCategory,
                            style: const TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 8),
                        Text(
                          good.goodPrice == 0
                              ? 'Free'
                              : 'Rp ${good.goodPrice.toStringAsFixed(0)}',
                          style: const TextStyle(
                              color: AppTheme.primaryYellow, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 12),
                  child: Icon(Icons.chevron_right, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
      ),
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              "Map View is coming soon!",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              "Stay tuned for location-based discovery.",
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
