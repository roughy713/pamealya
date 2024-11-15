import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PrivateChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserUsername;
  final String otherUserId;
  final String otherUserName;
  final bool isCookInitiated;

  const PrivateChatPage({
    super.key,
    required this.currentUserId,
    required this.currentUserUsername,
    required this.otherUserId,
    required this.otherUserName,
    required this.isCookInitiated,
  });

  @override
  _PrivateChatPageState createState() => _PrivateChatPageState();
}

class _PrivateChatPageState extends State<PrivateChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];

  @override
  void initState() {
    super.initState();
    _listenToMessages();
  }

  void _listenToMessages() {
    final stream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['message_id']).order('created_at');

    stream.listen((allMessages) {
      final filteredMessages = allMessages.where((message) {
        final isSentByCurrentUser =
            message['sender_id'] == widget.currentUserUsername &&
                message['receiver_id'] == widget.otherUserName;
        final isReceivedByCurrentUser =
            message['sender_id'] == widget.otherUserName &&
                message['receiver_id'] == widget.currentUserUsername;
        return isSentByCurrentUser || isReceivedByCurrentUser;
      }).toList();

      setState(() {
        _messages = filteredMessages;
      });

      _scrollToBottom();
    }, onError: (error) {
      print("Error in real-time subscription: $error");
    });
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final senderId = widget.currentUserUsername;
    final receiverId = widget.otherUserName;

    final response = await Supabase.instance.client.from('messages').insert({
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': messageText,
      'created_at': DateTime.now().toIso8601String(),
    });

    if (response.error == null) {
      _messageController.clear();
      _scrollToBottom();
    } else {
      print('Error sending message: ${response.error?.message}');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.otherUserName),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isCurrentUser =
                    message['sender_id'] == widget.currentUserUsername;

                return Align(
                  alignment: isCurrentUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color:
                          isCurrentUser ? Colors.blue[300] : Colors.grey[300],
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(10),
                        topRight: const Radius.circular(10),
                        bottomLeft: isCurrentUser
                            ? const Radius.circular(10)
                            : const Radius.circular(0),
                        bottomRight: isCurrentUser
                            ? const Radius.circular(0)
                            : const Radius.circular(10),
                      ),
                    ),
                    child: Text(
                      message['message'],
                      style: TextStyle(
                          color: isCurrentUser ? Colors.white : Colors.black),
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
