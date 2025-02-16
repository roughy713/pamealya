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

      // Fetch pending bookings
      final pendingResponse = await supabase
          .from('bookingrequest')
          .select('''
      bookingrequest_id,
      _isBookingAccepted,
      desired_delivery_time,
      mealplan(meal_name),
      delivery_status:delivery_status_id(status_name),
      Local_Cook(first_name, last_name)
    ''')
          .eq('familymember_id', familyMemberId)
          .eq('_isBookingAccepted', false)
          .eq('status', 'pending');

      final acceptedResponse = await supabase.from('bookingrequest').select('''
      bookingrequest_id,
      _isBookingAccepted,
      desired_delivery_time,
      mealplan:mealplan_id(meal_name),
      delivery_status:delivery_status_id(status_name),
      Local_Cook(first_name, last_name)
    ''').eq('familymember_id', familyMemberId).eq('_isBookingAccepted', true);

      setState(() {
        pendingBookings =
            List<Map<String, dynamic>>.from(pendingResponse.map((booking) {
          final cook = booking['Local_Cook'] ?? {};
          final deliveryStatus = booking['delivery_status'] ?? {};
          return {
            ...booking,
            'cook_name':
                '${cook['first_name'] ?? 'Unknown'} ${cook['last_name'] ?? ''}'
                    .trim(),
            'status_name': deliveryStatus['status_name'] ?? 'Unknown',
          };
        }));

        acceptedBookings =
            List<Map<String, dynamic>>.from(acceptedResponse.map((booking) {
          final cook = booking['Local_Cook'] ?? {};
          final deliveryStatus = booking['delivery_status'] ?? {};
          return {
            ...booking,
            'cook_name':
                '${cook['first_name'] ?? 'Unknown'} ${cook['last_name'] ?? ''}'
                    .trim(),
            'status_name': deliveryStatus['status_name'] ?? 'Unknown',
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
    }
  }

  void showBookingDetails(String label, List<Map<String, dynamic>> bookings) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 500,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$label Bookings',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  bookings.isEmpty
                      ? const Text('No bookings found.')
                      : Expanded(
                          child: ListView.builder(
                            itemCount: bookings.length,
                            itemBuilder: (context, index) {
                              final booking = bookings[index];
                              final deliveryTime = DateTime.parse(
                                booking['desired_delivery_time'] ??
                                    DateTime.now().toString(),
                              ).toLocal();
                              final mealName =
                                  booking['mealplan']?['meal_name'] ?? 'N/A';
                              final statusName = booking['delivery_status']
                                      ?['status_name'] ??
                                  'N/A';

                              return ListTile(
                                leading: const Icon(Icons.event),
                                title: Text('Cook: ${booking['cook_name']}'),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Delivery: ${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}'),
                                    Text('Meal: $mealName'),
                                    Text('Status: $statusName'),
                                  ],
                                ),
                                onTap: () {
                                  _showDetailedBookingDialog(booking);
                                },
                              );
                            },
                          ),
                        ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDetailedBookingDialog(Map<String, dynamic> booking) {
    final deliveryTime = DateTime.parse(
      booking['desired_delivery_time'] ?? DateTime.now().toString(),
    ).toLocal();
    final mealName = booking['mealplan']?['meal_name'] ?? 'N/A';
    final statusName = booking['delivery_status']?['status_name'] ?? 'Unknown';

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 500,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Booking Details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text('Cook: ${booking['cook_name']}'),
                  Text(
                    'Delivery Date: ${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}',
                  ),
                  const Divider(color: Colors.grey),
                  const Text(
                    'Additional Details:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text('Meal Name: $mealName'),
                  Text('Delivery Status: $statusName'),
                  const Spacer(),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Close',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
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
                      Expanded(
                        child: _buildStatusCard(
                          label: 'Pending',
                          count: pendingCount,
                          icon: Icons.pending_actions,
                          onTap: () =>
                              showBookingDetails('Pending', pendingBookings),
                        ),
                      ),
                      const SizedBox(width: 20), // Adjust spacing between cards
                      Expanded(
                        child: _buildStatusCard(
                          label: 'Accepted',
                          count: acceptedCount,
                          icon: Icons.check_circle,
                          onTap: () =>
                              showBookingDetails('Accepted', acceptedBookings),
                        ),
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
        child: Center(
          // Center everything inside the card
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 100, color: Colors.green), // Increased icon size
              const SizedBox(height: 20), // Adjusted spacing
              Text(
                label,
                style: const TextStyle(
                  fontSize: 36, // Increased font size for the label
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Align text center horizontally
              ),
              const SizedBox(height: 10), // Adjusted spacing
              Text(
                '$count',
                style: const TextStyle(
                  fontSize: 48, // Increased font size for the count
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center, // Align text center horizontally
              ),
            ],
          ),
        ),
      ),
    );
  }
}
