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
  List<Map<String, dynamic>> allBookings = [];
  List<Map<String, dynamic>> filteredBookings = [];
  bool isLoading = true;

  // Search and filter properties
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'All';

  final List<String> statusOptions = ['All', 'Accepted', 'Pending'];

  @override
  void initState() {
    super.initState();
    fetchBookings();

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

  // Helper method to get order progress text
  String _getOrderProgressText(bool isAccepted, String? statusName) {
    if (!isAccepted) {
      return "Cook hasn't accepted yet";
    } else {
      if (statusName == null) return "Unknown";
      switch (statusName.toLowerCase()) {
        case 'received':
          return "Not yet started";
        case 'preparing':
          return "Cook is preparing";
        case 'ready':
          return "Ready for delivery";
        case 'out for delivery':
          return "Out for delivery";
        case 'delivered':
          return "Delivered";
        default:
          return statusName;
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredBookings = allBookings.where((booking) {
        // Apply status filter
        if (_statusFilter != 'All') {
          bool statusMatch = false;
          if (_statusFilter == 'Accepted' &&
              booking['_isBookingAccepted'] == true) {
            statusMatch = true;
          } else if (_statusFilter == 'Pending' &&
              (booking['_isBookingAccepted'] == false ||
                  booking['status']?.toLowerCase() == 'pending')) {
            statusMatch = true;
          }

          if (!statusMatch) return false;
        }

        // Apply search query if not empty
        if (_searchQuery.isNotEmpty) {
          String cookName = booking['cook_name']?.toLowerCase() ?? '';
          String mealName =
              booking['mealplan']?['meal_name']?.toLowerCase() ?? '';
          String status = booking['status']?.toLowerCase() ?? '';

          return cookName.contains(_searchQuery.toLowerCase()) ||
              mealName.contains(_searchQuery.toLowerCase()) ||
              status.contains(_searchQuery.toLowerCase());
        }

        return true;
      }).toList();
    });
  }

  Future<void> fetchBookings() async {
    setState(() {
      isLoading = true;
    });

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

      // Fetch all bookings regardless of status
      final bookingsResponse = await supabase.from('bookingrequest').select('''
      bookingrequest_id,
      _isBookingAccepted,
      desired_delivery_time,
      mealplan:mealplan_id(meal_name),
      delivery_status:delivery_status_id(status_name),
      Local_Cook(first_name, last_name),
      status
    ''').eq('familymember_id', familyMemberId);

      final processedBookings =
          List<Map<String, dynamic>>.from(bookingsResponse.map((booking) {
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

      setState(() {
        allBookings = processedBookings;
        _applyFilters(); // This will set filteredBookings
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

  void _showBookingDetailDialog(Map<String, dynamic> booking) {
    final deliveryTime = DateTime.parse(
      booking['desired_delivery_time'] ?? DateTime.now().toString(),
    ).toLocal();

    // Format the time with AM/PM format
    final hour = deliveryTime.hour > 12
        ? deliveryTime.hour - 12
        : (deliveryTime.hour == 0 ? 12 : deliveryTime.hour);
    final amPm = deliveryTime.hour >= 12 ? 'PM' : 'AM';
    final formattedTime =
        '${hour}:${deliveryTime.minute.toString().padLeft(2, '0')} $amPm';

    final mealName = booking['mealplan']?['meal_name'] ?? 'N/A';
    final statusName = booking['delivery_status']?['status_name'] ?? 'Unknown';
    final status = booking['status'] ?? 'Unknown';
    final isAccepted = booking['_isBookingAccepted'] == true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 8,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            constraints: BoxConstraints(
              maxWidth: 600,
              minHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with status indicator
                Row(
                  children: [
                    const Text(
                      'Booking Details',
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
                        color: isAccepted
                            ? Colors.green.withOpacity(0.1)
                            : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: isAccepted
                                ? Colors.green.withOpacity(0.5)
                                : Colors.orange.withOpacity(0.5)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isAccepted
                                ? Icons.check_circle
                                : Icons.pending_actions,
                            color: isAccepted ? Colors.green : Colors.orange,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            status,
                            style: TextStyle(
                              color: isAccepted ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Primary info section with large text
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
                            'Cook:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            booking['cook_name'],
                            style: const TextStyle(
                              fontSize: 20,
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
                            'Delivery Date:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.blueGrey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year} at ${formattedTime}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Additional details section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Additional Details:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Meal details with icon and styled text
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu,
                            color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        const Text(
                          'Meal Name:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            mealName,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Order status with icon and styled text
                    Row(
                      children: [
                        const Icon(Icons.local_shipping,
                            color: Colors.blueGrey),
                        const SizedBox(width: 12),
                        const Text(
                          'Order Status:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          !isAccepted
                              ? 'Cook hasn\'t accepted Booking request'
                              : (statusName == 'Received'
                                  ? 'Order progress: Not yet started'
                                  : statusName),
                          style: const TextStyle(
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Close button - modern style
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.grey[200],
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
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
                            hintText: "Search by cook, meal or status...",
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
                        'All Bookings (${filteredBookings.length})',
                        style: const TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      // Stats chips
                      _buildStatusChip(
                          'Accepted',
                          allBookings
                              .where((b) => b['_isBookingAccepted'] == true)
                              .length,
                          Colors.green),
                      const SizedBox(width: 8),
                      _buildStatusChip(
                          'Pending',
                          allBookings
                              .where((b) =>
                                  b['_isBookingAccepted'] == false ||
                                  b['status']?.toLowerCase() == 'pending')
                              .length,
                          Colors.orange),
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
                            'Cook',
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
                    child: filteredBookings.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty || _statusFilter != 'All'
                                  ? 'No bookings match your search or filter criteria'
                                  : 'No bookings found',
                              style: const TextStyle(
                                  fontSize: 16, fontStyle: FontStyle.italic),
                            ),
                          )
                        : ListView.separated(
                            itemCount: filteredBookings.length,
                            separatorBuilder: (context, index) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final booking = filteredBookings[index];
                              final deliveryTime = DateTime.parse(
                                booking['desired_delivery_time'] ??
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
                                  '${hour}:${deliveryTime.minute.toString().padLeft(2, '0')} $amPm';

                              final mealName =
                                  booking['mealplan']?['meal_name'] ?? 'N/A';
                              final isAccepted =
                                  booking['_isBookingAccepted'] == true;
                              final status = booking['status'] ?? 'Unknown';

                              return InkWell(
                                onTap: () => _showBookingDetailDialog(booking),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12.0, horizontal: 16.0),
                                  child: Row(
                                    children: [
                                      isAccepted
                                          ? const Icon(Icons.check_circle,
                                              color: Colors.green)
                                          : const Icon(Icons.pending_actions,
                                              color: Colors.orange),
                                      Expanded(
                                        flex: 2,
                                        child: Padding(
                                          padding:
                                              const EdgeInsets.only(left: 8.0),
                                          child: Text(booking['cook_name']),
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
                                            // Date
                                            Text(
                                              '${deliveryTime.day}/${deliveryTime.month}/${deliveryTime.year}',
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
                                            // Booking Status
                                            Text(
                                              status,
                                              style: TextStyle(
                                                color: status.toLowerCase() ==
                                                        'Pending'
                                                    ? Colors.orange
                                                    : status.toLowerCase() ==
                                                            'Accepted'
                                                        ? Colors.green
                                                        : Colors.black,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            // Order Progress
                                            const SizedBox(height: 4),
                                            Text(
                                              _getOrderProgressText(
                                                  isAccepted,
                                                  booking['delivery_status']
                                                      ?['status_name']),
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
        onPressed: () => fetchBookings(),
        child: const Icon(Icons.refresh),
        tooltip: 'Refresh bookings',
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
