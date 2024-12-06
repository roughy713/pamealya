import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersChatRoomPage extends StatefulWidget {
  final String chatRoomId;
  final String recipientName;

  const OrdersChatRoomPage({
    Key? key,
    required this.chatRoomId,
    required this.recipientName,
  }) : super(key: key);

  @override
  _OrdersChatRoomPageState createState() => _OrdersChatRoomPageState();
}

class _OrdersChatRoomPageState extends State<OrdersChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final supabase = Supabase.instance.client;

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

  /// Fetches messages for the given chat room ID
  Future<void> _fetchMessages() async {
    try {
      final response = await supabase
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

  /// Subscribes to new messages in the current chat room
  void _subscribeToMessages() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.chatRoomId)
        .listen((List<Map<String, dynamic>> payload) {
          for (final newMessage in payload) {
            if (!_messages
                .any((message) => message['id'] == newMessage['id'])) {
              setState(() {
                _messages.add(newMessage);
              });
            }
          }
        });
  }

  /// Sends a message to the current chat room
  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) {
      return;
    }

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    try {
      await supabase.from('messages').insert({
        'content': messageContent,
        'room_id': widget.chatRoomId,
        'user_id': supabase.auth.currentUser?.id,
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with ${widget.recipientName}'),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isMine =
                    message['user_id'] == supabase.auth.currentUser?.id;
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
