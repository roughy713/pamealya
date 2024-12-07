import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyBookingsPage extends StatefulWidget {
  final String currentUserId;

  const MyBookingsPage({
    Key? key,
    required this.currentUserId,
  }) : super(key: key);

  @override
  _MyBookingsPageState createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  int acceptedCount = 0;
  int pendingCount = 0;
  List<Map<String, dynamic>> acceptedBookings = [];
  List<Map<String, dynamic>> pendingBookings = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookings();
  }

  Future<void> fetchBookings() async {
    final supabase = Supabase.instance.client;

    try {
      // Fetch familymember_id based on the current user's user_id
      final familyMemberResponse = await supabase
          .from('familymember')
          .select('familymember_id')
          .eq('user_id', widget.currentUserId)
          .single();

      if (familyMemberResponse == null || familyMemberResponse.isEmpty) {
        throw Exception("No family member found for the current user.");
      }

      final familyMemberId = familyMemberResponse['familymember_id'];
      print("Fetched familymember_id: $familyMemberId");

      // Fetch pending bookings
      final pendingResponse = await supabase
          .from('bookingrequest')
          .select('''
          bookingrequest_id,
          _isBookingAccepted,
          desired_delivery_time,
          Local_Cook(first_name, last_name)
        ''')
          .eq('familymember_id', familyMemberId)
          .eq('_isBookingAccepted', false)
          .eq('status', 'pending');

      // Fetch accepted bookings
      final acceptedResponse = await supabase
          .from('bookingrequest')
          .select('''
          bookingrequest_id,
          _isBookingAccepted,
          desired_delivery_time,
          Local_Cook(first_name, last_name)
        ''')
          .eq('familymember_id', familyMemberId)
          .eq('_isBookingAccepted', true);

      print("Pending Bookings Response: $pendingResponse");
      print("Accepted Bookings Response: $acceptedResponse");

      setState(() {
        pendingBookings =
            List<Map<String, dynamic>>.from(pendingResponse.map((booking) {
          final cook = booking['Local_Cook'] ?? {};
          return {
            ...booking,
            'cook_name':
                '${cook['first_name'] ?? 'Unknown'} ${cook['last_name'] ?? ''}'
                    .trim(),
          };
        }));

        acceptedBookings =
            List<Map<String, dynamic>>.from(acceptedResponse.map((booking) {
          final cook = booking['Local_Cook'] ?? {};
          return {
            ...booking,
            'cook_name':
                '${cook['first_name'] ?? 'Unknown'} ${cook['last_name'] ?? ''}'
                    .trim(),
          };
        }));

        pendingCount = pendingBookings.length;
        acceptedCount = acceptedBookings.length;
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching bookings: $e')),
        );
      }
      setState(() {
        isLoading = false;
      });
      print('Error fetching bookings: $e');
    }
  }

  void showBookingDetails(String label, List<Map<String, dynamic>> bookings) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('$label Bookings'),
          content: bookings.isEmpty
              ? const Text('No bookings found.')
              : SizedBox(
                  height: 300,
                  width: 400,
                  child: ListView.builder(
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      final deliveryTime = DateTime.parse(
                        booking['desired_delivery_time'] ??
                            DateTime.now().toString(),
                      ).toLocal();

                      return ListTile(
                        leading: const Icon(Icons.event),
                        title: Text('Cook: ${booking['cook_name']}'),
                        subtitle: Text(
                          'Delivery: ${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}',
                        ),
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookings'),
      ),
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
                        label: 'Pending',
                        count: pendingCount,
                        icon: Icons.pending_actions,
                        onTap: () =>
                            showBookingDetails('Pending', pendingBookings),
                      ),
                      _buildStatusCard(
                        label: 'Accepted',
                        count: acceptedCount,
                        icon: Icons.check_circle,
                        onTap: () =>
                            showBookingDetails('Accepted', acceptedBookings),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard({
    required String label,
    required int count,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 150,
          height: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.green),
              const SizedBox(height: 10),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 5),
              Text(
                '$count',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
