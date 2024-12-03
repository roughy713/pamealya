import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamHeadChatPage extends StatefulWidget {
  final String currentUserId; // ID of the family head
  final String currentUserUsername; // Username of the family head

  const FamHeadChatPage({
    Key? key,
    required this.currentUserId,
    required this.currentUserUsername,
  }) : super(key: key);

  @override
  _FamHeadChatPageState createState() => _FamHeadChatPageState();
}

class _FamHeadChatPageState extends State<FamHeadChatPage> {
  late Future<List<Map<String, dynamic>>> _cooksFuture;

  @override
  void initState() {
    super.initState();
    _cooksFuture = fetchCooks();
  }

  Future<List<Map<String, dynamic>>> fetchCooks() async {
    try {
      // Fetch all cooks from the Local_Cook table
      final response = await Supabase.instance.client
          .from('Local_Cook')
          .select('user_id, first_name, last_name');

      if (response.isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch cooks: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Cook to Chat'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _cooksFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final cooks = snapshot.data!;
          if (cooks.isEmpty) {
            return const Center(child: Text('No cooks available to chat.'));
          }

          return ListView.builder(
            itemCount: cooks.length,
            itemBuilder: (context, index) {
              final cook = cooks[index];
              return ListTile(
                title: Text('${cook['first_name']} ${cook['last_name']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        roomId: '${widget.currentUserId}_${cook['user_id']}',
                        recipientName:
                            '${cook['first_name']} ${cook['last_name']}',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatRoomPage extends StatefulWidget {
  final String roomId;
  final String recipientName;

  const ChatRoomPage({
    Key? key,
    required this.roomId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  late final Stream<List<Map<String, dynamic>>> _messagesStream;

  @override
  void initState() {
    super.initState();
    _messagesStream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.roomId)
        .order('created_at')
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    await Supabase.instance.client.from('messages').insert({
      'room_id': widget.roomId,
      'content': text,
      'sender_name': 'Family Head', // Replace with dynamic user details
      'created_at': DateTime.now().toIso8601String(),
    });

    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.recipientName}'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(child: Text('Failed to load messages.'));
                }

                final messages = snapshot.data!;
                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message['content']),
                      subtitle: Text('Sent by: ${message['sender_name']}'),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration:
                        const InputDecoration(hintText: 'Enter message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
