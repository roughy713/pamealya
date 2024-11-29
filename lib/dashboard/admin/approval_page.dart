import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http; // Import HTTP package

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({Key? key}) : super(key: key);

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
      final response = await Supabase.instance.client
          .from('Local_Cook')
          .select()
          .eq('is_accepted', false);

      if (response != null) {
        setState(() {
          cooks = response as List<dynamic>;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch cooks');
      }
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

  void _showCookDetailsDialog(BuildContext context, Map<String, dynamic> cook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            height: 500,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person,
                            size: 40, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${cook['first_name']} ${cook['last_name']}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Personal Details',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Gender: ${cook['gender'] ?? 'N/A'}'),
                Text(
                    'Address: ${cook['address_street'] ?? 'N/A'}, Barangay ${cook['barangay'] ?? 'N/A'}'),
                Text('Postal Code: ${cook['postal_code'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                const Text(
                  'Availability',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Days Available: ${cook['availability_days'] ?? 'N/A'}'),
                Text(
                    'Time Available: ${cook['time_available_from'] ?? 'N/A'} - ${cook['time_available_to'] ?? 'N/A'}'),
                const SizedBox(height: 16),
                const Text(
                  'Certification',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final url = cook['certifications'];
                    if (url != null && url.isNotEmpty) {
                      if (await canLaunch(url)) {
                        await launch(url);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Cannot open the certification file')),
                        );
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No certification available')),
                      );
                    }
                  },
                  child: const Text(
                    'View Certification',
                    style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          context,
                          'Are you sure you want to approve this cook?',
                        );
                        if (confirmed) {
                          await _approveCook(cook);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          context,
                          'Are you sure you want to reject this cook?',
                        );
                        if (confirmed) {
                          await _rejectCook(cook);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String message) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmation'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _approveCook(Map<String, dynamic> cook) async {
    try {
      await Supabase.instance.client
          .from('Local_Cook')
          .update({'is_accepted': true}).eq('localcookid', cook['localcookid']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cook successfully approved!')),
      );
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cook successfully rejected!')),
      );
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
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.person, color: Colors.green[700]),
                        ),
                        title: Text(
                          '${cook['first_name']} ${cook['last_name']}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Age: ${cook['age'] ?? 'N/A'} | City: ${cook['address_street'] ?? 'N/A'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCookDetailsDialog(context, cook),
                      ),
                    );
                  },
                ),
    );
  }
}
