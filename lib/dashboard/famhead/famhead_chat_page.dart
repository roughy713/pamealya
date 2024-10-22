import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart';

class FamHeadChatPage extends StatelessWidget {
  final String currentUserId;

  const FamHeadChatPage({Key? key, required this.currentUserId})
      : super(key: key);

  Future<List<Map<String, dynamic>>> _fetchCooks() async {
    // Querying the "Local_Cook_Approved" table to fetch cooks
    final response =
        await Supabase.instance.client.from('Local_Cook_Approved').select();

    // Check if the response data is not empty
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
              return ListTile(
                title: Text('${cook['first_name']} ${cook['last_name']}'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PrivateChatPage(
                        currentUserId: currentUserId,
                        otherUserId: cook[
                            'id'], // Replace 'id' with the correct column name for cook's ID
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
