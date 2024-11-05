import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingRequestsPage extends StatefulWidget {
  const BookingRequestsPage({Key? key}) : super(key: key);

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
          .order('request_date', ascending: false);

      if (response != null && response.isNotEmpty) {
        setState(() {
          bookingRequests = response as List<Map<String, dynamic>>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching booking requests: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> updateBookingStatus(String bookingId, bool isApproved) async {
    try {
      final response = await supabase.from('bookingrequest').update(
          {'is_approved': isApproved}).eq('bookingrequest_id', bookingId);

      if (response != null && response.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: Text(isApproved
                ? 'Booking request successfully accepted.'
                : 'Booking request successfully declined.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        fetchBookingRequests(); // Refresh the booking requests list
      }
    } catch (e) {
      print('Error updating booking status: $e');
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: const Text('Failed to update booking status.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                            Row(
                              children: [
                                const CircleAvatar(
                                  backgroundColor: Colors.grey,
                                  child:
                                      Icon(Icons.person, color: Colors.white),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Booking ID: ${booking['bookingrequest_id'] ?? 'N/A'}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                                'Family Member: ${booking['famhead_id'] ?? 'N/A'}'),
                            Text('Cook: ${booking['localcook_id'] ?? 'N/A'}'),
                            Text('Meal: ${booking['mealplan_id'] ?? 'N/A'}'),
                            Text('Date: ${booking['request_date'] ?? 'N/A'}'),
                            Text(
                                'Time: ${booking['desired_delivery_time'] ?? 'N/A'}'),
                            Text('Location: Service Location or Home Address'),
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
                                  child: const Text(
                                    'Accept',
                                    style: TextStyle(color: Colors.black),
                                  ),
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
                                  child: const Text(
                                    'Decline',
                                    style: TextStyle(color: Colors.black),
                                  ),
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
