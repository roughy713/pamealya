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
      final currentUserId = Supabase.instance.client.auth.currentUser?.id;
      print('Current user ID: $currentUserId');

      // Get sender's name first
      String senderName = '';

      // Try to find in familymember table using actual UUID comparison
      final senderInfo = await Supabase.instance.client
          .from('familymember')
          .select('first_name, last_name')
          .filter('user_id', 'eq', currentUserId) // Changed to filter method
          .maybeSingle();

      if (senderInfo == null) {
        // If not found in familymember, check Local_Cook table
        final cookInfo = await Supabase.instance.client
            .from('Local_Cook')
            .select('first_name, last_name')
            .filter('user_id', 'eq', currentUserId) // Changed to filter method
            .maybeSingle();

        if (cookInfo != null) {
          senderName =
              '${cookInfo['first_name']} ${cookInfo['last_name']}'.trim();
        }
      } else {
        senderName =
            '${senderInfo['first_name']} ${senderInfo['last_name']}'.trim();
      }

      // Send the message
      await Supabase.instance.client.from('messages').insert({
        'content': messageContent,
        'room_id': widget.chatRoomId,
        'user_id': currentUserId,
      });

      // Get chat room details
      final chatRoomResponse =
          await Supabase.instance.client.from('chat_room').select('''
          familymember_id,
          localcookid,
          Local_Cook:localcookid(user_id),
          familymember:familymember_id(user_id)
        ''').eq('room_id', widget.chatRoomId).single();

      print('Chat room response: $chatRoomResponse');

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
          await Supabase.instance.client.rpc(
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
    } catch (e) {
      print('Error details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending message: $e')),
      );
    }
  }

  Future<void> ensureRoomExists(String roomId) async {
    try {
      final response = await Supabase.instance.client
          .from('chat_room') // Changed from 'rooms' to 'chat_room'
          .select('*')
          .eq('room_id', roomId)
          .maybeSingle();

      if (response == null) {
        // Room doesn't exist; create it
        await Supabase.instance.client.from('chat_room').insert({
          'room_id': roomId,
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
        title: Text('${widget.recipientName}'),
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
