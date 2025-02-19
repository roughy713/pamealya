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
      // Get family heads who have accepted bookings with this cook
      final response = await Supabase.instance.client
          .from('familymember')
          .select('''
            familymember_id,
            first_name,
            last_name,
            user_id,
            is_family_head,
            bookingrequest!inner (
              status,
              localcookid,
              _isBookingAccepted,
              is_cook_booking
            )
          ''')
          .eq('is_family_head', true)
          .eq('bookingrequest.status', 'accepted')
          .eq('bookingrequest._isBookingAccepted', true)
          .eq('bookingrequest.is_cook_booking', true)
          .eq(
              'bookingrequest.localcookid',
              (await Supabase.instance.client
                  .from('Local_Cook')
                  .select('localcookid')
                  .eq('user_id', widget.currentUserId)
                  .single())['localcookid']);

      if (response == null) {
        throw Exception('No response received.');
      }

      // Remove duplicates based on familymember_id
      final Map<String, dynamic> uniqueFamilyHeads = {};
      for (var familyHead in response as List<dynamic>) {
        uniqueFamilyHeads[familyHead['familymember_id']] = familyHead;
      }

      return uniqueFamilyHeads.values.toList();
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
      return response as String;
    } catch (e) {
      throw Exception('Error creating or retrieving chat room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat with Family Heads'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchFamilyHeads(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No family heads have accepted bookings yet.'));
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
                      familyHead['user_id'],
                      widget.currentUserId,
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
