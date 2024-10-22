import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CookChatPage extends StatefulWidget {
  final String currentUserId;
  final String otherUserId; // Ensure the parameter is defined here

  const CookChatPage({
    Key? key,
    required this.currentUserId,
    required this.otherUserId, // This is needed to pass the family head ID
  }) : super(key: key);

  @override
  _CookChatPageState createState() => _CookChatPageState();
}

class _CookChatPageState extends State<CookChatPage> {
  final TextEditingController _messageController = TextEditingController();

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();

    if (content.isEmpty) return;

    final response = await Supabase.instance.client.from('messages').insert({
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId, // Use the otherUserId here
      'message': content,
    });

    if (response.error == null) {
      _messageController.clear();
    } else {
      print('Error sending message: ${response.error?.message}');
    }
  }

  Stream<List<Map<String, dynamic>>> _getMessageStream() {
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .order('created_at', ascending: true)
        .map((data) {
          return data.where((message) {
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
        title: const Text('Cook Chat with Family Head'),
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
