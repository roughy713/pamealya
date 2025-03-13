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
  List<Map<String, dynamic>> allOrders = [];
  List<Map<String, dynamic>> filteredOrders = [];
  bool isLoading = true;

  // Search and filter properties
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> statusOptions = [
    'All',
    'Preparing',
    'On Delivery',
    'Completed'
  ];

  @override
  void initState() {
    super.initState();
    fetchOrders();

    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  void _applyFilters() {
    setState(() {
      filteredOrders = allOrders.where((order) {
        // Apply status filter
        if (_statusFilter != 'All') {
          final deliveryStatusId = order['delivery_status_id'];
          bool statusMatch = false;

          if (_statusFilter == 'Preparing' && deliveryStatusId == 2) {
            statusMatch = true;
          } else if (_statusFilter == 'On Delivery' && deliveryStatusId == 3) {
            statusMatch = true;
          } else if (_statusFilter == 'Completed' && deliveryStatusId == 4) {
            statusMatch = true;
          }

          if (!statusMatch) return false;
        }

        // Apply search query if not empty
        if (_searchQuery.isNotEmpty) {
          final customerName = order['family_head_name']?.toLowerCase() ?? '';
          final mealName = order['mealplan']?['meal_name']?.toLowerCase() ?? '';
          final bookingId = order['bookingrequest_id']?.toLowerCase() ?? '';

          return customerName.contains(_searchQuery.toLowerCase()) ||
              mealName.contains(_searchQuery.toLowerCase()) ||
              bookingId.contains(_searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  // Helper method to get order progress text based on delivery_status_id
  String _getOrderProgressText(int? deliveryStatusId) {
    switch (deliveryStatusId) {
      case 1:
        return "Not yet started";
      case 2:
        return "Preparing";
      case 3:
        return "On delivery";
      case 4:
        return "Completed";
      default:
        return "Unknown";
    }
  }

  // Helper method to get color for order progress
  Color _getStatusColor(int? deliveryStatusId) {
    switch (deliveryStatusId) {
      case 1:
        return Colors.grey;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Show error dialog instead of snackbar
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Show success dialog instead of snackbar
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Helper method to get icon based on delivery status
  IconData _getStatusIcon(int? deliveryStatusId) {
    switch (deliveryStatusId) {
      case 1:
        return Icons.hourglass_empty;
      case 2:
        return Icons.fastfood;
      case 3:
        return Icons.delivery_dining;
      case 4:
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Future<void> fetchOrders() async {
    setState(() {
      isLoading = true;
    });

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
      mealplan:mealplan_id(meal_name, mealplan_id),
      request_date,
      desired_delivery_time,
      Local_Cook!inner(first_name, last_name, user_id),
      familymember(first_name, last_name, user_id)
    ''')
          .eq('status', 'accepted') // Fetch only accepted bookings
          .eq('Local_Cook.user_id', userId) // Ensure only this user's bookings
          .order('desired_delivery_time',
              ascending: false); // Sort newest first

      // Filter out results with null Local_Cook data
      final filteredResponse = response.where((order) {
        final cook = order['Local_Cook'];
        return cook != null && cook['user_id'] == userId;
      }).toList();

      // Parse and update state with the filtered orders
      final processedOrders =
          List<Map<String, dynamic>>.from(filteredResponse.map((order) {
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

      setState(() {
        allOrders = processedOrders;
        _applyFilters(); // This will set filteredOrders
        isLoading = false;
      });
    } catch (e) {
      // Debug: log the error
      print('Error fetching orders: $e');
      if (mounted) {
        _showErrorDialog('Error fetching orders: $e');
      }
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<String> getOrCreateChatRoom(
      String familyUserId, String cookUserId) async {
    try {
      // Create or get room via RPC
      final response = await supabase.rpc(
        'get_or_create_chat_room',
        params: {
          'family_member_user_id': familyUserId,
          'cook_user_id': cookUserId,
        },
      );

      if (response == null) {
        throw Exception('Unable to create or retrieve chat room');
      }

      return response as String;
    } catch (e) {
      throw Exception('Error creating or retrieving chat room: $e');
    }
  }

  void _showOrderDetailsDialog(
      BuildContext context, Map<String, dynamic> order) {
    final deliveryTime = DateTime.parse(
      order['desired_delivery_time'] ?? DateTime.now().toString(),
    ).toLocal();

    // Format the time with AM/PM format
    final hour = deliveryTime.hour > 12
        ? deliveryTime.hour - 12
        : (deliveryTime.hour == 0 ? 12 : deliveryTime.hour);
    final amPm = deliveryTime.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '$hour:${deliveryTime.minute.toString().padLeft(2, '0')} $amPm';
    final formattedDate =
        '${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 8,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                constraints: BoxConstraints(
                  maxWidth: 600,
                  minHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with status
                    Row(
                      children: [
                        const Text(
                          'Order Details',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: _getStatusColor(order['delivery_status_id'])
                                .withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color:
                                    _getStatusColor(order['delivery_status_id'])
                                        .withOpacity(0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(order['delivery_status_id']),
                                color: _getStatusColor(
                                    order['delivery_status_id']),
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _getOrderProgressText(
                                    order['delivery_status_id']),
                                style: TextStyle(
                                  color: _getStatusColor(
                                      order['delivery_status_id']),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Primary info section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blueGrey),
                              const SizedBox(width: 12),
                              const Text(
                                'Customer:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order['family_head_name'],
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.restaurant_menu,
                                  color: Colors.blueGrey),
                              const SizedBox(width: 12),
                              const Text(
                                'Meal:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                order['mealplan']?['meal_name'] ?? 'N/A',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today,
                                  color: Colors.blueGrey),
                              const SizedBox(width: 12),
                              const Text(
                                'Delivery Date & Time:',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blueGrey,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${deliveryTime.month}/${deliveryTime.day}/${deliveryTime.year} at $formattedTime',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Order progress section
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Order Progress:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blueGrey,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStepCircle(
                              context,
                              2,
                              'Preparing',
                              Icons.fastfood,
                              (newStep) {
                                _updateOrderStatus(newStep,
                                    order['bookingrequest_id'], context);
                              },
                              order['bookingrequest_id'],
                              order['delivery_status_id'],
                            ),
                            _buildDashedLine(),
                            _buildStepCircle(
                              context,
                              3,
                              'On Delivery',
                              Icons.delivery_dining,
                              (newStep) {
                                _updateOrderStatus(newStep,
                                    order['bookingrequest_id'], context);
                              },
                              order['bookingrequest_id'],
                              order['delivery_status_id'],
                            ),
                            _buildDashedLine(),
                            _buildStepCircle(
                              context,
                              4,
                              'Completed',
                              Icons.check_circle,
                              (newStep) {
                                _updateOrderStatus(newStep,
                                    order['bookingrequest_id'], context);
                              },
                              order['bookingrequest_id'],
                              order['delivery_status_id'],
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        // Message button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                final familyUserId =
                                    order['family_user_id']?.toString();
                                final cookUserId =
                                    order['cook_user_id']?.toString();

                                if (familyUserId == null ||
                                    cookUserId == null) {
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
                                      recipientName:
                                          order['family_head_name'] ?? 'N/A',
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.chat, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Message',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Row(
                      children: [
                        // Ingredients button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final mealplanId =
                                  order['mealplan']?['mealplan_id'];
                              if (mealplanId != null) {
                                Navigator.pop(context);
                                _showIngredientsDialog(mealplanId);
                              } else {
                                _showErrorDialog('No meal plan ID available.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              foregroundColor: Colors.green[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.restaurant_menu, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Ingredients',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        // Instructions button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              final mealplanId =
                                  order['mealplan']?['mealplan_id'];
                              if (mealplanId != null) {
                                Navigator.pop(context);
                                _showDirectInstructionsDialog(mealplanId);
                              } else {
                                _showErrorDialog('No meal plan ID available.');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[100],
                              foregroundColor: Colors.green[800],
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.menu_book, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Instructions',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Close button
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showIngredientsDialog(int mealplanId) async {
    try {
      final mealplanResponse = await supabase
          .from('mealplan')
          .select('recipe_id')
          .eq('mealplan_id', mealplanId)
          .single();

      if (mealplanResponse.isEmpty) {
        throw Exception('No recipe linked to this meal.');
      }

      final recipeId = mealplanResponse['recipe_id'];

      final ingredientsResponse = await supabase
          .from('ingredients')
          .select('name, quantity, unit')
          .eq('recipe_id', recipeId);

      if (ingredientsResponse.isEmpty) {
        _showErrorDialog('No ingredients found for this recipe.');
        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 600,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingredients',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(thickness: 1, color: Colors.grey),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: ingredientsResponse.length,
                      itemBuilder: (context, index) {
                        final ingredient = ingredientsResponse[index];
                        return ListTile(
                          leading:
                              const Icon(Icons.restaurant, color: Colors.green),
                          title: Text(ingredient['name'] ?? 'Unknown'),
                          subtitle: Text(
                            '${ingredient['quantity'] ?? 'N/A'} ${ingredient['unit'] ?? ''}',
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Prev/Back button
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Go back to order details dialog
                          final order = allOrders.firstWhere(
                            (o) => o['mealplan']?['mealplan_id'] == mealplanId,
                            orElse: () => {},
                          );
                          if (order.isNotEmpty) {
                            _showOrderDetailsDialog(context, order);
                          }
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Order'),
                      ),

                      // Instructions button
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showInstructionsDialog(recipeId);
                        },
                        icon: const Icon(Icons.menu_book),
                        label: const Text('Show Instructions'),
                      ),

                      // Close button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Close',
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
      );
    } catch (e) {
      _showErrorDialog('Error fetching ingredients: $e');
    }
  }

  Future<void> _showInstructionsDialog(int recipeId) async {
    try {
      final instructionsResponse = await supabase
          .from('instructions')
          .select('step_number, instruction')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);

      if (instructionsResponse.isEmpty) {
        _showErrorDialog('No instructions found for this recipe.');
        return;
      }

      showDialog(
        context: context,
        builder: (context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Container(
              width: 600,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Instructions',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(thickness: 1, color: Colors.grey),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: instructionsResponse.length,
                      itemBuilder: (context, index) {
                        final step = instructionsResponse[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.green,
                            child: Text(
                              '${step['step_number']}',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          title: Text(step['instruction'] ?? 'N/A'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back to ingredients button
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          // Go back to ingredients dialog
                          _showIngredientsFromRecipe(recipeId);
                        },
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Back to Ingredients'),
                      ),

                      // Close button
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Close',
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
      );
    } catch (e) {
      _showErrorDialog('Error fetching instructions: $e');
    }
  }

  // Helper method to show ingredients when coming back from instructions
  Future<void> _showIngredientsFromRecipe(int recipeId) async {
    try {
      // First, find the mealplan_id that matches this recipe_id
      final mealplanResponse = await supabase
          .from('mealplan')
          .select('mealplan_id')
          .eq('recipe_id', recipeId)
          .limit(1)
          .single();

      if (mealplanResponse.isEmpty) {
        throw Exception('Could not find mealplan for this recipe.');
      }

      final mealplanId = mealplanResponse['mealplan_id'];
      _showIngredientsDialog(mealplanId);
    } catch (e) {
      _showErrorDialog('Error returning to ingredients: $e');
    }
  }

  // Direct access to instructions from order details dialog
  Future<void> _showDirectInstructionsDialog(int mealplanId) async {
    try {
      final mealplanResponse = await supabase
          .from('mealplan')
          .select('recipe_id')
          .eq('mealplan_id', mealplanId)
          .single();

      if (mealplanResponse.isEmpty) {
        throw Exception('No recipe linked to this meal.');
      }

      final recipeId = mealplanResponse['recipe_id'];
      _showInstructionsDialog(recipeId);
    } catch (e) {
      _showErrorDialog('Error showing instructions: $e');
    }
  }

  Widget _buildStepCircle(
    BuildContext context,
    int step,
    String label,
    IconData icon,
    Function(int) onStepClick,
    String bookingRequestId,
    int? deliveryStatusId,
  ) {
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
                    onStepClick(step);
                  }
                }
              : () {
                  if (!isCompleted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Complete the previous step first!'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
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
            color: isCompleted ? Colors.green : Colors.grey[600],
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

  Future<bool> _updateOrderStatus(
      int step, String bookingRequestId, BuildContext context) async {
    try {
      int statusId;
      String statusText;
      String notificationMessage;
      String notificationTitle;

      // Get the order before updating
      final order = allOrders.firstWhere(
        (order) => order['bookingrequest_id'] == bookingRequestId,
      );

      final cookName = order['cook_name'] ?? 'Your cook';
      final mealName = order['mealplan']?['meal_name'] ?? 'your meal';

      switch (step) {
        case 2:
          statusId = 2;
          statusText = "Preparing";
          notificationTitle = "Order Status: Preparing";
          notificationMessage = "$cookName has started preparing $mealName";
          break;
        case 3:
          statusId = 3;
          statusText = "On Delivery";
          notificationTitle = "Order Status: On Delivery";
          notificationMessage =
              "$cookName is now delivering $mealName to your location";
          break;
        case 4:
          statusId = 4;
          statusText = "Completed";
          notificationTitle = "Order Status: Completed";
          notificationMessage =
              "Your order for $mealName has been completed by $cookName";
          break;
        default:
          return false;
      }

      // Update the delivery_status_id in the database
      final response = await supabase
          .from('bookingrequest')
          .update({'delivery_status_id': statusId})
          .eq('bookingrequest_id', bookingRequestId)
          .select();

      if (response.isNotEmpty) {
        // Send notification to family head
        if (order['familymember'] != null &&
            order['familymember']['user_id'] != null) {
          await supabase.rpc(
            'create_notification',
            params: {
              'p_recipient_id': order['familymember']['user_id'],
              'p_sender_id': supabase.auth.currentUser?.id,
              'p_title': notificationTitle,
              'p_message': notificationMessage,
              'p_notification_type': 'delivery_status',
              'p_related_id': bookingRequestId,
            },
          );
        }

        await fetchOrders();

        if (mounted) {
          final updatedOrder = allOrders.firstWhere(
            (order) => order['bookingrequest_id'] == bookingRequestId,
            orElse: () => {},
          );

          if (updatedOrder.isNotEmpty) {
            Navigator.pop(context);
            _showOrderDetailsDialog(context, updatedOrder);
          }
        }

        // Show success message to cook
        if (mounted) {
          _showSuccessDialog('Status successfully updated to $statusText');
        }

        return true;
      } else {
        print('Database error: No rows affected.');
        return false;
      }
    } catch (e) {
      print('Error updating order status: $e');

      if (mounted) {
        _showErrorDialog('Error updating status: $e');
      }

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
                  // Search and Filter Row
                  Row(
                    children: [
                      // Search Bar
                      Expanded(
                        flex: 3,
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText:
                                "Search by customer, meal, or booking ID...",
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            filled: true,
                            fillColor: Colors.grey[100],
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 0.0),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status Filter Dropdown
                      Expanded(
                        flex: 1,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8.0),
                            color: Colors.grey[100],
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _statusFilter,
                              isExpanded: true,
                              hint: const Text('Status'),
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    _statusFilter = newValue;
                                    _applyFilters();
                                  });
                                }
                              },
                              items: statusOptions.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Stats Row
                  Row(
                    children: [
                      Text(
                        'All Orders (${filteredOrders.length})',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Stats chips
                      _buildStatusChip(
                          'Preparing',
                          allOrders
                              .where((o) => o['delivery_status_id'] == 2)
                              .length,
                          Colors.orange),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                          'On Delivery',
                          allOrders
                              .where((o) => o['delivery_status_id'] == 3)
                              .length,
                          Colors.blue),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                          'Completed',
                          allOrders
                              .where((o) => o['delivery_status_id'] == 4)
                              .length,
                          Colors.green),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Table header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 24), // Space for status icon
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Customer',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Meal',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Delivery Date',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            'Status & Progress',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        SizedBox(width: 24), // Space for action icon
                      ],
                    ),
                  ),

                  // Table body
                  Expanded(
                    child: filteredOrders.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty || _statusFilter != 'All'
                                  ? 'No orders match your search or filter criteria'
                                  : 'No orders found',
                              style: const TextStyle(
                                  fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredOrders.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              final deliveryTime = DateTime.parse(
                                order['desired_delivery_time'] ??
                                    DateTime.now().toString(),
                              ).toLocal();

                              // Format the time with AM/PM format
                              final hour = deliveryTime.hour > 12
                                  ? deliveryTime.hour - 12
                                  : (deliveryTime.hour == 0
                                      ? 12
                                      : deliveryTime.hour);
                              final amPm =
                                  deliveryTime.hour >= 12 ? 'PM' : 'AM';
                              final formattedTime =
                                  '$hour:${deliveryTime.minute.toString().padLeft(2, '0')} $amPm';

                              final mealName =
                                  order['mealplan']?['meal_name'] ?? 'N/A';
                              final deliveryStatusId =
                                  order['delivery_status_id'];

                              return InkWell(
                                onTap: () =>
                                    _showOrderDetailsDialog(context, order),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      Icon(
                                        _getStatusIcon(deliveryStatusId),
                                        color:
                                            _getStatusColor(deliveryStatusId),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child:
                                              Text(order['family_head_name']),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Text(mealName),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Date - Month/Day/Year format
                                            Text(
                                              '${deliveryTime.month}/${deliveryTime.day}/${deliveryTime.year}',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500),
                                            ),
                                            // Time
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedTime,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 2,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            // Order Status
                                            Text(
                                              deliveryStatusId == 4
                                                  ? 'Completed'
                                                  : 'In Progress',
                                              style: TextStyle(
                                                color: _getStatusColor(
                                                    deliveryStatusId),
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // Order Progress
                                            const SizedBox(height: 4),
                                            Text(
                                              _getOrderProgressText(
                                                  deliveryStatusId),
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey[700],
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios,
                                          size: 16),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => fetchOrders(),
        tooltip: 'Refresh orders',
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }
}
