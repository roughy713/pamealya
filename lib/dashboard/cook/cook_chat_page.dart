import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart';

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
  List<Map<String, dynamic>>? _familyHeads;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyHeads();
  }

  Future<void> _loadFamilyHeads() async {
    try {
      final response = await Supabase.instance.client
          .from('Family_Head')
          .select(
              'famheadid, first_name, last_name'); // Fetch first and last names

      if (response != null) {
        setState(() {
          _familyHeads = List<Map<String, dynamic>>.from(response as List);
          _isLoading = false;
        });
      }
    } catch (error) {
      print('Error fetching family heads: $error');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToChat(String famHeadUserId, String famHeadFullName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatPage(
          currentUserId: widget.currentUserId,
          currentUserUsername: widget.currentUserUsername,
          otherUserId: famHeadUserId,
          otherUserName: famHeadFullName,
          isCookInitiated: true,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Family Head'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _familyHeads == null || _familyHeads!.isEmpty
              ? const Center(
                  child: Text('No family heads available to chat with.'))
              : ListView.builder(
                  itemCount: _familyHeads!.length,
                  itemBuilder: (context, index) {
                    final famHead = _familyHeads![index];
                    final famHeadUserId = famHead['famheadid'];
                    final famHeadFirstName = famHead['first_name'];
                    final famHeadLastName = famHead['last_name'];

                    if (famHeadUserId == null ||
                        famHeadFirstName == null ||
                        famHeadLastName == null) {
                      return const ListTile(
                        title: Text('Error: Missing family head information'),
                      );
                    }

                    final famHeadFullName =
                        '$famHeadFirstName $famHeadLastName';

                    return ListTile(
                      title: Text(famHeadFullName),
                      onTap: () =>
                          _navigateToChat(famHeadUserId, famHeadFullName),
                    );
                  },
                ),
    );
  }
}
