import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/request_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'chat_room_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  int get _currentUserId => context.read<AuthProvider>().currentUserId ?? 0;

  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _conversations = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final raw = await _api.fetchMyApprovedRequests(_currentUserId);
      raw.sort((a, b) {
        final tA = a['last_message_time'] as String? ?? a['datetime_updated'] as String? ?? '';
        final tB = b['last_message_time'] as String? ?? b['datetime_updated'] as String? ?? '';
        return tB.compareTo(tA); // Descending order
      });
      if (mounted) setState(() {
        _conversations = raw;
        _loading = false;
      });
    } catch (e) {
      if (mounted) setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _otherUserName(Map<String, dynamic> req) {
    // If I am the requester, the "other" is the good's owner (giver)
    // If I am the giver, the "other" is the requester
    final requesterId = req['requester'] as int? ?? 0;
    if (requesterId == _currentUserId) {
      // I'm the requester → other is giver
      final goodName = req['good_name'] as String? ?? 'Good';
      return 'Giver - $goodName'; 
    } else {
      // I'm the giver → other is requester
      return req['requester_name'] as String? ??
             req['requester_username'] as String? ??
             'User #$requesterId';
    }
  }

  int _otherUserId(Map<String, dynamic> req) {
    final requesterId = req['requester'] as int? ?? 0;
    if (requesterId == _currentUserId) {
      return req['good_owner_id'] as int? ?? 0;
    }
    return requesterId;
  }

  String _goodName(Map<String, dynamic> req) {
    return req['good_name'] as String? ?? 'Good #${req['user_good']}';
  }

  String _formatTime(String? isoString) {
    if (isoString == null) return '';
    final dt = DateTime.tryParse(isoString);
    if (dt == null) return '';
    final local = dt.toLocal();
    final now = DateTime.now();
    if (local.year == now.year && local.month == now.month && local.day == now.day) {
      return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    }
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('chats').tr(),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
          : _error != null
              ? _errorState()
              : _conversations.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: AppTheme.primaryGreen,
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        separatorBuilder: (_, __) => const Divider(
                            height: 1, indent: 72, endIndent: 16),
                        itemBuilder: (_, i) {
                          final req = _conversations[i];
                          final requestId  = req['id'] as int;
                          final otherName  = _otherUserName(req);
                          final otherUid   = _otherUserId(req);
                          final goodName   = _goodName(req);
                          final lastMsg    = req['last_message_body'] as String? ?? '📦 Request for $goodName';
                          final lastTime   = _formatTime(req['last_message_time'] as String?);

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor:
                                  AppTheme.primaryGreen.withValues(alpha: 0.15),
                              child: Text(
                                otherName.isNotEmpty
                                    ? otherName[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryGreen,
                                    fontSize: 18),
                              ),
                            ),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    otherName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 15),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (lastTime.isNotEmpty)
                                  Text(
                                    lastTime,
                                    style: const TextStyle(
                                        fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                              ],
                            ),
                            subtitle: Text(
                              lastMsg,
                              style: const TextStyle(
                                  fontSize: 13, color: AppTheme.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if ((req['unread_count'] as int? ?? 0) > 0)
                                  Container(
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.all(6),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${req['unread_count']}',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Approved ✅',
                                    style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryGreen),
                                  ),
                                ),
                              ],
                            ),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatRoomScreen(
                                  requestId:      requestId,
                                  otherUserId:    otherUid,
                                  otherUserName:  otherName,
                                  goodName:       goodName,
                                ),
                              ),
                            ).then((_) => _load()),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No active chats',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            Text(
              'Chats appear here once a pick-up\nrequest has been approved.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 12),
          Text(_error ?? 'Unknown error', textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text('retry').tr()),
        ],
      ),
    );
  }
}
