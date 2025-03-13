import 'package:pamealya/common/chat_room_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamHeadChatPage extends StatefulWidget {
  final String currentUserId;

  const FamHeadChatPage({
    super.key,
    required this.currentUserId,
  });

  @override
  _FamHeadChatPageState createState() => _FamHeadChatPageState();
}

class _FamHeadChatPageState extends State<FamHeadChatPage> {
  Future<List<Map<String, dynamic>>> fetchCooksWithUnreadCount() async {
    try {
      print('Fetching cooks for user ID: ${widget.currentUserId}');

      // First get the familymember_id
      final familyMemberResponse = await Supabase.instance.client
          .from('bookingrequest')
          .select('familymember_id')
          .eq('user_id', widget.currentUserId)
          .eq('_isBookingAccepted', true)
          .eq('is_cook_booking', true)
          .limit(1)
          .single();

      final String familyMemberId = familyMemberResponse['familymember_id'];
      print('Family Member ID: $familyMemberId');

      // First fetch the cooks
      final cooksResponse = await Supabase.instance.client
          .from('Local_Cook')
          .select('''
            localcookid,
            first_name,
            last_name,
            user_id,
            bookingrequest!inner (
              status,
              _isBookingAccepted,
              is_cook_booking
            )
          ''')
          .eq('bookingrequest.familymember_id', familyMemberId)
          .eq('bookingrequest._isBookingAccepted', true)
          .eq('bookingrequest.is_cook_booking', true);

      final List<Map<String, dynamic>> processedCooks = [];

      // For each cook, fetch their chat room and messages separately
      for (var cook in cooksResponse as List<dynamic>) {
        try {
          // Get the chat room for this cook and family member
          final chatRoomResponse = await Supabase.instance.client
              .from('chat_room')
              .select()
              .or('participant1_id.eq.${cook['user_id']},participant2_id.eq.${cook['user_id']}')
              .or('participant1_id.eq.${widget.currentUserId},participant2_id.eq.${widget.currentUserId}')
              .single();

          // Fetch messages separately
          final messagesResponse = await Supabase.instance.client
              .from('messages')
              .select()
              .eq('chat_room_id', chatRoomResponse['id'])
              .order('created_at', ascending: false);

          int unreadCount = 0;
          Map<String, dynamic>? lastMessage;

          final messages = messagesResponse as List;

          // Calculate unread messages
          unreadCount = messages
              .where((msg) =>
                  msg['receiver_id'] == widget.currentUserId && !msg['is_read'])
              .length;

          // Get last message
          if (messages.isNotEmpty) {
            lastMessage = {
              'content': messages[0]['content'],
              'timestamp': messages[0]['created_at'],
            };
          }

          processedCooks.add({
            ...cook,
            'unread_count': unreadCount,
            'last_message': lastMessage,
          });
        } catch (e) {
          print('Error processing cook ${cook['localcookid']}: $e');
          // Add cook without message data
          processedCooks.add({
            ...cook,
            'unread_count': 0,
            'last_message': null,
          });
        }
      }

      return processedCooks;
    } catch (e) {
      print('Error in fetchCooksWithUnreadCount: $e');
      throw Exception('Error fetching booked cooks: $e');
    }
  }

  Future<String> getOrCreateChatRoom(
      String familyMemberUserId, String cookUserId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_or_create_chat_room',
        params: {
          'family_member_user_id': familyMemberUserId,
          'cook_user_id': cookUserId,
        },
      );

      if (response == null) {
        throw Exception('No response received from RPC.');
      }
      return response as String;
    } catch (e) {
      throw Exception('Error creating or retrieving chat room: $e');
    }
  }

  String _formatTimestamp(String timestamp) {
    final DateTime messageTime = DateTime.parse(timestamp);
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(messageTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat with Your Booked Cooks'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCooksWithUnreadCount(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'You haven\'t booked any cooks yet.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            );
          }

          final cooks = snapshot.data!;
          return ListView.separated(
            itemCount: cooks.length,
            separatorBuilder: (context, index) => const Divider(
              height: 1,
              color: Colors.grey,
            ),
            itemBuilder: (context, index) {
              final cook = cooks[index];
              final unreadCount = cook['unread_count'] as int;
              final lastMessage = cook['last_message'];

              return ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    cook['first_name'][0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${cook['first_name']} ${cook['last_name']}',
                        style: TextStyle(
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (unreadCount > 0) ...[
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: lastMessage != null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            lastMessage['content'],
                            style: TextStyle(
                              fontWeight: unreadCount > 0
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: unreadCount > 0
                                  ? Colors.black87
                                  : Colors.grey,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatTimestamp(lastMessage['timestamp']),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      )
                    : null,
                onTap: () async {
                  try {
                    final chatRoomId = await getOrCreateChatRoom(
                      widget.currentUserId,
                      cook['user_id'],
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatRoomId: chatRoomId,
                          recipientName:
                              '${cook['first_name']} ${cook['last_name']}',
                        ),
                      ),
                    );
                  } catch (e) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Error'),
                        content: Text('Error opening chat: $e'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
