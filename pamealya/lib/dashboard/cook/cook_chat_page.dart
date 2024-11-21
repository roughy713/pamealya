import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart'; // Ensure this is the correct import path for PrivateChatPage

class CookChatPage extends StatefulWidget {
  final String currentUserId;
  final String currentUserUsername;

  const CookChatPage({
    super.key,
    required this.currentUserId,
    required this.currentUserUsername,
  });

  @override
  _CookChatPageState createState() => _CookChatPageState();
}

class _CookChatPageState extends State<CookChatPage> {
  final supabase = Supabase.instance.client;

  Future<List<Map<String, dynamic>>> _fetchAcceptedFamilyHeads() async {
    try {
      final response = await supabase
          .from('bookingrequest')
          .select('famhead_id, localcook_id')
          .eq('_isBookingAccepted', true)
          .eq('localcook_id', widget.currentUserId);

      return List<Map<String, dynamic>>.from(response as List);
    } catch (e) {
      debugPrint('Error fetching family heads: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        backgroundColor: Colors.green[600],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAcceptedFamilyHeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Failed to load chats.'),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[600],
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No family heads available to chat with.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final familyHeads = snapshot.data!;
          return ListView.builder(
            itemCount: familyHeads.length,
            itemBuilder: (context, index) {
              final famHead = familyHeads[index];
              final famHeadUserId = famHead['famhead_id'];

              if (famHeadUserId == null) {
                return const ListTile(
                  title: Text('Error: Missing family head information'),
                );
              }

              return ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                title: Text(
                  'Family Head: $famHeadUserId', // Replace with actual name if available
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Tap to start chatting'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateChatPage(
                        currentUserId: widget.currentUserId,
                        currentUserUsername: widget.currentUserUsername,
                        otherUserId: famHeadUserId,
                        otherUserName:
                            'Family Head: $famHeadUserId', // Replace with actual name if available
                        isCookInitiated: true,
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
