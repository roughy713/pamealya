import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewCooksPage extends StatefulWidget {
  const ViewCooksPage({super.key});

  @override
  _ViewCooksPageState createState() => _ViewCooksPageState();
}

class _ViewCooksPageState extends State<ViewCooksPage> {
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
          .eq('is_accepted', true);
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

  Widget _buildDetailRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
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
              value ?? 'N/A',
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  void _viewCookDetails(dynamic cook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${cook['first_name']} ${cook['last_name']}',
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

                  // Profile Avatar
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.green[100],
                      child: const Icon(Icons.person,
                          size: 50, color: Colors.green),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Personal Information Section
                  const Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow('Age:', cook['age']?.toString()),
                  _buildDetailRow('Gender:', cook['gender']),
                  _buildDetailRow('Date of Birth:', cook['dateofbirth']),
                  _buildDetailRow('Phone:', cook['phone']),

                  const SizedBox(height: 20),
                  // Address Information Section
                  const Text(
                    'Address Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow('Street:', cook['address_street']),
                  _buildDetailRow('Barangay:', cook['barangay']),
                  _buildDetailRow('City:', cook['city']),
                  _buildDetailRow('Province:', cook['province']),
                  _buildDetailRow(
                      'Postal Code:', cook['postal_code']?.toString()),

                  const SizedBox(height: 20),
                  // Availability Section
                  const Text(
                    'Availability',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildDetailRow('Days:', cook['availability_days']),
                  _buildDetailRow('Time:',
                      '${cook['time_available_from'] ?? 'N/A'} - ${cook['time_available_to'] ?? 'N/A'}'),

                  const SizedBox(height: 20),
                  // Certifications Section
                  const Text(
                    'Certifications',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (cook['certifications'] != null &&
                      cook['certifications'].isNotEmpty)
                    InkWell(
                      onTap: () async {
                        final url = cook['certifications'];
                        if (url != null && url.isNotEmpty) {
                          try {
                            await launchUrl(Uri.parse(url));
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text('Could not open certification')),
                              );
                            }
                          }
                        }
                      },
                      child: Row(
                        children: [
                          const Icon(Icons.file_present, color: Colors.blue),
                          const SizedBox(width: 8),
                          Text(
                            'View Certification',
                            style: TextStyle(
                              color: Colors.blue[700],
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    const Text('No certifications available'),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Cooks'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading cooks'))
              : cooks.isEmpty
                  ? const Center(child: Text('No cooks found'))
                  : ListView.builder(
                      itemCount: cooks.length,
                      itemBuilder: (context, index) {
                        final cook = cooks[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 8.0, horizontal: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[100],
                              child:
                                  const Icon(Icons.person, color: Colors.green),
                            ),
                            title: Text(
                              '${cook['first_name']} ${cook['last_name']}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                                'Age: ${cook['age']} | City: ${cook['city']}'),
                            trailing: const Icon(Icons.arrow_forward_ios),
                            onTap: () => _viewCookDetails(cook),
                          ),
                        );
                      },
                    ),
    );
  }
}
