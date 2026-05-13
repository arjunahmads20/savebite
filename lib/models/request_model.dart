/// Represents a pick-up Request submitted by a user for a UserGood.
class RequestModel {
  final int id;
  final int userGoodId;
  final int requesterId;
  final String status; // Pending | Approved | Rejected | Cancelled
  final String? requesterName;
  final String? requesterUsername;
  final DateTime? datetimeCreated;

  const RequestModel({
    required this.id,
    required this.userGoodId,
    required this.requesterId,
    required this.status,
    this.requesterName,
    this.requesterUsername,
    this.datetimeCreated,
  });

  factory RequestModel.fromJson(Map<String, dynamic> json) {
    return RequestModel(
      id:               json['id'] as int,
      userGoodId:       json['user_good'] as int? ?? 0,
      requesterId:      json['requester'] as int? ?? 0,
      status:           json['status'] as String? ?? 'Pending',
      requesterName:    json['requester_name'] as String?,
      requesterUsername: json['requester_username'] as String?,
      datetimeCreated:  json['datetime_created'] != null
          ? DateTime.tryParse(json['datetime_created'] as String)
          : null,
    );
  }

  bool get isPending   => status == 'Pending';
  bool get isApproved  => status == 'Approved';
  bool get isRejected  => status == 'Rejected';
  bool get isCancelled => status == 'Cancelled';
}
