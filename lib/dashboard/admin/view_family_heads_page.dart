import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewFamilyHeadsPage extends StatefulWidget {
  const ViewFamilyHeadsPage({Key? key}) : super(key: key);

  @override
  _ViewFamilyHeadsPageState createState() => _ViewFamilyHeadsPageState();
}

class _ViewFamilyHeadsPageState extends State<ViewFamilyHeadsPage> {
  List<dynamic> familyHeads = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchFamilyHeads();
  }

  Future<void> _fetchFamilyHeads() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('position', 'Family Head');

      setState(() {
        familyHeads = response as List<dynamic>;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      debugPrint('Error fetching family heads: $e');
    }
  }

  void _showFamilyDetails(BuildContext context, dynamic familyHead) async {
    // Add logic to navigate to details or open dialog (similar to previous implementation)
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Family Heads'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(
                  child: Text(
                    'Error loading data. Please try again.',
                    style: TextStyle(fontSize: 16, color: Colors.red),
                  ),
                )
              : familyHeads.isEmpty
                  ? const Center(
                      child: Text(
                        'No family heads found.',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: familyHeads.length,
                      itemBuilder: (context, index) {
                        final familyHead = familyHeads[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child:
                                  const Icon(Icons.person, color: Colors.green),
                            ),
                            title: Text(
                              '${familyHead['first_name']} ${familyHead['last_name']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Age: ${familyHead['age'] ?? 'N/A'} | City: ${familyHead['city'] ?? 'N/A'}',
                              style: const TextStyle(fontSize: 14),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () =>
                                _showFamilyDetails(context, familyHead),
                          ),
                        );
                      },
                    ),
    );
  }
}
