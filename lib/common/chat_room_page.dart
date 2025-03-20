import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

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
  final ScrollController _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  final supabase = Supabase.instance.client;
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _subscribeToMessages();
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchMessages() async {
    try {
      final response = await supabase
          .from('messages')
          .select('''
            id, 
            content, 
            user_id, 
            created_at,
            is_read,
            read_at
          ''')
          .eq('room_id', widget.chatRoomId)
          .order('created_at', ascending: true);

      if (response != null) {
        setState(() {
          _messages.clear();
          _messages.addAll(List<Map<String, dynamic>>.from(response));
        });

        if (_isFirstLoad) {
          _isFirstLoad = false;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController
                  .jumpTo(_scrollController.position.maxScrollExtent);
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching messages: $e')),
        );
      }
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final currentUserId = supabase.auth.currentUser?.id;
      if (currentUserId == null) return;

      final currentTime = DateTime.now().toIso8601String();

      final unreadMessages = _messages
          .where((msg) =>
              msg['user_id'] != currentUserId && !(msg['is_read'] ?? false))
          .toList();

      if (unreadMessages.isNotEmpty) {
        await supabase
            .from('messages')
            .update({
              'is_read': true,
              'read_at': currentTime,
            })
            .eq('room_id', widget.chatRoomId)
            .eq('is_read', false)
            .neq('user_id', currentUserId);

        setState(() {
          for (var msg in _messages) {
            if (msg['user_id'] != currentUserId && !(msg['is_read'] ?? false)) {
              msg['is_read'] = true;
              msg['read_at'] = currentTime;
            }
          }
        });
      }
    } catch (e) {}
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    }
  }

  void _subscribeToMessages() {
    supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('room_id', widget.chatRoomId)
        .listen((List<Map<String, dynamic>> payload) {
          for (final newMessage in payload) {
            int existingIndex =
                _messages.indexWhere((msg) => msg['id'] == newMessage['id']);

            setState(() {
              if (existingIndex != -1) {
                _messages[existingIndex] = newMessage;
              } else {
                _messages.add(newMessage);
                if (newMessage['user_id'] != supabase.auth.currentUser?.id) {
                  _markMessagesAsRead();
                }
              }
            });

            if (existingIndex == -1) {
              _scrollToBottom();
            }
          }
        });
  }

  String _formatMessageTime(String? timestamp) {
    if (timestamp == null) return '';
    final dateTime = DateTime.parse(timestamp).toLocal();
    return DateFormat('h:mm a').format(dateTime);
  }

  Widget _buildMessageStatus(Map<String, dynamic> message, bool isMine) {
    final time = _formatMessageTime(message['created_at']);
    final isRead = message['is_read'] ?? false;

    if (isMine) {
      return Container(
        padding: const EdgeInsets.only(top: 2, right: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              time,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            const SizedBox(width: 3),
            if (isRead)
              const Row(
                children: [
                  Icon(Icons.done_all, size: 16, color: Colors.blue),
                  SizedBox(width: 3),
                  Text(
                    'Seen',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue,
                    ),
                  ),
                ],
              )
            else
              const Row(
                children: [
                  Icon(Icons.done, size: 16, color: Colors.grey),
                  SizedBox(width: 3),
                  Text(
                    'Sent',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    } else {
      // For received messages, just show the time
      return Container(
        padding: const EdgeInsets.only(top: 2, left: 2),
        child: Text(
          time,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      );
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    try {
      final currentUserId = supabase.auth.currentUser?.id;

      // Get sender's name
      String senderName = '';
      final senderInfo = await supabase
          .from('familymember')
          .select('first_name, last_name')
          .filter('user_id', 'eq', currentUserId)
          .maybeSingle();

      if (senderInfo == null) {
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

      // Send message
      await supabase.from('messages').insert({
        'content': messageContent,
        'room_id': widget.chatRoomId,
        'user_id': currentUserId,
        'created_at': DateTime.now().toIso8601String(),
        'is_read': false,
        'read_at': null,
      });

      // Update chat room's last message timestamp
      await supabase.from('chat_room').update({
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('room_id', widget.chatRoomId);

      // Get recipient information and send notification
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

        recipientUserId =
            currentUserId == familyUserId ? cookUserId : familyUserId;

        if (recipientUserId != null) {
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
    } catch (e) {
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
      body: Column(
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
                  alignment:
                      isMine ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 5.0,
                      horizontal: 10.0,
                    ),
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Container(
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
                        _buildMessageStatus(message, isMine),
                      ],
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
