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

  Future<List<Map<String, dynamic>>> _fetchCooks() async {
    final response = await Supabase.instance.client
        .from('Local_Cook_Approved')
        .select('localcookid, first_name, last_name');
    print("Fetched cooks: $response");

    if (response != null) {
      return List<Map<String, dynamic>>.from(response as List);
    } else {
      throw Exception('Error fetching cooks.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchCooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
                child: Text('No cooks available to chat with.'));
          }

          final cooks = snapshot.data!;
          return ListView.builder(
            itemCount: cooks.length,
            itemBuilder: (context, index) {
              final cook = cooks[index];
              final cookUserId = cook['localcookid'];
              final cookFirstName = cook['first_name'];
              final cookLastName = cook['last_name'];

              print('Cook #$index ID: $cookUserId');
              print('Cook #$index First Name: $cookFirstName');
              print('Cook #$index Last Name: $cookLastName');

              if (cookUserId == null ||
                  cookFirstName == null ||
                  cookLastName == null) {
                return const ListTile(
                  title: Text('Error: Missing cook information'),
                  subtitle:
                      Text('One or more fields are missing for this cook.'),
                );
              }

              return ListTile(
                title: Text('$cookFirstName $cookLastName'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateChatPage(
                        currentUserId: currentUserId,
                        currentUserUsername: currentUserUsername,
                        otherUserId: cookUserId,
                        otherUserName: '$cookFirstName $cookLastName',
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
