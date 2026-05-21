class UserGood {
  final int id;
  final int userId;
  final String goodName;
  final String goodCategory;
  final String pictureUrl;
  final DateTime datetimeExpiry;
  final String status;
  final double actualPrice;
  final double discountedPrice;
  final bool ownerIsBusiness;
  final String? ownerBusinessName;

  UserGood({
    required this.id,
    required this.userId,
    required this.goodName,
    required this.goodCategory,
    required this.pictureUrl,
    required this.datetimeExpiry,
    required this.status,
    required this.actualPrice,
    required this.discountedPrice,
    this.ownerIsBusiness = false,
    this.ownerBusinessName,
  });

  /// Convenience: is this good free to take?
  bool get isFree => discountedPrice == 0;

  factory UserGood.fromJson(Map<String, dynamic> json) {
    String picture = "https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6?auto=format&fit=crop&w=400&q=80";
    if (json['pictures'] != null && (json['pictures'] as List).isNotEmpty) {
      picture = json['pictures'][0]['picture_url'] ?? picture;
      if (!picture.startsWith('http')) {
        picture = 'http://127.0.0.1:8000$picture';
      }
    }

    return UserGood(
      id:              json['id'] as int,
      userId:          json['user'] as int? ?? 0,
      goodName:        json['good_name'] as String? ?? 'Unknown Good',
      goodCategory:    json['good_category_name'] as String? ??
                       json['good_category']?.toString() ?? 'General',
      pictureUrl:      picture,
      datetimeExpiry:  json['datetime_expiry'] != null
          ? DateTime.parse(json['datetime_expiry'] as String)
          : DateTime.now().add(const Duration(days: 1)),
      status:          json['status'] as String? ?? 'Available',
      actualPrice:     double.tryParse(json['actual_price']?.toString() ?? '0') ?? 0.0,
      discountedPrice: double.tryParse(json['discounted_price']?.toString() ?? '0') ?? 0.0,
      ownerIsBusiness: json['owner_is_business'] as bool? ?? false,
      ownerBusinessName: json['owner_business_name'] as String?,
    );
  }
}

// ── Dummy Data (userId: 0 so it's never filtered out as "own" goods) ────────
final List<UserGood> dummySharedGoods = [
  UserGood(
    id: 1,
    userId: 0,
    goodName: "Fresh Apples",
    goodCategory: "Fruits",
    pictureUrl: "https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6?auto=format&fit=crop&w=400&q=80",
    datetimeExpiry: DateTime.now().add(const Duration(days: 2)),
    status: "Available",
    actualPrice: 25000,
    discountedPrice: 0,
    ownerIsBusiness: false,
    ownerBusinessName: null,
  ),
  UserGood(
    id: 2,
    userId: 0,
    goodName: "Baguette Bread",
    goodCategory: "Bakery",
    pictureUrl: "https://images.unsplash.com/photo-1597075687490-8f673c6c17f6?auto=format&fit=crop&w=400&q=80",
    datetimeExpiry: DateTime.now().add(const Duration(hours: 12)),
    status: "Available",
    actualPrice: 35000,
    discountedPrice: 12000,
    ownerIsBusiness: true,
    ownerBusinessName: "Toko Roti Makmur",
  ),
  UserGood(
    id: 3,
    userId: 0,
    goodName: "Mixed Veggies",
    goodCategory: "Vegetables",
    pictureUrl: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&q=80",
    datetimeExpiry: DateTime.now().add(const Duration(days: 1)),
    status: "Available",
    actualPrice: 0,
    discountedPrice: 0,
    ownerIsBusiness: false,
    ownerBusinessName: null,
  ),
];
