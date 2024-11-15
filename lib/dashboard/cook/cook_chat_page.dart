import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart';

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
  Future<List<Map<String, dynamic>>> _fetchAcceptedFamilyHeads() async {
    final response = await Supabase.instance.client
        .from('bookingrequest')
        .select('famhead_id, localcook_id')
        .eq('_isBookingAccepted', true)
        .eq('localcook_id', widget.currentUserId);

    return List<Map<String, dynamic>>.from(response as List);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAcceptedFamilyHeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No family heads available to chat with.'));
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
                title: Text(
                    'Family Head $famHeadUserId'), // Replace with actual family head name if available
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateChatPage(
                        currentUserId: widget.currentUserId,
                        currentUserUsername: widget.currentUserUsername,
                        otherUserId: famHeadUserId,
                        otherUserName:
                            'Family Head $famHeadUserId', // Replace with actual name if available
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
