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
      print('Fetching cooks for user ID: ${widget.currentUserId}');

      // First get the familymember_id for this user
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

      // Now fetch the cooks with all required conditions
      final response = await Supabase.instance.client
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

      if (response == null) {
        throw Exception('No response received.');
      }

      print('Raw response: $response');

      final Map<String, dynamic> uniqueCooks = {};
      for (var cook in response as List<dynamic>) {
        uniqueCooks[cook['localcookid']] = cook;
      }

      final result = uniqueCooks.values.toList();
      print('Processed cooks: $result');

      return result;
    } catch (e) {
      print('Error in fetchCooks: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Chat with Your Booked Cooks'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: fetchCooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('You haven\'t booked any cooks yet.'));
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
