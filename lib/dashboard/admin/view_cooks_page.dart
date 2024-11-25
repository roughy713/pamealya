import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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

  void _viewCookDetails(dynamic cook) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CookDetailsPage(cook: cook),
      ),
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

class CookDetailsPage extends StatelessWidget {
  final dynamic cook;

  const CookDetailsPage({super.key, required this.cook});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${cook['first_name']} ${cook['last_name']}'),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 8.0,
            shadowColor: Colors.greenAccent,
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.green[100],
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '${cook['first_name']} ${cook['last_name']}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Age: ${cook['age']}',
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  const Divider(thickness: 1, height: 40),
                  buildDetailRow('Gender:', cook['gender']),
                  buildDetailRow('Date of Birth:', cook['dateofbirth']),
                  buildDetailRow('Phone:', cook['phone']),
                  buildDetailRow('Address:',
                      '${cook['address_line1']}, ${cook['barangay']}, ${cook['city']}, ${cook['province']}'),
                  buildDetailRow('Postal Code:', cook['postal_code']),
                  buildDetailRow('Availability:',
                      '${cook['availability_days']} from ${cook['time_available_from']} to ${cook['time_available_to']}'),
                  const SizedBox(height: 8),
                  buildCertificationSection(cook['certifications']),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildCertificationSection(String? certificationUrl) {
    return certificationUrl == null || certificationUrl.isEmpty
        ? const Text(
            'Certifications: None',
            style: TextStyle(fontSize: 16, color: Colors.black54),
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Certifications:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  // Handle certification file opening
                  // Add logic to open or download the certification file
                },
                child: Text(
                  certificationUrl,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.blue,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          );
  }
}
