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

  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Booking Details'),
          content: SizedBox(
            width: 500,
            height: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Booking ID: ${booking['bookingrequest_id']}'),
                Text('Family Head: ${booking['family_head_name'] ?? 'N/A'}'),
                Text('Cook: ${booking['cook_name'] ?? 'Unknown'}'),
                Text('Meal: ${booking['meal_name'] ?? 'N/A'}'),
                Text('Request Date: ${booking['request_date']}'),
                Text('Delivery Time: ${booking['desired_delivery_time']}'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (booking['mealplan_id'] != null) {
                  _showIngredientsDialog(
                      booking['mealplan_id']); // Pass mealplan_id
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('No meal plan ID available.')),
                  );
                }
              },
              child: const Text('Show Ingredients'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> updateBookingStatus(String bookingId, bool isAccepted) async {
    try {
      // Get the booking details first
      final booking = bookingRequests.firstWhere(
        (booking) => booking['bookingrequest_id'] == bookingId,
      );

      await supabase.from('bookingrequest').update({
        'status': isAccepted ? 'accepted' : 'declined',
        '_isBookingAccepted': isAccepted,
      }).eq('bookingrequest_id', bookingId);

      // Get the family member's user_id for notification
      if (booking['familymember'] != null &&
          booking['familymember']['user_id'] != null) {
        await supabase.rpc(
          'create_notification',
          params: {
            'p_recipient_id': booking['familymember']['user_id'],
            'p_sender_id': supabase.auth.currentUser?.id,
            'p_title': 'Booking ${isAccepted ? 'Accepted' : 'Declined'}',
            'p_message':
                'Your booking for ${booking['meal_name'] ?? 'the meal'} has been ${isAccepted ? 'accepted' : 'declined'}',
            'p_notification_type': 'booking',
            'p_related_id': bookingId,
          },
        );
      }

      setState(() {
        bookingRequests.removeWhere(
          (booking) => booking['bookingrequest_id'] == bookingId,
        );
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

  Future<void> _showIngredientsDialog(int mealplanId) async {
    try {
      // Fetch the recipe_id linked to this mealplan_id
      final mealplanResponse = await supabase
          .from('mealplan')
          .select('recipe_id')
          .eq('mealplan_id', mealplanId)
          .single();

      if (mealplanResponse == null || mealplanResponse.isEmpty) {
        throw Exception('No recipe linked to this meal.');
      }

      final recipeId = mealplanResponse['recipe_id'];

      // Fetch the ingredients for the recipe
      final ingredientsResponse = await supabase
          .from('ingredients')
          .select('name, quantity, unit')
          .eq('recipe_id', recipeId);

      if (ingredientsResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No ingredients found for this recipe.')),
        );
        return;
      }

      // Show the ingredients dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Ingredients'),
            content: SizedBox(
              width: 500,
              height: 500,
              child: ListView.builder(
                itemCount: ingredientsResponse.length,
                itemBuilder: (context, index) {
                  final ingredient = ingredientsResponse[index];
                  final name = ingredient['name'] ?? 'Unknown';
                  final quantity = ingredient['quantity'] ?? 'N/A';
                  final unit = ingredient['unit'] ?? '';
                  return ListTile(
                    title: Text(name),
                    subtitle: Text('$quantity $unit'),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showInstructionsDialog(
                      recipeId); // Pass recipe_id to the instructions dialog
                },
                child: const Text('Show Instructions'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching ingredients: $e')),
      );
    }
  }

  Future<void> _showInstructionsDialog(int recipeId) async {
    try {
      // Fetch instructions for the recipe
      final instructionsResponse = await supabase
          .from('instructions')
          .select('step_number, instruction')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);

      if (instructionsResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('No instructions found for this recipe.')),
        );
        return;
      }

      // Show the instructions dialog
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Instructions'),
            content: SizedBox(
              width: 500,
              height: 500,
              child: ListView.builder(
                itemCount: instructionsResponse.length,
                itemBuilder: (context, index) {
                  final step = instructionsResponse[index];
                  final stepNumber = step['step_number'];
                  final instruction = step['instruction'] ?? 'N/A';
                  return ListTile(
                    title: Text('Step $stepNumber'),
                    subtitle: Text(instruction),
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
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching instructions: $e')),
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
                        child: Material(
                          color: Colors
                              .transparent, // Ensure the material doesn't obscure the card's style
                          child: InkWell(
                            onTap: () {
                              _showBookingDetailsDialog(
                                  booking); // Show details dialog
                            },
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
                                  Text(
                                      'Cook: ${booking['cook_name'] ?? 'Unknown'}'),
                                  Text(
                                      'Meal: ${booking['meal_name'] ?? 'N/A'}'),
                                  Text(
                                      'Request Date: ${booking['request_date']}'),
                                  Text(
                                      'Delivery Time: ${booking['desired_delivery_time']}'),
                                  const SizedBox(height: 16),
                                  // Row for Accept and Decline buttons
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      ElevatedButton(
                                        onPressed: () {
                                          updateBookingStatus(
                                              booking['bookingrequest_id'],
                                              true);
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
                                              booking['bookingrequest_id'],
                                              false);
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
                          ),
                        ),
                      );
                    },
                  ));
  }
}
