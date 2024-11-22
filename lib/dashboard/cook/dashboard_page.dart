import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int acceptedCount = 0;
  int bookingRequestsCount = 0;
  List<Map<String, dynamic>> upcomingBookings = [];

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final supabase = Supabase.instance.client;

    try {
      // Fetch Accepted Count
      final acceptedResponse = await supabase
          .from('bookingrequest')
          .select()
          .eq('_isBookingAccepted', true)
          .eq('is_cook_booking', true);

      // Fetch Booking Requests Count
      final bookingRequestsResponse = await supabase
          .from('bookingrequest')
          .select()
          .eq('_isBookingAccepted', false)
          .eq('is_cook_booking', true);

      // Fetch Upcoming Bookings
      final upcomingResponse = await supabase
          .from('bookingrequest')
          .select()
          .eq('_isBookingAccepted', true)
          .order('desired_delivery_time', ascending: true);

      setState(() {
        acceptedCount = acceptedResponse.length;
        bookingRequestsCount = bookingRequestsResponse.length;
        upcomingBookings = List<Map<String, dynamic>>.from(upcomingResponse);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
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
                  icon: Icons.check_circle,
                  label: 'Accepted',
                  count: acceptedCount,
                  color: Colors.green,
                ),
                _buildStatusCard(
                  icon: Icons.pending_actions,
                  label: 'Booking Requests',
                  count: bookingRequestsCount,
                  color: Colors.green,
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Upcoming Bookings',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: upcomingBookings.length,
                itemBuilder: (context, index) {
                  final booking = upcomingBookings[index];
                  final familyHead = booking['famhead_id'] ?? 'Unknown';
                  final deliveryTime = booking['desired_delivery_time'] != null
                      ? DateTime.parse(booking['desired_delivery_time'])
                          .toLocal()
                      : null;

                  final formattedTime = deliveryTime != null
                      ? '${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}, ${deliveryTime.hour}:${deliveryTime.minute.toString().padLeft(2, '0')}'
                      : 'Unknown Time';

                  return ListTile(
                    leading: const Icon(Icons.event),
                    title: Text(familyHead),
                    subtitle: Text('Delivery: $formattedTime'),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Expanded(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 60, color: color),
              const SizedBox(height: 15),
              Text(
                label,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 10),
              Text(
                '$count',
                style:
                    const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
