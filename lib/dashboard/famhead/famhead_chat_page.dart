import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart';

class FamHeadChatPage extends StatelessWidget {
  final String currentUserId;
  final String currentUserUsername;

  const FamHeadChatPage({
    Key? key,
    required this.currentUserId,
    required this.currentUserUsername,
  }) : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchAcceptedCooks() async {
    final response = await Supabase.instance.client
        .from('bookingrequest')
        .select('localcook_id, famhead_id')
        .eq('_isBookingAccepted', true)
        .eq('famhead_id', currentUserId);

    if (response != null) {
      return List<Map<String, dynamic>>.from(response as List);
    } else {
      throw Exception('Error fetching accepted bookings.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAcceptedCooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No accepted bookings available to chat.'));
          }

          final cooks = snapshot.data!;
          return ListView.builder(
            itemCount: cooks.length,
            itemBuilder: (context, index) {
              final cook = cooks[index];
              final cookUserId = cook['localcook_id'];

              if (cookUserId == null) {
                return const ListTile(
                  title: Text('Error: Missing cook information'),
                );
              }

              return ListTile(
                title: Text(
                    'Cook $cookUserId'), // Replace with actual cook name if available
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateChatPage(
                        currentUserId: currentUserId,
                        currentUserUsername: currentUserUsername,
                        otherUserId: cookUserId,
                        otherUserName:
                            'Cook $cookUserId', // Replace with cook name if available
                        isCookInitiated: false,
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
