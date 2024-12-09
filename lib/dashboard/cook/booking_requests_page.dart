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
      // Get the logged-in user's ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch booking requests for the logged-in cook
      final response = await supabase
          .from('bookingrequest')
          .select('''
          bookingrequest_id,
          familymember_id,
          mealplan_id,
          request_date,
          desired_delivery_time,
          status,
          Local_Cook(first_name, last_name, user_id),
          familymember(first_name, last_name, user_id),
          mealplan(meal_name) -- Join mealplan table to fetch meal_name
        ''')
          .eq('status', 'pending') // Fetch pending booking requests
          .eq('Local_Cook.user_id', userId) // Filter by logged-in user's ID
          .order('request_date', ascending: false);

      // Filter out results with null Local_Cook data
      final filteredRequests = response.where((booking) {
        final cook = booking['Local_Cook'];
        return cook != null && cook['user_id'] == userId;
      }).toList();

      // Update the state with the filtered booking requests
      setState(() {
        bookingRequests =
            List<Map<String, dynamic>>.from(filteredRequests.map((booking) {
          final cook = booking['Local_Cook'] ?? {};
          final familyHead = booking['familymember'] ?? {};
          return {
            ...booking,
            'cook_name':
                '${cook['first_name'] ?? 'Unknown'} ${cook['last_name'] ?? ''}'
                    .trim(),
            'family_head_name':
                '${familyHead['first_name'] ?? 'Unknown'} ${familyHead['last_name'] ?? ''}'
                    .trim(),
            'meal_name': booking['mealplan']?['meal_name'] ?? 'N/A',
          };
        }));
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
        '_isBookingAccepted': isAccepted, // Update _isBookingAccepted field
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
                                'Family Head: ${booking['family_head_name'] ?? 'N/A'}'),
                            Text('Cook: ${booking['cook_name'] ?? 'Unknown'}'),
                            Text('Meal: ${booking['meal_name'] ?? 'N/A'}'),
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
