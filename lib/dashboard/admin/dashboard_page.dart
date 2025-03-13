import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'approval_page.dart'; // Add the correct import path for Cooks Approval
import 'view_cooks_page.dart'; // Add the correct import path for View Cooks
import 'view_family_heads_page.dart'; // Add the correct import path for View Family Heads

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int cooksRequestCount = 0;
  int approvedCooksCount = 0;
  int familyHeadsCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final supabase = Supabase.instance.client;

    try {
      setState(() {
        isLoading = true;
      });

      // Fetch Cooks Request Count (is_accepted = false)
      final cooksRequestResponse = await supabase
          .from('Local_Cook')
          .select('localcookid')
          .eq('is_accepted', false);

      // Fetch Approved Cooks Count (is_accepted = true)
      final approvedCooksResponse = await supabase
          .from('Local_Cook')
          .select('localcookid')
          .eq('is_accepted', true);

      // Fetch Family Heads Count (position = 'Family Head')
      final familyHeadsResponse = await supabase
          .from('familymember')
          .select('familymember_id')
          .eq('position', 'Family Head');

      setState(() {
        cooksRequestCount = cooksRequestResponse.length;
        approvedCooksCount = approvedCooksResponse.length;
        familyHeadsCount = familyHeadsResponse.length;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

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
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overview',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatusCard(
                        context: context,
                        icon: Icons.pending_actions,
                        label: 'Cooks Request',
                        count: cooksRequestCount,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApprovalPage(),
                            ),
                          );
                        },
                      ),
                      _buildStatusCard(
                        context: context,
                        icon: Icons.check_circle,
                        label: 'Approved Cooks',
                        count: approvedCooksCount,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewCooksPage(),
                            ),
                          );
                        },
                      ),
                      _buildStatusCard(
                        context: context,
                        icon: Icons.people,
                        label: 'Family Heads',
                        count: familyHeadsCount,
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ViewFamilyHeadsPage(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 60, color: color),
                const SizedBox(height: 15),
                Text(
                  label,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Text(
                  '$count',
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
