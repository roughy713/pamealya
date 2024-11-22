import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  List<dynamic> cooks = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchCooks();
  }

  Future<void> _fetchCooks() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      // Fetch cooks where is_accepted is FALSE
      final response = await Supabase.instance.client
          .from('Local_Cook')
          .select()
          .eq('is_accepted', false);

      setState(() {
        cooks = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cooks: $e')),
      );
    }
  }

  Future<void> _approveCook(Map<String, dynamic> cook) async {
    try {
      // Update is_accepted to TRUE
      await Supabase.instance.client
          .from('Local_Cook')
          .update({'is_accepted': true}).eq('localcookid', cook['localcookid']);
      await _showDialog('Success', 'Cook successfully approved!');
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving cook: $e')),
      );
    }
  }

  Future<void> _rejectCook(Map<String, dynamic> cook) async {
    try {
      // Delete the cook from the table
      await Supabase.instance.client
          .from('Local_Cook')
          .delete()
          .eq('localcookid', cook['localcookid']);
      await _showDialog('Success', 'Cook successfully rejected!');
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting cook: $e')),
      );
    }
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Page')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading data'))
              : ListView.builder(
                  itemCount: cooks.length,
                  itemBuilder: (context, index) {
                    final cook = cooks[index];
                    return ListTile(
                      title: Text('${cook['first_name']} ${cook['last_name']}'),
                      subtitle: Text('Phone: ${cook['phone']}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => _approveCook(cook),
                          ),
                          IconButton(
                            icon: const Icon(Icons.clear, color: Colors.red),
                            onPressed: () => _rejectCook(cook),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
