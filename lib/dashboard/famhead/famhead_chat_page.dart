import 'package:flutter/material.dart';
import 'package:pamealya/common/chat_room_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FamHeadChatPage extends StatefulWidget {
  final String currentUserId;

  const FamHeadChatPage({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  State<FamHeadChatPage> createState() => _FamHeadChatPageState();
}

class _FamHeadChatPageState extends State<FamHeadChatPage> {
  Future<List<Map<String, dynamic>>> fetchCooks() async {
    try {
      final response = await Supabase.instance.client
          .from('Local_Cook')
          .select('localcookid, first_name, last_name');

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch cooks: $error');
    }
  }

  Future<String> getOrCreateChatRoom(String localCookId) async {
    try {
      final response = await Supabase.instance.client.rpc(
        'get_or_create_chat_room',
        params: {
          'familymember_id': widget.currentUserId,
          'localcook_id': localCookId,
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
        title: const Text('Select a Cook to Chat'),
        automaticallyImplyLeading: false, // Removes the back arrow
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchCooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
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
                      cook['localcookid'],
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
