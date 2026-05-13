import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_good.dart';
import '../models/our_partner.dart';
import '../models/good_category.dart';

class ApiService {
  // android:usesCleartextTraffic="true"
  // static const String baseUrl = 'https://127.0.0.1:8000/api';
  static const String baseUrl = 'https://arjunahmads24.pythonanywhere.com/api';

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  /// Fetch a user's profile data by ID.
  Future<Map<String, dynamic>?> fetchUserProfile(int userId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }

  /// Fetch the currently authenticated user's profile data.
  Future<Map<String, dynamic>?> fetchCurrentUser() async {
    try {
      final token = await _getToken();
      if (token == null) return null;
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(json.decode(response.body));
      }
    } catch (_) {}
    return null;
  }
  /// Update user profile
  Future<String?> updateUserProfile(int userId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      if (token == null) return 'Not authenticated';
      final response = await http.patch(
        Uri.parse('$baseUrl/users/$userId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(data),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return null; // success
      }
      return 'Failed to update profile: ${response.statusCode}';
    } catch (e) {
      return 'Network error: $e';
    }
  }
  Future<List<UserGood>> fetchSharedGoods({String? categoryName}) async {
    try {
      String url = '$baseUrl/user-goods/?status=Available';
      if (categoryName != null && categoryName.isNotEmpty && categoryName != 'All') {
        url += '&good_category__name=$categoryName';
      }
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserGood.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load shared goods');
      }
    } catch (e) {
      throw Exception('Error fetching shared goods: $e');
    }
  }

  Future<List<GoodCategory>> fetchCategories() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/good-categories/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => GoodCategory.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load categories');
      }
    } catch (e) {
      throw Exception('Error fetching categories: $e');
    }
  }

  Future<List<OurPartner>> fetchPartners() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/partners/'));
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => OurPartner.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load partners');
      }
    } catch (e) {
      throw Exception('Error fetching partners: $e');
    }
  }

  /// Creates a new UserGood. Returns (null, id) on success, (errorMsg, null) on failure.
  Future<(String?, int?)> createGood({
    required int userId,
    required int categoryId,
    required String goodName,
    required DateTime datetimeExpiry,
    required String pickLocation,
    String? messageForPicker,
    double goodPrice = 0.0,
    int goodQuantity = 1,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/user-goods/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user': userId,
          'good_category': categoryId,
          'good_name': goodName,
          'datetime_expiry': datetimeExpiry.toIso8601String(),
          'pick_location': pickLocation,
          'message_for_picker': messageForPicker ?? '',
          'good_price': goodPrice,
          'good_quantity': goodQuantity,
          'status': 'Available',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return (null, data['id'] as int?);
      } else {
        final body = json.decode(response.body);
        final firstError = body is Map ? body.values.first : body.toString();
        final msg = (firstError is List) ? firstError[0].toString() : firstError.toString();
        return (msg, null);
      }
    } catch (e) {
      return ('Network error: $e', null);
    }
  }

  /// Uploads an image for an existing UserGood (multipart POST).
  Future<String?> uploadGoodPicture({
    required int goodId,
    required List<int> imageBytes,
    required String filename,
  }) async {
    try {
      final token = await _getToken();
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/user-good-pictures/'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.fields['user_good'] = goodId.toString();
      request.files.add(http.MultipartFile.fromBytes(
        'picture_url',
        imageBytes,
        filename: filename,
      ));
      final streamed = await request.send();
      return streamed.statusCode == 201 ? null : 'Image upload failed (${streamed.statusCode})';
    } catch (e) {
      return 'Image upload error: $e';
    }
  }

  /// Fetch all goods shared by a specific user.
  Future<List<Map<String, dynamic>>> fetchMyGoods(int userId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user-goods/?user=$userId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load my goods');
  }

  /// Fetch all goods taken/requested by a specific user (as picker).
  Future<List<Map<String, dynamic>>> fetchMyTakenGoods(int userId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/good-takens/?picker=$userId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load taken goods');
  }

  /// Fetch a single UserGood by ID.
  Future<Map<String, dynamic>> fetchGoodDetail(int goodId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/user-goods/$goodId/'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(json.decode(response.body));
    }
    throw Exception('Failed to load good detail');
  }

  /// Update the status of a UserGood (e.g., cancel publication → 'Cancelled').
  Future<String?> updateGoodStatus(int goodId, String newStatus) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/user-goods/$goodId/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': newStatus}),
      );
      return response.statusCode == 200 ? null : 'Failed to update status';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  // ── Request Methods ──────────────────────────────────────────────────

  /// Submit a new pick-up Request for a good.
  /// Returns (null, requestId) on success, (errorMsg, null) on failure.
  Future<(String?, int?)> createRequest({
    required int userGoodId,
    required int requesterId,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/requests/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'user_good': userGoodId,
          'requester': requesterId,
          'status': 'Pending',
        }),
      );
      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        return (null, data['id'] as int?);
      }
      final body = json.decode(response.body);
      final firstError = body is Map ? body.values.first : body.toString();
      final msg = (firstError is List) ? firstError[0].toString() : firstError.toString();
      return (msg, null);
    } catch (e) {
      return ('Network error: $e', null);
    }
  }

  /// Update the status of a Request (Approved / Rejected / Cancelled).
  Future<String?> updateRequestStatus(int requestId, String newStatus) async {
    try {
      final token = await _getToken();
      final response = await http.patch(
        Uri.parse('$baseUrl/requests/$requestId/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'status': newStatus}),
      );
      return response.statusCode == 200 ? null : 'Failed to update request';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Fetch all requests for a specific UserGood (used by the giver in My Shared Good Detail).
  Future<List<Map<String, dynamic>>> fetchRequestsForGood(int userGoodId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/requests/?user_good=$userGoodId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load requests');
  }

  /// Fetch all requests submitted by a specific user (used in My Taken Good).
  Future<List<Map<String, dynamic>>> fetchMyRequests(int requesterId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/requests/?requester=$requesterId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load my requests');
  }

  /// Check if the current user already has an active (Pending/Approved) request
  /// for a given good. Returns null if no active request exists.
  Future<Map<String, dynamic>?> fetchMyRequestForGood(
      int userGoodId, int requesterId) async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/requests/?user_good=$userGoodId&requester=$requesterId'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final list = List<Map<String, dynamic>>.from(json.decode(response.body));
        // Return the most recent active request (Pending or Approved first, else latest)
        final active = list.where(
          (r) => r['status'] == 'Pending' || r['status'] == 'Approved',
        ).toList();
        if (active.isNotEmpty) return active.last;
        // Otherwise return any (most recent) — lets screen show "Cancelled/Rejected" state
        if (list.isNotEmpty) return list.last;
      }
    } catch (_) {}
    return null;
  }

  // ── Chat Methods ─────────────────────────────────────────────────────

  /// Fetch all messages for a given Request (chat room).
  Future<List<Map<String, dynamic>>> fetchMessages(int requestId) async {
    final token = await _getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/chats/?request=$requestId'),
      headers: {if (token != null) 'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Failed to load messages');
  }

  /// Send a message in a chat room (linked to an approved Request).
  Future<String?> sendMessage({
    required int requestId,
    required int senderId,
    required int receiverId,
    required String body,
  }) async {
    try {
      final token = await _getToken();
      final response = await http.post(
        Uri.parse('$baseUrl/chats/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({
          'request': requestId,
          'sender':  senderId,
          'receiver': receiverId,
          'body': body,
        }),
      );
      return response.statusCode == 201 ? null : 'Failed to send message';
    } catch (e) {
      return 'Network error: $e';
    }
  }

  /// Mark all unread messages in a chat room (request) as read for the current user
  Future<void> markChatAsRead(int requestId) async {
    try {
      final token = await _getToken();
      await http.post(
        Uri.parse('$baseUrl/chats/mark_read/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: json.encode({'request_id': requestId}),
      );
    } catch (_) {}
  }

  /// Fetch the total global unread count for the bottom nav bar badge
  Future<int?> fetchGlobalUnreadCount() async {
    try {
      final token = await _getToken();
      final response = await http.get(
        Uri.parse('$baseUrl/chats/unread_count/'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['unread_count'] as int;
      }
    } catch (_) {}
    return null;
  }

  /// Fetch all approved Requests involving the current user
  /// (as donor or requester) to build the Chat List screen.
  Future<List<Map<String, dynamic>>> fetchMyApprovedRequests(int userId) async {
    final token = await _getToken();
    // Fetch as giver and as requester, then merge
    final results = await Future.wait([
      http.get(
        Uri.parse('$baseUrl/requests/?user_good__user=$userId&status=Approved'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
      http.get(
        Uri.parse('$baseUrl/requests/?requester=$userId&status=Approved'),
        headers: {if (token != null) 'Authorization': 'Bearer $token'},
      ),
    ]);

    final combined = <Map<String, dynamic>>[];
    for (final response in results) {
      if (response.statusCode == 200) {
        combined.addAll(
            List<Map<String, dynamic>>.from(json.decode(response.body)));
      }
    }
    // De-duplicate by id
    final seen = <int>{};
    return combined.where((r) => seen.add(r['id'] as int)).toList();
  }
}
