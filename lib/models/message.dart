class Message {
  final String id;
  final String userId;
  final String content;
  final DateTime createdAt;
  final String myUserId; // Current user's ID

  Message({
    required this.id,
    required this.userId,
    required this.content,
    required this.createdAt,
    required this.myUserId,
  });

  // Determine if the message belongs to the current user
  bool get isMine => myUserId == userId;

  factory Message.fromMap({
    required Map<String, dynamic> map,
    required String myUserId,
  }) {
    return Message(
      id: map['id'],
      userId: map['user_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      myUserId: myUserId,
    );
  }
}
