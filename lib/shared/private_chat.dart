import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivateChatPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId;

  const PrivateChatPage({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) return;

    final response = await Supabase.instance.client.from('messages').insert({
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId,
      'message': messageText,
    });

    if (response.error == null) {
      _messageController.clear();
    } else {
      print('Error sending message: ${response.error?.message}');
    }
  }

  Stream<List<Map<String, dynamic>>> _getMessageStream() {
    // Listen for changes in the 'messages' table using Supabase's real-time capabilities
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .order('created_at', ascending: true)
        .map((data) {
          return data.where((message) {
            // Filter messages where current user is either the sender or receiver
            final isSentByCurrentUser =
                message['sender_id'] == widget.currentUserId &&
                    message['receiver_id'] == widget.otherUserId;
            final isReceivedByCurrentUser =
                message['receiver_id'] == widget.currentUserId &&
                    message['sender_id'] == widget.otherUserId;
            return isSentByCurrentUser || isReceivedByCurrentUser;
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Private Chat'),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _getMessageStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final messages = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return ListTile(
                      title: Text(message['message']),
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
                    decoration: const InputDecoration(
                      hintText: 'Enter your message',
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
