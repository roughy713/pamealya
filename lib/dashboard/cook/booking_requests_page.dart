import 'package:flutter/material.dart';
import 'package:pamealya/dashboard/admin/admin_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class BookingRequestsPage extends StatefulWidget {
  const BookingRequestsPage({super.key});
  @override
  _BookingRequestsPageState createState() => _BookingRequestsPageState();
}

class _BookingRequestsPageState extends State<BookingRequestsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> bookingRequests = [];
  bool isLoading = true;
  String filterStatus = 'All';
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
 mealplan(meal_name)
 ''')
          .eq('status', 'pending')
          .eq('Local_Cook.user_id', userId)
          .order('desired_delivery_time',
              ascending: true); // Order by delivery time
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
                '${familyHead['first_name'] ?? 'Unknown'}${familyHead['last_name'] ?? ''}'
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

  // Format date in the format shown in the screenshot
  String formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('M/d/yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  // Format time like the screenshot
  String formatTime(String? timeString) {
    if (timeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(timeString);
      return DateFormat('h:mm a').format(dateTime);
    } catch (e) {
      return timeString;
    }
  }

  // Format both date and time to match the screenshot
  String formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      return '${DateFormat('M/d/yyyy').format(dateTime)}\n${DateFormat('h:mm a').format(dateTime)}';
    } catch (e) {
      return dateTimeString;
    }
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '';
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return (nameParts[0][0] + nameParts[1][0]).toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Booking Details',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 32),

                // Booking details in a table layout
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Booking ID:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        booking['bookingrequest_id'],
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Family Head:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        booking['family_head_name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Cook:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        booking['cook_name'] ?? 'Unknown',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Meal:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        booking['meal_name'] ?? 'N/A',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Request Date:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatDate(booking['request_date']),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(
                      width: 150,
                      child: Text(
                        'Delivery Time:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        formatTime(booking['desired_delivery_time']),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),

                // Buttons for Accept/Decline
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        _showConfirmationDialog(booking, false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Decline',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Show confirmation dialog for Accept, similar to Decline
                        _showConfirmationDialog(booking, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(150, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Accept',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Bottom action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton.icon(
                      icon: const Icon(
                        Icons.restaurant_menu,
                        color: Colors.green,
                      ),
                      label: const Text(
                        'Show Ingredients',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        if (booking['mealplan_id'] != null) {
                          _showIngredientsDialog(booking['mealplan_id']);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('No meal plan ID available.')),
                          );
                        }
                      },
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF6750A4),
                      ),
                      label: const Text(
                        'Close',
                        style: TextStyle(
                          color: Color(0xFF6750A4),
                          fontSize: 16,
                        ),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show confirmation dialog before accepting or declining
  void _showConfirmationDialog(Map<String, dynamic> booking, bool isAccepting) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            isAccepting ? 'Confirm Accept' : 'Confirm Decline',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isAccepting ? Colors.green : Colors.red,
            ),
          ),
          content: Text(
            isAccepting
                ? 'Are you sure you want to accept this booking request from ${booking['family_head_name']} for ${booking['meal_name']}?'
                : 'Are you sure you want to decline this booking request from ${booking['family_head_name']} for ${booking['meal_name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close confirmation dialog
                updateBookingStatus(booking['bookingrequest_id'], isAccepting);
                Navigator.of(context).pop(); // Close booking details
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isAccepting ? Colors.green : Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(isAccepting ? 'Accept' : 'Decline'),
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

      // Update the booking status
      await supabase.from('bookingrequest').update({
        'status': isAccepted ? 'accepted' : 'declined',
        '_isBookingAccepted': isAccepted,
      }).eq('bookingrequest_id', bookingId);

      // Get the family head's user_id from the bookingrequest table
      final bookingDetails = await supabase.from('bookingrequest').select('''
 user_id,
 family_head,
 Local_Cook ( first_name, last_name ),
 mealplan ( meal_name )
 ''').eq('bookingrequest_id', bookingId).single();

      final familyHeadUserId = bookingDetails['user_id'];
      final cookName =
          "${bookingDetails['Local_Cook']['first_name']} ${bookingDetails['Local_Cook']['last_name']}";
      final mealName = bookingDetails['mealplan']['meal_name'];

      // Create notification for the family head
      await supabase.rpc(
        'create_notification',
        params: {
          'p_recipient_id': familyHeadUserId,
          'p_sender_id': supabase.auth.currentUser?.id,
          'p_title': isAccepted ? 'Booking Accepted' : 'Booking Declined',
          'p_message': isAccepted
              ? 'Your booking for $mealName has been accepted by cook $cookName.'
              : 'Your booking for $mealName has been declined by cook $cookName.',
          'p_notification_type': 'booking_status',
          'p_related_id': bookingId,
        },
      );

      // Create notification for admin
      final adminNotificationService =
          AdminNotificationService(supabase: supabase);

      if (isAccepted) {
        await adminNotificationService.notifyBookingAccepted(
            supabase.auth.currentUser!.id,
            cookName,
            booking['family_head_name'],
            mealName,
            bookingId);
      } else {
        await adminNotificationService.notifyBookingDeclined(
            supabase.auth.currentUser!.id,
            cookName,
            booking['family_head_name'],
            mealName,
            bookingId);
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
          backgroundColor: isAccepted ? Colors.green : Colors.red,
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
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green),
          ),
        ),
      );
      // Fetch the recipe_id linked to this mealplan_id
      final mealplanResponse = await supabase
          .from('mealplan')
          .select('recipe_id, meal_name')
          .eq('mealplan_id', mealplanId)
          .limit(1); // Use limit instead of single

      // Close loading dialog
      Navigator.pop(context);
      // Check if we got any results
      if (mealplanResponse == null || mealplanResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No meal plan found with this ID.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final recipeId = mealplanResponse[0]['recipe_id'];
      final mealName = mealplanResponse[0]['meal_name'] ?? 'Meal';
      // Fetch the ingredients for the recipe
      final ingredientsResponse = await supabase
          .from('ingredients')
          .select('name, quantity, unit')
          .eq('recipe_id', recipeId);
      if (ingredientsResponse == null || ingredientsResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No ingredients found for this recipe.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      // Show the ingredients dialog
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingredients for $mealName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.green, thickness: 1.0),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ingredientsResponse.length,
                      itemBuilder: (context, index) {
                        final ingredient = ingredientsResponse[index];
                        final name = ingredient['name'] ?? 'Unknown';
                        final quantity = ingredient['quantity'] ?? '';
                        final unit = ingredient['unit'] ?? '';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.restaurant,
                                color: Colors.green,
                                size: 36,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '$quantity $unit',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Colors.green, thickness: 1.0),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.note_alt_outlined,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Show Instructions',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showInstructionsDialog(recipeId, mealName);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          backgroundColor: Colors.green.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching ingredients: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showInstructionsDialog(int recipeId, String mealName) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.green), //
          ),
        ),
      );
      // Fetch instructions for the recipe
      final instructionsResponse = await supabase
          .from('instructions')
          .select('step_number, instruction')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);
      // Close loading dialog
      Navigator.pop(context);
      if (instructionsResponse.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No instructions found for this recipe.'),
            backgroundColor: Colors.green, // Green snackbar
          ),
        );
        return;
      }
      // Show the instructions dialog
      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 500,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200, width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with green styling
                  Text(
                    'Instructions for $mealName',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.green, thickness: 1.0),
                  const SizedBox(height: 16),

                  // Instructions list with green styling
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.6,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: instructionsResponse.length,
                      itemBuilder: (context, index) {
                        final step = instructionsResponse[index];
                        final stepNumber = step['step_number'];
                        final instruction = step['instruction'] ?? 'N/A';

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.green, // Green
                                child: Text(
                                  '$stepNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 2.0),
                                  child: Text(
                                    instruction,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Divider(color: Colors.green, thickness: 1.0),
                  const SizedBox(height: 16),

                  // Action buttons with green styling
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.green,
                        ),
                        label: const Text(
                          'Back to Ingredients',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showIngredientsDialog(recipeId);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          backgroundColor: Colors.green.shade50,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      // Close loading dialog if still showing
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error fetching instructions: $e'),
          backgroundColor: Colors.red, // Red for errors
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = bookingRequests.length;

    return Scaffold(
      backgroundColor: Colors.white,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    children: [
                      Text(
                        'All Booking Requests ($pendingCount)',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          'Pending: $pendingCount',
                          style: const TextStyle(
                            color: Colors.deepOrange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  color: Colors.grey.shade200,
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  child: const Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Customer',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          'Meal',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Delivery Date',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Status & Progress',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      SizedBox(width: 40), // Space for chevron
                    ],
                  ),
                ),
                Expanded(
                  child: bookingRequests.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No booking requests found',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'When customers make booking requests, they will appear here',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: bookingRequests.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final booking = bookingRequests[index];
                            final customerName =
                                booking['family_head_name'] ?? '';

                            return InkWell(
                              onTap: () => _showBookingDetailsDialog(booking),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 12, horizontal: 16),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: Colors.orange,
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: const Icon(
                                              Icons.watch_later_outlined,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(
                                            customerName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        booking['meal_name'] ?? 'N/A',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        formatDateTime(
                                            booking['desired_delivery_time']),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Pending',
                                            style: TextStyle(
                                              color: Colors.orange.shade700,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const Text(
                                            'Awaiting response',
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
