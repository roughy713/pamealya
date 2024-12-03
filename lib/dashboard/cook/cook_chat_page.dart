import 'package:flutter/material.dart';
import 'package:pamealya/common/chat_room_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CookChatPage extends StatefulWidget {
  final String currentUserId;

  const CookChatPage({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<CookChatPage> createState() => _CookChatPageState();
}

class _CookChatPageState extends State<CookChatPage> {
  Future<List<Map<String, dynamic>>> fetchFamilyHeads() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select('familymember_id, first_name, last_name')
          .eq('is_family_head', true);

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch family heads: $error');
    }
  }

  Future<String> getOrCreateChatRoom(String familyMemberId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_or_create_chat_room',
        params: {
          'familymember_id': familyMemberId,
          'localcook_id': widget.currentUserId,
        },
      );
      return response as String;
    } catch (error) {
      throw Exception('Failed to create or get chat room: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Family Head to Chat'),
        automaticallyImplyLeading: false, // Removes the back arrow
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchFamilyHeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      familyHead['familymember_id'],
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
                      SnackBar(content: Text('Failed to open chat room: $e')),
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
