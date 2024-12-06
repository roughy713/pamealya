import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRequestsPage extends StatefulWidget {
  const BookingRequestsPage({super.key});

  @override
  _BookingRequestsPageState createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends State<BookingRequestsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookingRequests = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchBookingRequests();
  }

  Future<void> fetchBookingRequests() async {
    try {
      final response = await supabase
          .from('bookingrequest')
          .select()
          .eq('status', 'pending') // Fetch pending booking requests
          .order('request_date', ascending: false);

      setState(() {
        bookingRequests = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching booking requests: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateBookingStatus(String bookingId, bool isAccepted) async {
    try {
      await supabase.from('bookingrequest').update({
        'status': isAccepted ? 'accepted' : 'declined',
        '_isBookingAccepted': isAccepted,
      }).eq('bookingrequest_id', bookingId);

      setState(() {
        bookingRequests.removeWhere(
            (booking) => booking['bookingrequest_id'] == bookingId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAccepted
                ? 'Booking request successfully accepted.'
                : 'Booking request successfully declined.',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating booking status: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Booking Requests'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : bookingRequests.isEmpty
              ? const Center(child: Text('No booking requests found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: bookingRequests.length,
                  itemBuilder: (context, index) {
                    final booking = bookingRequests[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Booking ID: ${booking['bookingrequest_id']}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                                'Family Head: ${booking['family_head'] ?? 'N/A'}'),
                            Text(
                                'Cook: ${booking['localcookid'] ?? 'Unknown'}'),
                            Text('Meal: ${booking['mealplan_id'] ?? 'N/A'}'),
                            Text('Request Date: ${booking['request_date']}'),
                            Text(
                                'Delivery Time: ${booking['desired_delivery_time']}'),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton(
                                  onPressed: () {
                                    updateBookingStatus(
                                        booking['bookingrequest_id'], true);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  child: const Text('Accept'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    updateBookingStatus(
                                        booking['bookingrequest_id'], false);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  child: const Text('Decline'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
