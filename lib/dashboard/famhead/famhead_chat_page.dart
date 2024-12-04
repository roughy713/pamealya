import 'package:pamealya/common/chat_room_page.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamHeadChatPage extends StatefulWidget {
  final String currentUserId; // Family member's user ID

  const FamHeadChatPage({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _FamHeadChatPageState createState() => _FamHeadChatPageState();
}

class _FamHeadChatPageState extends State<FamHeadChatPage> {
  Future<List<dynamic>> fetchCooks() async {
    try {
      final response = await Supabase.instance.client
          .from('Local_Cook')
          .select('localcookid, first_name, last_name, user_id');

      if (response == null) {
        throw Exception('No response received.');
      }
      return response as List<dynamic>; // Casting the result
    } catch (e) {
      throw Exception('Error fetching cooks: $e');
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
        title: const Text('Select cooks to chat'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchCooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(child: Text('No cooks available.'));
          }

          final cooks = snapshot.data!;
          return ListView.builder(
            itemCount: cooks.length,
            itemBuilder: (context, index) {
              final cook = cooks[index];
              return ListTile(
                title: Text('${cook['first_name']} ${cook['last_name']}'),
                onTap: () async {
                  try {
                    final chatRoomId = await getOrCreateChatRoom(
                      widget.currentUserId, // Family member's user ID
                      cook['user_id'], // Cook's user ID
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
