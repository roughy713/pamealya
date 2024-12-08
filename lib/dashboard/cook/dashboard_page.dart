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
      // Fetch the logged-in user's `localcookid`
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception("No user is currently logged in.");
      }

      final localCookResponse = await supabase
          .from('Local_Cook')
          .select('localcookid')
          .eq('user_id', userId)
          .maybeSingle(); // Use `maybeSingle` to fetch a single row safely

      if (localCookResponse == null ||
          localCookResponse['localcookid'] == null) {
        throw Exception(
            "No matching `localcookid` found for the current user. Make sure the user is a cook.");
      }

      final localCookId = localCookResponse['localcookid'];
      print("Fetched localcookid: $localCookId");

      // Fetch Accepted Bookings
      final acceptedResponse = await supabase
          .from('bookingrequest')
          .select('bookingrequest_id')
          .eq('localcookid', localCookId)
          .eq('_isBookingAccepted', true);

      print("Accepted Bookings Response: $acceptedResponse");

      // Fetch Booking Requests
      final bookingRequestsResponse = await supabase
          .from('bookingrequest')
          .select('bookingrequest_id')
          .eq('localcookid', localCookId)
          .eq('_isBookingAccepted', false)
          .eq('status', 'pending');

      print("Booking Requests Response: $bookingRequestsResponse");

      // Fetch Upcoming Bookings
      final upcomingResponse = await supabase
          .from('bookingrequest')
          .select('''
          bookingrequest_id,
          localcookid,
          desired_delivery_time,
          familymember_id,
          familymember(first_name, last_name)
      ''')
          .eq('localcookid', localCookId)
          .eq('_isBookingAccepted', true)
          .order('desired_delivery_time', ascending: true);

      print("Upcoming Bookings Response: $upcomingResponse");

      // Update state
      setState(() {
        // Count all rows for accepted bookings
        acceptedCount = acceptedResponse.length;

        // Count all rows for pending booking requests
        bookingRequestsCount = bookingRequestsResponse.length;

        // Populate upcoming bookings
        upcomingBookings =
            List<Map<String, dynamic>>.from(upcomingResponse.map((booking) {
          final familyMember = booking['familymember'] ?? {};
          return {
            ...booking,
            'family_head':
                '${familyMember['first_name'] ?? 'Unknown'} ${familyMember['last_name'] ?? ''}'
                    .trim(),
          };
        }));
      });
    } catch (e) {
      // Handle errors
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data: $e')),
      );
      print('Error fetching data: $e');
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
                  final familyHead = booking['family_head'] ?? 'Unknown';
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
