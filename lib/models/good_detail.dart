import 'user_good.dart';

/// Full detail model for a UserGood — extends UserGood with extra fields
/// returned by the detail API response.
class GoodDetail {
  final int id;
  final int userId;
  final String goodName;
  final String goodCategoryName;
  final String pictureUrl;
  final DateTime? datetimeExpiry;
  final String status;
  final double goodPrice;
  final String? pickLocation;
  final String? messageForPicker;

  const GoodDetail({
    required this.id,
    required this.userId,
    required this.goodName,
    required this.goodCategoryName,
    required this.pictureUrl,
    this.datetimeExpiry,
    required this.status,
    required this.goodPrice,
    this.pickLocation,
    this.messageForPicker,
  });

  factory GoodDetail.fromJson(Map<String, dynamic> json) {
    String picture =
        'https://images.unsplash.com/photo-1560806887-1e4cd0b6faa6?auto=format&fit=crop&w=400&q=80';
    if (json['pictures'] != null && (json['pictures'] as List).isNotEmpty) {
      final raw = json['pictures'][0]['picture_url'] as String? ?? picture;
      picture = raw.startsWith('http') ? raw : 'http://127.0.0.1:8000$raw';
    }

    return GoodDetail(
      id: json['id'] as int,
      userId: json['user'] as int? ?? 0,
      goodName: json['good_name'] as String? ?? 'Unknown Good',
      goodCategoryName:
          json['good_category_name'] as String? ??
          json['good_category']?.toString() ??
          'General',
      pictureUrl: picture,
      datetimeExpiry: json['datetime_expiry'] != null
          ? DateTime.tryParse(json['datetime_expiry'] as String)
          : null,
      status: json['status'] as String? ?? 'Available',
      goodPrice:
          double.tryParse(json['good_price']?.toString() ?? '0') ?? 0.0,
      pickLocation: json['pick_location'] as String?,
      messageForPicker: json['message_for_picker'] as String?,
    );
  }

  /// Convert back to a simple UserGood for screens that accept UserGood.
  UserGood toUserGood() => UserGood(
        id: id,
        userId: userId,
        goodName: goodName,
        goodCategory: goodCategoryName,
        pictureUrl: pictureUrl,
        datetimeExpiry: datetimeExpiry ?? DateTime.now().add(const Duration(days: 1)),
        status: status,
        goodPrice: goodPrice,
      );
}

/// Represents a GoodTaken record (someone picking up a UserGood).
class GoodTakenModel {
  final int id;
  final int giverId;
  final int pickerId;
  final int userGoodId;
  final int quantity;
  final DateTime datetimeTaken;
  final GoodDetail? goodDetail;

  const GoodTakenModel({
    required this.id,
    required this.giverId,
    required this.pickerId,
    required this.userGoodId,
    required this.quantity,
    required this.datetimeTaken,
    this.goodDetail,
  });

  factory GoodTakenModel.fromJson(Map<String, dynamic> json) {
    GoodDetail? detail;
    if (json['user_good_detail'] != null) {
      detail = GoodDetail.fromJson(json['user_good_detail']);
    }
    return GoodTakenModel(
      id: json['id'] as int,
      giverId: json['user'] as int? ?? 0,
      pickerId: json['picker'] as int? ?? 0,
      userGoodId: json['user_good'] as int? ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      datetimeTaken: json['datetime_taken'] != null
          ? DateTime.tryParse(json['datetime_taken'] as String) ??
              DateTime.now()
          : DateTime.now(),
      goodDetail: detail,
    );
  }
}
