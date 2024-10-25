import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../shared/private_chat.dart';

class CookChatPage extends StatefulWidget {
  final String currentUserId; // Cook's user ID

  const CookChatPage({Key? key, required this.currentUserId}) : super(key: key);

  @override
  _CookChatPageState createState() => _CookChatPageState();
}

class _CookChatPageState extends State<CookChatPage> {
  List<Map<String, dynamic>>? _familyHeads;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFamilyHeads(); // Load data once in initState
  }

  // Load family heads data
  Future<void> _loadFamilyHeads() async {
    try {
      final response =
          await Supabase.instance.client.from('Family_Head').select();
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

  // Direct navigation to PrivateChatPage
  void _navigateToChat(String famHeadUserId, String famHeadName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PrivateChatPage(
          currentUserId: widget.currentUserId,
          otherUserId: famHeadUserId,
          otherUserName: famHeadName,
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

                    final famHeadName = '$famHeadFirstName $famHeadLastName';

                    return ListTile(
                      title: Text(famHeadName),
                      onTap: () => _navigateToChat(famHeadUserId, famHeadName),
                    );
                  },
                ),
    );
  }
}
