import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CookChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserUsername;

  const CookChatPage({
    Key? key,
    required this.currentUserId,
    required this.currentUserUsername,
  }) : super(key: key);

  @override
  _CookChatPageState createState() => _CookChatPageState();
}

class _CookChatPageState extends State<CookChatPage> {
  late Future<List<Map<String, dynamic>>> _familyHeadsFuture;

  @override
  void initState() {
    super.initState();
    _familyHeadsFuture = fetchFamilyHeads();
  }

  Future<List<Map<String, dynamic>>> fetchFamilyHeads() async {
    try {
      // Fetch all family heads from the familymember table
      final response = await Supabase.instance.client
          .from('familymember')
          .select('user_id, first_name, last_name')
          .eq('is_family_head', true); // Filter for family heads

      if (response.isEmpty) {
        return [];
      }

      return List<Map<String, dynamic>>.from(response);
    } catch (error) {
      throw Exception('Failed to fetch family heads: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a Family Head to Chat'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _familyHeadsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final familyHeads = snapshot.data!;
          if (familyHeads.isEmpty) {
            return const Center(child: Text('No family heads available.'));
          }

          return ListView.builder(
            itemCount: familyHeads.length,
            itemBuilder: (context, index) {
              final familyHead = familyHeads[index];
              return ListTile(
                title: Text(
                    '${familyHead['first_name']} ${familyHead['last_name']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatRoomPage(
                        roomId:
                            '${widget.currentUserId}_${familyHead['user_id']}',
                        recipientName:
                            '${familyHead['first_name']} ${familyHead['last_name']}',
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class ChatRoomPage extends StatelessWidget {
  final String roomId;
  final String recipientName;

  const ChatRoomPage({
    Key? key,
    required this.roomId,
    required this.recipientName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with $recipientName'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Text('Messages will be displayed here for $roomId.'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration:
                        const InputDecoration(hintText: 'Type a message'),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: () {
                    // Handle message sending
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
