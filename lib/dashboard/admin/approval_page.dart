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
      final response =
          await Supabase.instance.client.from('Local_Cook').select();

      setState(() {
        cooks = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<void> _approveCook(Map<String, dynamic> cook) async {
    try {
      await Supabase.instance.client.from('Local_Cook_Approved').insert({
        ...cook,
      });
      await Supabase.instance.client
          .from('Local_Cook')
          .delete()
          .eq('localcookid', cook['localcookid']);
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving cook: $e')),
      );
    }
  }

  Future<void> _rejectCook(Map<String, dynamic> cook) async {
    try {
      await Supabase.instance.client
          .from('Local_Cook')
          .delete()
          .eq('localcookid', cook['localcookid']);
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting cook: $e')),
      );
    }
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
                      subtitle: Text('Email: ${cook['email']}'),
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
