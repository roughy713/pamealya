import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewFamilyHeadsPage extends StatefulWidget {
  const ViewFamilyHeadsPage({super.key});

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
      debugPrint('Fetching family heads...');

      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('position', 'Family Head');

      setState(() {
        familyHeads = response as List<dynamic>;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching family heads: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  Future<List<dynamic>> _fetchFamilyMembers(dynamic familyHead) async {
    try {
      debugPrint('Fetching family members...');
      debugPrint('Family head member ID: ${familyHead['familymember_id']}');

      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('family_head',
              '${familyHead['first_name']} ${familyHead['last_name']}')
          .neq('familymember_id', familyHead['familymember_id']);

      debugPrint('Family members response: $response');
      return response as List<dynamic>;
    } catch (e) {
      debugPrint('Error in _fetchFamilyMembers: $e');
      return [];
    }
  }

  Widget _buildDetailRow(String label, dynamic value) {
    String displayValue = value?.toString() ?? 'N/A';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _showFamilyDetails(BuildContext context, dynamic familyHead) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      final familyMembers = await _fetchFamilyMembers(familyHead);

      if (!context.mounted) return;
      Navigator.of(context).pop();

      if (!context.mounted) return;

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${familyHead['first_name']} ${familyHead['last_name']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                    const Divider(),
                    Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.green[100],
                        child: const Icon(Icons.person,
                            size: 50, color: Colors.green),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Family Head Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildDetailRow('Age:', familyHead['age']),
                    _buildDetailRow('Gender:', familyHead['gender']),
                    _buildDetailRow('Phone:', familyHead['phone']),
                    _buildDetailRow('Date of Birth:', familyHead['dob']),
                    _buildDetailRow('Religion:', familyHead['religion']),
                    _buildDetailRow('Address:', familyHead['address_line1']),
                    _buildDetailRow('Barangay:', familyHead['barangay']),
                    _buildDetailRow('City:', familyHead['city']),
                    _buildDetailRow('Province:', familyHead['province']),
                    _buildDetailRow('Postal:', familyHead['postal_code']),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Family Members',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          '(${familyMembers.length} members)',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (familyMembers.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No family members found',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: familyMembers.length,
                        itemBuilder: (context, index) {
                          final member = familyMembers[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.green[100],
                                child: const Icon(Icons.person,
                                    color: Colors.green),
                              ),
                              title: Text(
                                '${member['first_name']} ${member['last_name']}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(member['position'] ?? 'Member'),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      _buildDetailRow('Age:', member['age']),
                                      _buildDetailRow(
                                          'Gender:', member['gender']),
                                      _buildDetailRow(
                                          'Date of Birth:', member['dob']),
                                      _buildDetailRow(
                                          'Religion:', member['religion']),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error in showing family details: $e');
      if (context.mounted) {
        Navigator.of(context).pop();
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
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
                              'Age: ${familyHead['age']} | City: ${familyHead['city']}',
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
