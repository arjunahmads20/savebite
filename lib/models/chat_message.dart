/// Represents a single chat message belonging to a Request's conversation.
class ChatMessage {
  final int id;
  final int requestId;
  final int senderId;
  final int receiverId;
  final String body;
  final DateTime datetimeSent;
  final DateTime? datetimeReaded;
  final String? senderName;
  final String? senderAvatar;

  const ChatMessage({
    required this.id,
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.body,
    required this.datetimeSent,
    this.datetimeReaded,
    this.senderName,
    this.senderAvatar,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id:             json['id'] as int,
      requestId:      json['request'] as int? ?? 0,
      senderId:       json['sender'] as int? ?? 0,
      receiverId:     json['receiver'] as int? ?? 0,
      body:           json['body'] as String? ?? '',
      datetimeSent:   json['datetime_sent'] != null
          ? DateTime.parse(json['datetime_sent'] as String).toLocal()
          : DateTime.now(),
      datetimeReaded: json['datetime_readed'] != null
          ? DateTime.tryParse(json['datetime_readed'] as String)?.toLocal()
          : null,
      senderName:   json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
    );
  }

  bool isMine(int currentUserId) => senderId == currentUserId;
}

/// Lightweight summary of a conversation shown in the Chat List.
class ChatConversation {
  final int requestId;
  final int otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String lastMessage;
  final DateTime lastMessageTime;
  final String goodName;

  const ChatConversation({
    required this.requestId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.lastMessage,
    required this.lastMessageTime,
    required this.goodName,
  });
}
