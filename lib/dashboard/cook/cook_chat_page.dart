import 'package:flutter/material.dart';
import 'package:pamealya/common/chat_room_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CookChatPage extends StatefulWidget {
  final String currentUserId; // Cook's user ID

  const CookChatPage({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _CookChatPageState createState() => _CookChatPageState();
}

class _CookChatPageState extends State<CookChatPage> {
  Future<List<dynamic>> fetchFamilyHeads() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select(
              'familymember_id, first_name, last_name, user_id, is_family_head')
          .eq('is_family_head', true); // Filter by is_family_head = true

      if (response == null) {
        throw Exception('No response received.');
      }
      return response as List<dynamic>; // Casting the result
    } catch (e) {
      throw Exception('Error fetching family heads: $e');
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
      return response as String; // Assuming the RPC returns the chat room ID
    } catch (e) {
      throw Exception('Error creating or retrieving chat room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Select family heads to chat'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchFamilyHeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No family heads available.'));
          }

          final familyHeads = snapshot.data!;
          return ListView.builder(
            itemCount: familyHeads.length,
            itemBuilder: (context, index) {
              final familyHead = familyHeads[index];
              return ListTile(
                title: Text(
                    '${familyHead['first_name']} ${familyHead['last_name']}'),
                onTap: () async {
                  try {
                    final chatRoomId = await getOrCreateChatRoom(
                      familyHead['user_id'], // Family head's user ID
                      widget.currentUserId, // Cook's user ID
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatRoomPage(
                          chatRoomId: chatRoomId,
                          recipientName:
                              '${familyHead['first_name']} ${familyHead['last_name']}',
                        ),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error opening chat room: $e')),
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
