import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../models/user_good.dart';
import '../../models/good_detail.dart';
import '../../models/our_partner.dart';
import '../../widgets/top_nav_bar.dart';
import '../../widgets/bottom_nav_bar.dart';
import '../../services/api_service.dart';
import '../../providers/navigation_provider.dart';
import '../../providers/auth_provider.dart';
import '../good_detail/good_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  
  List<UserGood> _goods = [];
  List<OurPartner> _partners = [];
  
  bool _isLoadingGoods = true;
  bool _isLoadingPartners = true;
  
  String? _goodsError;
  String? _partnersError;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    _fetchGoods();
    _fetchPartners();
  }

  Future<void> _fetchGoods() async {
    setState(() {
      _isLoadingGoods = true;
      _goodsError = null;
    });
    try {
      final int currentUserId = context.read<AuthProvider>().currentUserId ?? 0;
      final goods = await _apiService.fetchSharedGoods();
      setState(() {
        _goods = goods.where((g) => g.userId != currentUserId).toList();
        _isLoadingGoods = false;
      });
    } catch (e) {
      setState(() {
        _goodsError = "Failed to load goods.";
        _isLoadingGoods = false;
        // Fallback to dummy data if API is empty/fails during dev
        _goods = dummySharedGoods; 
      });
    }
  }

  Future<void> _fetchPartners() async {
    setState(() {
      _isLoadingPartners = true;
      _partnersError = null;
    });
    try {
      final partners = await _apiService.fetchPartners();
      setState(() {
        _partners = partners;
        _isLoadingPartners = false;
      });
    } catch (e) {
      setState(() {
        _partnersError = "Failed to load partners.";
        _isLoadingPartners = false;
        // Fallback to dummy data if API is empty/fails during dev
        _partners = dummyPartners;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TopNavBar(location: "Jakarta, Indonesia"),
      body: RefreshIndicator(
        onRefresh: _fetchData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // Banner Images section
              _buildBanner(),
              
              const SizedBox(height: 24),
              
              // Shared Goods Section
              _buildSectionHeader(
                title: 'shared_goods'.tr(context: context),
                onSeeAll: () {
                  // Navigate to the Explore tab (index 1)
                  context.read<NavigationProvider>().goToTab(1);
                },
              ),
              _buildSharedGoodsSection(),

              const SizedBox(height: 24),

              // Our Partner Slider Section
              _buildSectionHeader(title: 'our_partners'.tr(context: context), onSeeAll: () {}),
              _buildPartnerSection(),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBanner() {
    final List<String> bannerImages = [
      "https://images.unsplash.com/photo-1488459716781-31db52582fe9?auto=format&fit=crop&w=800&q=80",
      "https://images.unsplash.com/photo-1593113565241-ecfeaa3bcf41?auto=format&fit=crop&w=800&q=80",
    ];

    return CarouselSlider(
      options: CarouselOptions(
        height: 160.0,
        enlargeCenterPage: true,
        autoPlay: true,
        aspectRatio: 16 / 9,
        autoPlayCurve: Curves.fastOutSlowIn,
        enableInfiniteScroll: true,
        autoPlayAnimationDuration: const Duration(milliseconds: 800),
        viewportFraction: 0.9,
      ),
      items: bannerImages.map((imageUrl) {
        return Builder(
          builder: (BuildContext context) {
            return Container(
              width: MediaQuery.of(context).size.width,
              margin: const EdgeInsets.symmetric(horizontal: 5.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(imageUrl),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                alignment: Alignment.bottomLeft,
                child: Text(
                  'Save Food,\nSave The World.',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            );
          },
        );
      }).toList(),
    );
  }

  Widget _buildSectionHeader({required String title, required VoidCallback onSeeAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text(
              "See All",
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharedGoodsSection() {
    if (_isLoadingGoods) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }
    
    if (_goods.isEmpty) {
      return SizedBox(
        height: 220,
        child: Center(child: Text('no_shared_goods_available_right_now').tr()),
      );
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _goods.length,
        itemBuilder: (context, index) {
          final good = _goods[index];
          return GestureDetector(
            onTap: () async {
              try {
                final raw = await _apiService.fetchGoodDetail(good.id);
                final detail = GoodDetail.fromJson(raw);
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
              } catch (_) {
                // Fallback: build from lightweight UserGood
                final detail = GoodDetail(
                  id: good.id,
                  userId: 0,
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
              width: 160,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(
                      good.pictureUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image_not_supported, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          good.goodName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          good.goodCategory,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryYellow.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                good.goodPrice == 0 ? 'Free' : 'Rp ${good.goodPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: AppTheme.primaryYellow,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPartnerSection() {
    if (_isLoadingPartners) {
      return const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen)),
      );
    }
    
    if (_partners.isEmpty) {
      return SizedBox(
        height: 100,
        child: Center(child: Text('no_partners_found').tr()),
      );
    }

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _partners.length,
        itemBuilder: (context, index) {
          final partner = _partners[index];
          return Container(
            width: 80,
            margin: const EdgeInsets.only(right: 16),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage: NetworkImage(partner.avatarUrl),
                  onBackgroundImageError: (exception, stackTrace) {},
                  child: partner.avatarUrl.isEmpty 
                      ? const Icon(Icons.person, color: Colors.white) 
                      : null,
                ),
                const SizedBox(height: 8),
                Text(
                  partner.name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
