import 'package:flutter/material.dart';
import 'package:pamealya/common/order_chat_room_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> orders = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    try {
      // Get the logged-in user's ID
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not logged in');
      }

      // Fetch only the orders where the logged-in user is the booked cook
      final response = await supabase
          .from('bookingrequest')
          .select('''
      bookingrequest_id,
      delivery_status_id,
      familymember_id,
      mealplan_id,
      request_date,
      desired_delivery_time,
      Local_Cook(first_name, last_name, user_id),
      familymember(first_name, last_name, user_id)
    ''')
          .eq('status', 'accepted') // Fetch only accepted bookings
          .eq('Local_Cook.user_id', userId) // Ensure only this user's bookings
          .order('desired_delivery_time', ascending: true);

      // Debug: print the response to verify data
      print('Filtered Orders Response: $response');

      // Filter out results with null Local_Cook data
      final filteredOrders = response.where((order) {
        final cook = order['Local_Cook'];
        return cook != null && cook['user_id'] == userId;
      }).toList();

      // Parse and update state with the filtered orders
      setState(() {
        orders = List<Map<String, dynamic>>.from(filteredOrders.map((order) {
          final cook = order['Local_Cook'] ?? {};
          final familyMember = order['familymember'] ?? {};
          return {
            ...order,
            'cook_name':
                '${cook['first_name'] ?? 'Unknown'} ${cook['last_name'] ?? ''}'
                    .trim(),
            'family_head_name':
                '${familyMember['first_name'] ?? 'Unknown'} ${familyMember['last_name'] ?? ''}'
                    .trim(),
            'cook_user_id': cook['user_id'],
            'family_user_id': familyMember['user_id'],
          };
        }));
        isLoading = false;
      });
    } catch (e) {
      // Debug: log the error
      print('Error fetching orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching orders: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> getOrCreateChatRoom(
      String familyUserId, String cookUserId) async {
    try {
      final response = await supabase.rpc(
        'get_or_create_chat_room',
        params: {
          'family_member_user_id': familyUserId,
          'cook_user_id': cookUserId,
        },
      );

      if (response == null) {
        throw Exception(
            'Unable to create or retrieve chat room. Please ensure all data is valid.');
      }
      return response as String;
    } catch (e) {
      throw Exception('Error creating or retrieving chat room: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? const Center(child: Text('No orders found.'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return GestureDetector(
                      onTap: () {
                        _showOrderDetailsDialog(context, order);
                      },
                      child: Card(
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
                                'Booking ID: ${order['bookingrequest_id']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                  'Family Head: ${order['family_head_name'] ?? 'N/A'}'),
                              Text('Cook: ${order['cook_name'] ?? 'Unknown'}'),
                              Text('Meal: ${order['mealplan_id'] ?? 'N/A'}'),
                              Text('Request Date: ${order['request_date']}'),
                              Text(
                                  'Delivery Time: ${order['desired_delivery_time']}'),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  void _showOrderDetailsDialog(
      BuildContext context, Map<String, dynamic> order) {
    showDialog(
      context: context,
      builder: (context) {
        int currentStep = 0; // Initialize the current step
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: SizedBox(
                width: 700,
                height: 600,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Booking ID: ${order['bookingrequest_id'].toString()}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Divider(thickness: 1, color: Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildDetailRow('Family Head',
                                  order['family_head_name'] ?? 'N/A'),
                              _buildDetailRow(
                                  'Cook', order['cook_name'] ?? 'Unknown'),
                              _buildDetailRow(
                                'Meal Plan',
                                order['mealplan_id'] != null
                                    ? order['mealplan_id'].toString()
                                    : 'N/A',
                              ),
                              _buildDetailRow(
                                'Request Date',
                                order['request_date'] != null
                                    ? order['request_date'].toString()
                                    : 'N/A',
                              ),
                              _buildDetailRow(
                                'Delivery Time',
                                order['desired_delivery_time'] != null
                                    ? order['desired_delivery_time'].toString()
                                    : 'N/A',
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                'Actions:',
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  _buildStepCircle(
                                    context,
                                    1,
                                    'Preparing',
                                    Icons.fastfood,
                                    currentStep,
                                    setState,
                                    order['bookingrequest_id'],
                                    order[
                                        'delivery_status_id'], // Pass deliveryStatusId here
                                  ),
                                  _buildDashedLine(),
                                  _buildStepCircle(
                                    context,
                                    2,
                                    'On Delivery',
                                    Icons.delivery_dining,
                                    currentStep,
                                    setState,
                                    order['bookingrequest_id'],
                                    order[
                                        'delivery_status_id'], // Pass deliveryStatusId here
                                  ),
                                  _buildDashedLine(),
                                  _buildStepCircle(
                                    context,
                                    3,
                                    'Done',
                                    Icons.check_circle,
                                    currentStep,
                                    setState,
                                    order['bookingrequest_id'],
                                    order[
                                        'delivery_status_id'], // Pass deliveryStatusId here
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final familyUserId =
                                  order['family_user_id']?.toString();
                              final cookUserId =
                                  order['cook_user_id']?.toString();

                              if (familyUserId == null || cookUserId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Error: Missing user IDs for chat room'),
                                  ),
                                );
                                return;
                              }

                              final chatRoomId = await getOrCreateChatRoom(
                                  familyUserId, cookUserId);

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OrdersChatRoomPage(
                                    chatRoomId: chatRoomId,
                                    recipientName: order['cook_name'] ?? 'N/A',
                                  ),
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error opening chat room: $e')),
                              );
                            }
                          },
                          icon: const Icon(Icons.chat, color: Colors.white),
                          label: const Text(
                            'Message',
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Center(
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
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCircle(
      BuildContext context,
      int step,
      String label,
      IconData icon,
      int currentStep,
      Function setState,
      String bookingRequestId,
      int? deliveryStatusId) {
    // Determine if the step is completed based on deliveryStatusId
    final isCompleted = deliveryStatusId != null && step <= deliveryStatusId;

    // Determine if the step is active (only the next step is active)
    final isActive = deliveryStatusId != null && step == deliveryStatusId + 1;

    return Column(
      children: [
        GestureDetector(
          onTap: isActive
              ? () async {
                  final confirmed =
                      await _showConfirmationDialog(context, label);
                  if (confirmed) {
                    setState(() {
                      currentStep = step;
                    });

                    final statusUpdated =
                        await _updateOrderStatus(step, bookingRequestId);
                    if (statusUpdated) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$label marked as complete!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Failed to update status in the database'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete the previous step first!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
          child: CircleAvatar(
            radius: 30,
            backgroundColor: isCompleted ? Colors.green : Colors.grey[300],
            child: Icon(
              icon,
              color: isCompleted ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isCompleted ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String label) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Confirm Action'),
              content: Text('Are you sure you want to mark this as $label?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<bool> _updateOrderStatus(int step, String bookingRequestId) async {
    try {
      int statusId;

      // Map the step to the corresponding delivery_status_id
      if (step == 1) {
        statusId = 2; // "Preparing"
      } else if (step == 2) {
        statusId = 3; // "On Delivery"
      } else if (step == 3) {
        statusId = 4; // "Delivered"
      } else {
        return false;
      }

      // Update the delivery_status_id in the database
      final response = await Supabase.instance.client
          .from('bookingrequest')
          .update({'delivery_status_id': statusId})
          .eq('bookingrequest_id', bookingRequestId)
          .select();

      if (response.isNotEmpty) {
        return true; // Successfully updated
      } else {
        print('Database error: No rows affected.');
        return false;
      }
    } catch (e) {
      print('Error updating order status: $e');
      return false;
    }
  }

  Widget _buildDashedLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[400],
    );
  }
}
