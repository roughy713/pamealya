import 'dart:async';
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
  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _messages = [];
  final supabase = Supabase.instance.client;
  bool isLoading = true;
  Timer? _messageTimer;

  @override
  void initState() {
    super.initState();
    print('Chat room ID: ${widget.chatRoomId}'); // Add this debug print
    _fetchMessages();
    _messageTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _fetchMessages();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      // Ensure chat room exists
      final roomResponse = await supabase
          .from('chat_room')
          .select('room_id')
          .eq('room_id', widget.chatRoomId)
          .maybeSingle();

      if (roomResponse == null) {
        print('No existing chat room found.');
        setState(() {
          _messages = [];
          isLoading = false;
        });
        return;
      }

      // Fetch messages for the existing chat room
      final response = await supabase
          .from('messages')
          .select('id, content, user_id, created_at')
          .eq('room_id', widget.chatRoomId)
          .order('created_at', ascending: true);

      setState(() {
        _messages =
            response != null ? List<Map<String, dynamic>>.from(response) : [];
        isLoading = false;
      });

      if (_messages.isNotEmpty) {
        Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
      }
    } catch (e) {
      print('Error fetching messages: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching messages: $e')),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        try {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } catch (e) {
          print('Error scrolling to bottom: $e');
        }
      });
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    try {
      final currentUserId = supabase.auth.currentUser?.id;

      // Get sender's name first
      String senderName = '';

      // Try to find in familymember table
      final senderInfo = await supabase
          .from('familymember')
          .select('first_name, last_name')
          .filter('user_id', 'eq', currentUserId)
          .maybeSingle();

      if (senderInfo == null) {
        // If not found in familymember, check Local_Cook table
        final cookInfo = await supabase
            .from('Local_Cook')
            .select('first_name, last_name')
            .filter('user_id', 'eq', currentUserId)
            .maybeSingle();

        if (cookInfo != null) {
          senderName =
              '${cookInfo['first_name']} ${cookInfo['last_name']}'.trim();
        }
      } else {
        senderName =
            '${senderInfo['first_name']} ${senderInfo['last_name']}'.trim();
      }

      await supabase.from('messages').insert({
        'content': messageContent,
        'room_id': widget.chatRoomId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Update last_message_at in chat_room
      await supabase.from('chat_room').update({
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('room_id', widget.chatRoomId);

      // Get chat room details to determine recipient
      final chatRoomResponse = await supabase.from('chat_room').select('''
          familymember_id,
          localcookid,
          Local_Cook:localcookid(user_id),
          familymember:familymember_id(user_id)
        ''').eq('room_id', widget.chatRoomId).single();

      if (chatRoomResponse != null) {
        String? recipientUserId;
        final cookUserId = chatRoomResponse['Local_Cook']?['user_id'];
        final familyUserId = chatRoomResponse['familymember']?['user_id'];

        if (currentUserId == familyUserId) {
          recipientUserId = cookUserId;
        } else {
          recipientUserId = familyUserId;
        }

        if (recipientUserId != null) {
          print('Sending notification to recipient: $recipientUserId');
          // Create notification with correct sender name
          await supabase.rpc(
            'create_notification',
            params: {
              'p_recipient_id': recipientUserId,
              'p_sender_id': currentUserId,
              'p_title': 'New Message',
              'p_message': 'You have a new message from $senderName',
              'p_notification_type': 'message',
              'p_related_id': widget.chatRoomId,
            },
          );
        }
      }

      _fetchMessages(); // Fetch messages immediately after sending
    } catch (e) {
      print('Error details: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending message: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = supabase.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipientName),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: _messages.length,
                    padding: const EdgeInsets.all(10.0),
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMine = message['user_id'] == currentUser?.id;

                      return Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          margin: const EdgeInsets.symmetric(
                            vertical: 5.0,
                            horizontal: 10.0,
                          ),
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: isMine ? Colors.green : Colors.grey[300],
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            message['content'] ?? '',
                            style: TextStyle(
                              color: isMine ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, -1),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: 'Type a message...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding: const EdgeInsets.all(12),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.send),
                        color: Colors.green,
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
