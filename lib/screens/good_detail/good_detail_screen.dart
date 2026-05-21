import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/good_detail.dart';
import '../../models/request_model.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../chat/chat_room_screen.dart';

enum GoodDetailContext {
  myShared,  // I am the giver — see request list, can cancel publication
  explore,   // I am a browser — can submit a pick-up request
  myTaken,   // I am the requester — can cancel my request
}

class GoodDetailScreen extends StatefulWidget {
  final GoodDetail good;
  final GoodDetailContext detailContext;
  final GoodTakenModel? takenRecord;
  /// For myTaken context: the Request record the user submitted.
  final RequestModel? myRequest;

  const GoodDetailScreen({
    super.key,
    required this.good,
    required this.detailContext,
    this.takenRecord,
    this.myRequest,
  });

  @override
  State<GoodDetailScreen> createState() => _GoodDetailScreenState();
}

class _GoodDetailScreenState extends State<GoodDetailScreen> {
  final ApiService _api = ApiService();

  late String _currentGoodStatus;
  bool _isActioning = false;

  // explore context state
  RequestModel? _mySubmittedRequest;

  // myShared context state
  List<RequestModel> _requests = [];
  bool _loadingRequests = false;

  @override
  void initState() {
    super.initState();
    _currentGoodStatus = widget.good.status;
    _mySubmittedRequest = widget.myRequest;

    if (widget.detailContext == GoodDetailContext.myShared) {
      _loadRequests();
    }
    // For explore: if no request was pre-loaded by the caller, check the API
    if (widget.detailContext == GoodDetailContext.explore &&
        widget.myRequest == null) {
      _loadMyExistingRequest();
    }
  }

  // ── Data Loading ─────────────────────────────────────────────────────

  Future<void> _loadRequests() async {
    setState(() => _loadingRequests = true);
    try {
      final raw = await _api.fetchRequestsForGood(widget.good.id);
      setState(() {
        _requests = raw.map(RequestModel.fromJson).toList();
        _loadingRequests = false;
      });
    } catch (_) {
      setState(() => _loadingRequests = false);
    }
  }

  /// Fallback: called from explore when the caller didn't pre-fetch the request.
  Future<void> _loadMyExistingRequest() async {
    final int currentUserId = context.read<AuthProvider>().currentUserId ?? 0;
    final raw = await _api.fetchMyRequestForGood(widget.good.id, currentUserId);
    if (raw != null && mounted) {
      setState(() => _mySubmittedRequest = RequestModel.fromJson(raw));
    }
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _submitRequest() async {
    setState(() => _isActioning = true);
    final int currentUserId = context.read<AuthProvider>().currentUserId ?? 0;
    final (error, requestId) = await _api.createRequest(
      userGoodId: widget.good.id,
      requesterId: currentUserId,
    );
    if (!mounted) return;
    setState(() => _isActioning = false);

    if (error == null && requestId != null) {
      setState(() {
        _mySubmittedRequest = RequestModel(
          id: requestId,
          userGoodId: widget.good.id,
          requesterId: context.read<AuthProvider>().currentUserId ?? 0,
          status: 'Pending',
        );
      });
      _snack('Request submitted! Waiting for giver\'s approval 🎉');
    } else {
      _snack(error ?? 'Unknown error', isError: true);
    }
  }

  Future<void> _cancelRequest() async {
    final req = _mySubmittedRequest ?? widget.myRequest;
    if (req == null) return;
    final confirmed = await _confirm(
      title: 'cancel_request'.tr(context: context),
      body: 'Are you sure you want to cancel your pick-up request?',
      confirmLabel: 'Yes, Cancel',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    final error = await _api.updateRequestStatus(req.id, 'Cancelled');
    if (!mounted) return;
    setState(() => _isActioning = false);

    if (error == null) {
      setState(() {
        _mySubmittedRequest = RequestModel(
          id: req.id,
          userGoodId: req.userGoodId,
          requesterId: req.requesterId,
          status: 'Cancelled',
          requesterName: req.requesterName,
          requesterUsername: req.requesterUsername,
        );
      });
      _snack('Request cancelled.');
    } else {
      _snack(error, isError: true);
    }
  }

  Future<void> _cancelPublication() async {
    final confirmed = await _confirm(
      title: 'cancel_publication'.tr(context: context),
      body: 'This will remove your good from listings. Continue?',
      confirmLabel: 'Yes, Cancel',
      isDestructive: true,
    );
    if (!confirmed) return;

    setState(() => _isActioning = true);
    final error = await _api.updateGoodStatus(widget.good.id, 'Cancelled');
    if (!mounted) return;
    setState(() => _isActioning = false);

    if (error == null) {
      setState(() => _currentGoodStatus = 'Cancelled');
      _snack('Good publication cancelled.');
    } else {
      _snack(error, isError: true);
    }
  }

  Future<void> _approveRequest(RequestModel req) async {
    setState(() => _isActioning = true);
    final error = await _api.updateRequestStatus(req.id, 'Approved');
    if (!mounted) return;
    setState(() => _isActioning = false);

    if (error == null) {
      _snack('Request approved! ✅');
      _loadRequests();
    } else {
      _snack(error, isError: true);
    }
  }

  Future<void> _rejectRequest(RequestModel req) async {
    setState(() => _isActioning = true);
    final error = await _api.updateRequestStatus(req.id, 'Rejected');
    if (!mounted) return;
    setState(() => _isActioning = false);

    if (error == null) {
      _snack('Request rejected.');
      _loadRequests();
    } else {
      _snack(error, isError: true);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  Future<bool> _confirm({
    required String title,
    required String body,
    required String confirmLabel,
    bool isDestructive = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(body),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('cancel').tr(),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              confirmLabel,
              style: TextStyle(
                color: isDestructive ? Colors.red : AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red.shade700 : AppTheme.primaryGreen,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day.toString().padLeft(2, '0')} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'available': return AppTheme.primaryGreen;
      case 'taken':     return Colors.blue;
      case 'expired':   return Colors.orange;
      case 'cancelled': return Colors.red;
      default:          return AppTheme.textSecondary;
    }
  }

  Color _reqStatusColor(String status) {
    switch (status) {
      case 'Approved':  return AppTheme.primaryGreen;
      case 'Rejected':  return Colors.red;
      case 'Cancelled': return Colors.grey;
      default:          return Colors.orange;
    }
  }

  /// Free badge — shown when discountedPrice == 0
  Widget _buildPriceBadgeFree() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.volunteer_activism, size: 14, color: AppTheme.primaryGreen),
          SizedBox(width: 6),
          Text(
            'Free',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  /// Paid badge — shows actual (struck-through), discounted price, and % off pill
  Widget _buildPriceBadgePaid({required double actual, required double discounted}) {
    String fmt(double v) =>
        'Rp ${v.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.')}';
    final int pct = actual > 0
        ? ((actual - discounted) / actual * 100).round()
        : 0;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.primaryGreen.withValues(alpha: 0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer_outlined,
                  size: 14, color: AppTheme.primaryGreen),
              const SizedBox(width: 6),
              Text(
                fmt(discounted),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
        ),
        if (actual > discounted) ...[
          const SizedBox(width: 8),
          Text(
            fmt(actual),
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          if (pct > 0) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.red.shade600,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '-$pct%',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  // ── Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          // Hero App Bar
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    widget.good.pictureUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.image, size: 60, color: Colors.grey),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.55),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Good Card ────────────────────────────────────────
                  _buildCard(children: [
                    Align(
                      alignment: Alignment.centerRight,
                      child: _statusBadge(_currentGoodStatus, _statusColor(_currentGoodStatus)),
                    ),
                    const SizedBox(height: 8),
                    Text(widget.good.goodName,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    _infoRow(Icons.category_outlined,    'Category', widget.good.goodCategoryName),
                    const SizedBox(height: 4),
                    _infoRow(
                      Icons.calendar_today_outlined,
                      'Expires',
                      widget.good.datetimeExpiry != null ? _formatDate(widget.good.datetimeExpiry!) : '—',
                      valueColor: widget.good.datetimeExpiry != null &&
                              widget.good.datetimeExpiry!.isBefore(DateTime.now())
                          ? Colors.red
                          : null,
                    ),
                    if (widget.good.ownerIsBusiness) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6F00).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFF6F00).withValues(alpha: 0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.storefront_outlined,
                                    size: 13, color: Color(0xFFFF6F00)),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    widget.good.ownerBusinessName ?? 'Toko / Warung',
                                    style: const TextStyle(
                                      fontSize: 11,
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
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // ── Price row ────────────────────────────────────
                    if (widget.good.isFree)
                      _buildPriceBadgeFree()
                    else
                      _buildPriceBadgePaid(
                        actual: widget.good.actualPrice,
                        discounted: widget.good.discountedPrice,
                      ),
                  ]),
                  const SizedBox(height: 14),

                  // ── Pick Location ───────────────────────────────────
                  if ((widget.good.pickLocation ?? '').isNotEmpty)
                    _buildCard(
                      title: 'pick_up_location'.tr(context: context),
                      titleIcon: Icons.location_on_outlined,
                      children: [
                        Text(widget.good.pickLocation!,
                            style: const TextStyle(fontSize: 14, height: 1.5)),
                      ],
                    ),
                  if ((widget.good.pickLocation ?? '').isNotEmpty) const SizedBox(height: 14),

                  // ── Message for Picker ──────────────────────────────
                  if ((widget.good.messageForPicker ?? '').isNotEmpty)
                    _buildCard(
                      title: 'message_for_picker'.tr(context: context),
                      titleIcon: Icons.chat_bubble_outline,
                      children: [
                        Text(widget.good.messageForPicker!,
                            style: const TextStyle(
                                fontSize: 14, height: 1.5, fontStyle: FontStyle.italic)),
                      ],
                    ),
                  if ((widget.good.messageForPicker ?? '').isNotEmpty) const SizedBox(height: 14),

                  // ── Message for Provider (myTaken) ─────────────────
                  if (widget.detailContext == GoodDetailContext.myTaken)
                    _buildCard(
                      title: 'message_for_provider'.tr(context: context),
                      titleIcon: Icons.message_outlined,
                      children: [
                        Text(
                          'No message from provider.',
                          style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  if (widget.detailContext == GoodDetailContext.myTaken)
                    const SizedBox(height: 14),

                  // ── Datetime Taken (myTaken) ─────────────────────────
                  if (widget.detailContext == GoodDetailContext.myTaken &&
                      widget.takenRecord != null)
                    _buildCard(
                      title: 'taken_on'.tr(context: context),
                      titleIcon: Icons.access_time,
                      children: [
                        Text(
                          _formatDate(widget.takenRecord!.datetimeTaken),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  if (widget.detailContext == GoodDetailContext.myTaken &&
                      widget.takenRecord != null)
                    const SizedBox(height: 14),

                  // ── Request List (myShared) ─────────────────────────
                  if (widget.detailContext == GoodDetailContext.myShared)
                    _buildRequestList(),
                  if (widget.detailContext == GoodDetailContext.myShared)
                    const SizedBox(height: 14),

                  // ── Datetime Taken for myShared ──────────────────────
                  if (widget.detailContext == GoodDetailContext.myShared &&
                      _requests.any((r) => r.isApproved))
                    _buildCard(
                      title: 'datetime_taken'.tr(context: context),
                      titleIcon: Icons.check_circle_outline,
                      children: [
                        Text(
                          'This good has been approved for pick-up.',
                          style: TextStyle(
                              fontSize: 13, color: AppTheme.primaryGreen),
                        ),
                      ],
                    ),
                  if (widget.detailContext == GoodDetailContext.myShared &&
                      _requests.any((r) => r.isApproved))
                    const SizedBox(height: 14),

                  // ── Action Button ───────────────────────────────────
                  _buildActionButton(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Request List Widget ──────────────────────────────────────────────

  Widget _buildRequestList() {
    return _buildCard(
      title: 'pick_up_requests'.tr(context: context),
      titleIcon: Icons.list_alt_outlined,
      children: [
        if (_loadingRequests)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppTheme.primaryGreen)))
        else if (_requests.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No requests yet.',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
            ),
          )
        else
          ..._requests.map((req) => _buildRequestTile(req)),
      ],
    );
  }

  Widget _buildRequestTile(RequestModel req) {
    final name = req.requesterName ?? req.requesterUsername ?? 'User #${req.requesterId}';
    final canAct = req.isPending && _currentGoodStatus.toLowerCase() == 'available';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: AppTheme.primaryGreen),
            ),
          ),
          const SizedBox(width: 10),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                _statusBadge(req.status, _reqStatusColor(req.status), fontSize: 10),
              ],
            ),
          ),
          // Approve / Reject buttons (only for pending)
          if (canAct) ...[
            _isActioning
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                    children: [
                      _iconActionBtn(
                        icon: Icons.check,
                        color: AppTheme.primaryGreen,
                        tooltip: 'Approve',
                        onTap: () => _approveRequest(req),
                      ),
                      const SizedBox(width: 6),
                      _iconActionBtn(
                        icon: Icons.close,
                        color: Colors.red,
                        tooltip: 'Reject',
                        onTap: () => _rejectRequest(req),
                      ),
                    ],
                  ),
          ],
          // Chat button for approved requests
          if (req.isApproved)
            _iconActionBtn(
              icon: Icons.chat_bubble_outline,
              color: AppTheme.primaryGreen,
              tooltip: 'Open Chat',
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatRoomScreen(
                    requestId:     req.id,
                    otherUserId:   req.requesterId,
                    otherUserName: req.requesterName ??
                                   req.requesterUsername ??
                                   'User #${req.requesterId}',
                    goodName:      widget.good.goodName,
                  ),
                ),
              ).then((_) => _loadRequests()),
            ),
        ],
      ),
    );
  }

  Widget _iconActionBtn({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
      ),
    );
  }

  // ── Main Action Button ───────────────────────────────────────────────

  Widget _buildActionButton() {
    if (_isActioning) {
      return const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen));
    }

    switch (widget.detailContext) {
      // ── Giver view ─────────────────────────────────────────────────
      case GoodDetailContext.myShared:
        // Hide Cancel Publication entirely once any request is Approved
        final hasApproved = _requests.any((r) => r.isApproved);
        if (hasApproved) {
          return _infoChip('A request has been approved — good is taken ✅');
        }
        if (_currentGoodStatus.toLowerCase() == 'available') {
          return _actionBtn(
            label: 'cancel_publication'.tr(context: context),
            icon: Icons.cancel_outlined,
            color: Colors.red,
            onPressed: _cancelPublication,
          );
        }
        return _infoChip('This good is no longer active.');

      // ── Browser view ───────────────────────────────────────────────
      case GoodDetailContext.explore:
        if (_currentGoodStatus.toLowerCase() != 'available') {
          return _infoChip('This good is no longer available.');
        }
        if (_mySubmittedRequest != null) {
          final status = _mySubmittedRequest!.status;
          if (status == 'Pending') {
            return Column(
              children: [
                _infoChip('Your request is pending approval ⏳'),
                const SizedBox(height: 10),
                _actionBtn(
                  label: 'cancel_request'.tr(context: context),
                  icon: Icons.cancel_outlined,
                  color: Colors.orange,
                  onPressed: _cancelRequest,
                ),
              ],
            );
          }
          if (status == 'Approved') {
            return _infoChip('Your request was approved! ✅ Go pick it up.');
          }
          if (status == 'Rejected') {
            return _infoChip('Your request was rejected.');
          }
          if (status == 'Cancelled') {
            // Allow re-requesting after cancellation
            return _actionBtn(
              label: 'request_to_pick'.tr(context: context),
              icon: Icons.volunteer_activism,
              color: AppTheme.primaryGreen,
              onPressed: _submitRequest,
            );
          }
        }
        return _actionBtn(
          label: 'request_to_pick'.tr(context: context),
          icon: Icons.volunteer_activism,
          color: AppTheme.primaryGreen,
          onPressed: _submitRequest,
        );

      // ── Requester view ─────────────────────────────────────────────
      case GoodDetailContext.myTaken:
        final req = _mySubmittedRequest ?? widget.myRequest;
        if (req != null && req.isPending) {
          return _actionBtn(
            label: 'cancel_request'.tr(context: context),
            icon: Icons.cancel_outlined,
            color: Colors.orange,
            onPressed: _cancelRequest,
          );
        }
        return _infoChip('Request already processed.');
    }
  }

  Widget _actionBtn({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _infoChip(String msg) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.grey.shade500, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(msg, style: TextStyle(color: Colors.grey.shade600, fontSize: 13))),
        ],
      ),
    );
  }

  Widget _statusBadge(String label, Color color, {double fontSize = 11}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildCard({
    String? title,
    IconData? titleIcon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                if (titleIcon != null) ...[
                  Icon(titleIcon, size: 16, color: AppTheme.primaryGreen),
                  const SizedBox(width: 6),
                ],
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 10),
          ],
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text('$label: ', style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: valueColor ?? AppTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
