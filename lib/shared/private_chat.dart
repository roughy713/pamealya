import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivateChatPage extends StatefulWidget {
  final String currentUserId; // Cook or family head's ID (sender)
  final String otherUserId; // Family head or cook's ID (receiver)
  final String
      otherUserName; // The name of the other user (to show in the AppBar)
  final bool
      isCookInitiated; // Whether the chat was initiated by the cook or not

  const PrivateChatPage({
    Key? key,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
    required this.isCookInitiated,
  }) : super(key: key);

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  // Function to send messages
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();

    if (messageText.isEmpty) return;

    // Insert the message into the 'messages' table
    final response = await Supabase.instance.client.from('messages').insert({
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId,
      'message': messageText,
      'created_at':
          DateTime.now().toIso8601String(), // Make sure to store the time
    });

    if (response.error == null) {
      setState(() {
        _messages.add({
          'sender_id': widget.currentUserId,
          'receiver_id': widget.otherUserId,
          'message': messageText,
          'created_at': DateTime.now().toString(),
        });
      });
      _messageController.clear();
      _scrollToBottom();
    } else {
      print('Error sending message: ${response.error?.message}');
    }
  }

  // Scroll to the bottom when a new message is added
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  // Filter messages between cook and family head
  List<Map<String, dynamic>> _filterMessages(
      List<Map<String, dynamic>> messages) {
    return messages.where((message) {
      return (message['sender_id'] == widget.currentUserId &&
              message['receiver_id'] == widget.otherUserId) ||
          (message['sender_id'] == widget.otherUserId &&
              message['receiver_id'] == widget.currentUserId);
    }).toList();
  }

  // Stream for retrieving messages in real-time
  Stream<List<Map<String, dynamic>>> _getMessageStream() {
    return Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['message_id'])
        .order('created_at', ascending: true)
        .map((data) => List<Map<String, dynamic>>.from(data));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget
            .otherUserName), // Set the AppBar to display the family head's or cook's name
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

                final allMessages =
                    snapshot.data as List<Map<String, dynamic>>? ?? [];
                final filteredMessages = _filterMessages(allMessages);

                _messages = filteredMessages;

                return ListView.builder(
                  controller: _scrollController,
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final message = _messages[index];
                    final isCurrentUser =
                        message['sender_id'] == widget.currentUserId;

                    // Message alignment and styling
                    return Align(
                      alignment: isCurrentUser
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                            vertical: 5, horizontal: 10),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? Colors.blue[300]
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          message['message'],
                          style: TextStyle(
                              color:
                                  isCurrentUser ? Colors.white : Colors.black),
                        ),
                      ),
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
                    onSubmitted: (value) => _sendMessage(),
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
