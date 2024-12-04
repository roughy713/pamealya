import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientName;

  const ChatRoomPage({
    Key? key,
    required this.chatRoomId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _ChatRoomPageState createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await Supabase.instance.client
          .from('messages')
          .select('id, content, user_id, created_at')
          .eq('room_id', widget.chatRoomId)
          .order('created_at', ascending: true);

      if (response != null) {
        setState(() {
          _messages.clear();
          _messages.addAll((response as List<dynamic>)
              .map((message) => message as Map<String, dynamic>)
              .toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching messages: $e')),
      );
    }
  }

  void _subscribeToMessages() {
    Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.chatRoomId)
        .listen((List<Map<String, dynamic>> payload) {
          for (final newMessage in payload) {
            // Prevent duplicate messages
            if (!_messages
                .any((message) => message['id'] == newMessage['id'])) {
              setState(() {
                _messages.add(newMessage);
              });
            }
          }
        });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    try {
      // Ensure the room exists before sending the message
      await ensureRoomExists(widget.chatRoomId);

      await Supabase.instance.client.from('messages').insert({
        'content': messageContent,
        'room_id': widget.chatRoomId,
        'user_id': Supabase.instance.client.auth.currentUser?.id,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> ensureRoomExists(String roomId) async {
    try {
      final response = await Supabase.instance.client
          .from('rooms')
          .select('*')
          .eq('id', roomId)
          .maybeSingle();

      if (response == null) {
        // Room doesn't exist; create it
        await Supabase.instance.client.from('rooms').insert({
          'id': roomId,
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      print('Error ensuring room exists: $e');
    }
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
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMine = message['user_id'] ==
                    Supabase.instance.client.auth.currentUser?.id;
                return Align(
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                        vertical: 5.0, horizontal: 10.0),
                    padding: const EdgeInsets.all(10.0),
                    decoration: BoxDecoration(
                      color: isMine ? Colors.green : Colors.grey[300],
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: Text(
                      message['content'],
                      style: TextStyle(
                        color: isMine ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
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
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                    ),
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
