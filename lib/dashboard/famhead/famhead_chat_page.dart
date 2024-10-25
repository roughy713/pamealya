import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart'; // Assuming this is where PrivateChatPage is located

class FamHeadChatPage extends StatelessWidget {
  final String currentUserId;

  const FamHeadChatPage({Key? key, required this.currentUserId})
      : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchCooks() async {
    // Querying the "Local_Cook_Approved" table to fetch cooks
    final response =
        await Supabase.instance.client.from('Local_Cook_Approved').select();

    // Print the entire response for debugging purposes
    print("Fetched cooks: $response");

    // Check if the response has data
    if (response != null) {
      return List<Map<String, dynamic>>.from(response as List);
    } else {
      throw Exception('Error fetching cooks.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat with Cooks'),
      ),
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
              final cookUserId = cook['localcookid']; // Fetching cook's UUID
              final cookFirstName = cook['first_name'];
              final cookLastName = cook['last_name'];

              // Log the fetched values for debugging
              print('Cook #$index ID: $cookUserId');
              print('Cook #$index First Name: $cookFirstName');
              print('Cook #$index Last Name: $cookLastName');

              // Check if any required field is null
              if (cookUserId == null ||
                  cookFirstName == null ||
                  cookLastName == null) {
                return ListTile(
                  title: Text('Error: Missing cook information'),
                  subtitle:
                      Text('One or more fields are missing for this cook.'),
                );
              }

              return ListTile(
                title: Text('$cookFirstName $cookLastName'),
                onTap: () {
                  // Navigate to PrivateChatPage when a cook is selected
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateChatPage(
                        currentUserId: currentUserId,
                        otherUserId: cookUserId, // Pass the valid cook's UUID
                        otherUserName:
                            '$cookFirstName $cookLastName', // Pass the cook's full name
                        isCookInitiated:
                            false, // Family head initiates the chat
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
