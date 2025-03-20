import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'dart:async';
import 'approval_page.dart'; // Import the approval page

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  _AdminNotificationsPageState createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
  bool isLoading = true;
  bool hasError = false;
  StreamSubscription? _notificationSubscription;
  int unreadCount = 0;

  // Sorting options
  String _sortOrder = 'newest'; // 'newest' or 'oldest'

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
    _setupNotificationSubscription();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  void _setupNotificationSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notificationSubscription = supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: _sortOrder == 'oldest')
        .listen((List<Map<String, dynamic>> data) {
          if (mounted) {
            setState(() {
              notifications = data;
              _updateUnreadCount();
              _groupNotificationsByDate();
            });
          }
        }, onError: (error) {});
  }

  void _updateUnreadCount() {
    unreadCount = notifications.where((n) => !(n['is_read'] ?? false)).length;
  }

  void _groupNotificationsByDate() {
    groupedNotifications = {};

    for (var notification in notifications) {
      final createdAt = DateTime.parse(notification['created_at']);
      final today = DateTime.now();
      final yesterday = DateTime.now().subtract(const Duration(days: 1));

      String dateKey;

      if (createdAt.year == today.year &&
          createdAt.month == today.month &&
          createdAt.day == today.day) {
        dateKey = 'Today';
      } else if (createdAt.year == yesterday.year &&
          createdAt.month == yesterday.month &&
          createdAt.day == yesterday.day) {
        dateKey = 'Yesterday';
      } else if (today.difference(createdAt).inDays < 7) {
        dateKey =
            DateFormat('EEEE').format(createdAt); // Day name (e.g., 'Monday')
      } else {
        dateKey =
            DateFormat('MMM d, yyyy').format(createdAt); // e.g., 'Feb 17, 2025'
      }

      if (!groupedNotifications.containsKey(dateKey)) {
        groupedNotifications[dateKey] = [];
      }

      groupedNotifications[dateKey]!.add(notification);
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest';
    });
    // Re-fetch notifications with the new sort order
    _fetchNotifications();
    // Update the subscription with the new sort order
    _notificationSubscription?.cancel();
    _setupNotificationSubscription();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: _sortOrder == 'oldest');

      if (mounted) {
        // Create a map to track seen notification types + related_ids to filter duplicates
        final Map<String, String> seenNotifications = {};
        final filteredNotifications =
            List<Map<String, dynamic>>.from(response).where((notification) {
          // Create a unique key combining notification_type and related_id
          final key =
              "${notification['notification_type']}_${notification['related_id']}";

          // If we've seen this combination before, filter it out
          if (seenNotifications.containsKey(key)) {
            return false;
          }

          // Otherwise, mark as seen and keep it
          seenNotifications[key] = notification['notification_id'].toString();
          return true;
        }).toList();

        setState(() {
          notifications = filteredNotifications;
          _updateUnreadCount();
          _groupNotificationsByDate();
          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching notifications: $e')),
        );
      }
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await supabase.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );

      if (mounted) {
        setState(() {
          final index = notifications.indexWhere(
              (n) => n['notification_id'].toString() == notificationId);
          if (index != -1) {
            notifications[index]['is_read'] = true;
            _updateUnreadCount();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (!mounted || notifications.isEmpty || unreadCount == 0) return;

    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Marking all notifications as read..."),
                ],
              ),
            ),
          );
        },
      );

      // Get all unread notifications
      final unreadNotifications =
          notifications.where((n) => !(n['is_read'] ?? false)).toList();

      // Mark each notification as read one by one
      for (var notification in unreadNotifications) {
        await supabase.rpc(
          'mark_notification_read',
          params: {'p_notification_id': notification['notification_id']},
        );
      }

      setState(() {
        for (var i = 0; i < notifications.length; i++) {
          notifications[i]['is_read'] = true;
        }
        unreadCount = 0;
        _groupNotificationsByDate(); // Update groupings with new read status
      });

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // Show success dialog
      _showSuccessDialog(
          context, 'Success', 'All notifications marked as read');
    } catch (e) {
      // Close loading dialog if open
      try {
        if (mounted) Navigator.of(context).pop();
      } catch (_) {
        // Dialog might not be open
      }

      // Show error dialog
      _showErrorDialog(
          context, 'Error', 'Error marking notifications as read: $e');
    }
  }

  void _showSuccessDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Colors.amber, size: 28),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final notificationType = notification['notification_type'];
    final notificationId = notification['notification_id'].toString();
    final relatedId = notification['related_id'];
    final senderId = notification['sender_id'];

    // Mark notification as read when clicked
    if (!(notification['is_read'] ?? false)) {
      await markAsRead(notificationId);
    }

    // Handle different notification types
    if (notificationType == 'cook_registration') {
      // Retrieve the cook details
      try {
        final cookData = await supabase
            .from('Local_Cook')
            .select()
            .eq('user_id', relatedId)
            .single();

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
                builder: (context) => const ApprovalPage(),
                settings: RouteSettings(arguments: {
                  'selectedCook': cookData,
                  'autoOpenDetails': true
                })),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading cook details: $e')),
          );
        }
      }
    } else if (notificationType == 'family_head_registration') {
      // Retrieve the family head details
      try {
        final familyHeadData = await supabase
            .from('familymember')
            .select()
            .eq('user_id', relatedId)
            .single();

        if (mounted) {
          _showFamilyMemberDetailsDialog(familyHeadData);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error loading family head details: $e')),
          );
        }
      }
    } else if (notificationType == 'support_request') {
      if (relatedId != null) {
        try {
          // Fetch the support request details
          final supportRequest = await supabase
              .from('support_requests')
              .select('*')
              .eq('request_id', relatedId)
              .single();

          // Show support request details dialog
          if (mounted) {
            _showSupportRequestDialog(supportRequest);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error loading support request: $e')),
            );
          }
        }
      }
    } else {
      // For any other notification types, show a generic dialog
      _showGenericNotificationDetailsDialog(notification);
    }
  }

  // Add this method to show family member details
  void _showFamilyMemberDetailsDialog(Map<String, dynamic> familyMember) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
              '${familyMember['first_name']} ${familyMember['last_name']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Age', familyMember['age']?.toString() ?? 'N/A'),
                _buildDetailRow('Gender', familyMember['gender'] ?? 'N/A'),
                _buildDetailRow('Date of Birth', familyMember['dob'] ?? 'N/A'),
                _buildDetailRow(
                    'Phone', familyMember['phone']?.toString() ?? 'N/A'),
                _buildDetailRow('Position', familyMember['position'] ?? 'N/A'),
                _buildDetailRow(
                    'Family Head', familyMember['family_head'] ?? 'N/A'),
                _buildDetailRow('Religion', familyMember['religion'] ?? 'N/A'),
                const Divider(),
                const Text(
                  'Address Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildDetailRow(
                    'Address', familyMember['address_line1'] ?? 'N/A'),
                _buildDetailRow('Province', familyMember['province'] ?? 'N/A'),
                _buildDetailRow('City', familyMember['city'] ?? 'N/A'),
                _buildDetailRow('Barangay', familyMember['barangay'] ?? 'N/A'),
                _buildDetailRow(
                    'Postal Code', familyMember['postal_code'] ?? 'N/A'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to show generic notification details
  void _showGenericNotificationDetailsDialog(
      Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(notification['title'] ?? 'Notification Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Type', notification['notification_type'] ?? 'N/A'),
                _buildDetailRow('Message', notification['message'] ?? 'N/A'),
                _buildDetailRow('Created At',
                    DateTime.parse(notification['created_at']).toString()),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  // Add this method to handle cook registration details
  Future<void> _handleCookRegistrationNotification(String cookId) async {
    try {
      // Show loading spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Dialog(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text("Loading cook details..."),
                ],
              ),
            ),
          );
        },
      );

      // Fetch the cook details
      final cookData = await supabase
          .from('Local_Cook')
          .select()
          .eq('user_id', cookId)
          .single();

      // Close loading dialog
      if (mounted) Navigator.of(context).pop();

      // If cook is already approved, show details
      if (cookData['is_accepted'] == true) {
        if (mounted) {
          _showCookDetailsDialog(cookData);
        }
      } else {
        // Navigate to the approval page
        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const ApprovalPage(),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if open
      try {
        if (mounted) Navigator.of(context).pop();
      } catch (_) {
        // Dialog might not be open
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading cook details: $e')),
        );
      }
    }
  }

  // Add this method to show cook details dialog for already approved cooks
  void _showCookDetailsDialog(Map<String, dynamic> cook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      child: const Icon(Icons.restaurant, color: Colors.green),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cook['first_name']} ${cook['last_name']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Approved Cook',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildDetailSection(
                          'Personal Information',
                          [
                            _buildDetailRow(
                                'Age', cook['age']?.toString() ?? 'N/A'),
                            _buildDetailRow('Gender', cook['gender'] ?? 'N/A'),
                            _buildDetailRow(
                                'Date of Birth', cook['dateofbirth'] ?? 'N/A'),
                            _buildDetailRow('Phone', cook['phone'] ?? 'N/A'),
                          ],
                        ),
                        _buildDetailSection(
                          'Location',
                          [
                            _buildDetailRow(
                                'Address', cook['address_line1'] ?? 'N/A'),
                            _buildDetailRow('City', cook['city'] ?? 'N/A'),
                            _buildDetailRow(
                                'Province', cook['province'] ?? 'N/A'),
                            _buildDetailRow(
                                'Barangay', cook['barangay'] ?? 'N/A'),
                            _buildDetailRow(
                                'Postal Code', cook['postal_code'] ?? 'N/A'),
                          ],
                        ),
                        _buildDetailSection(
                          'Availability',
                          [
                            _buildDetailRow(
                                'Days', cook['availability_days'] ?? 'N/A'),
                            _buildDetailRow('Hours',
                                '${cook['time_available_from'] ?? 'N/A'} - ${cook['time_available_to'] ?? 'N/A'}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Helper method for detail sections
  Widget _buildDetailSection(String title, List<Widget> details) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        ...details,
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }

  void _showSupportRequestDialog(Map<String, dynamic> supportRequest) {
    final requestId = supportRequest['request_id'];
    final email = supportRequest['email'] ?? 'No email';
    final issueType = supportRequest['issue_type'] ?? 'No issue type';
    final message = supportRequest['message'] ?? 'No message';

    // Format user type (replace underscores with spaces and capitalize)
    String userType = supportRequest['user_type'] ?? 'Unknown';
    userType = userType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    // Format status (replace underscores with spaces and capitalize)
    String status = supportRequest['status'] ?? 'pending';
    status = status
        .split('_')
        .map((word) => word.isNotEmpty
            ? '${word[0].toUpperCase()}${word.substring(1)}'
            : '')
        .join(' ');

    final timestamp = supportRequest['timestamp'] != null
        ? DateTime.parse(supportRequest['timestamp'])
        : DateTime.now();
    final formattedDate = DateFormat('MMM d, y - h:mm a').format(timestamp);

    // Get admin response from supportRequest
    final adminResponse = supportRequest['admin_response'];

    // Controller for admin response
    final responseController = TextEditingController(text: adminResponse);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Support Request from $email'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('User Type', userType),
              _buildDetailRow('Issue Type', issueType),
              _buildDetailRow('Submitted', formattedDate),
              _buildDetailRow('Status', status),
              const Divider(),
              const Text(
                'Message:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(message),
              ),
              const SizedBox(height: 16),
              const Text(
                'Your Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: responseController,
                maxLines: 5,
                decoration: const InputDecoration(
                  hintText: 'Type your response here...',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status change buttons
              DropdownButton<String>(
                value: supportRequest['status'],
                hint: const Text('Update Status'),
                items:
                    ['pending', 'in_progress', 'resolved'].map((String value) {
                  // Format display text
                  String displayText = value
                      .replaceAll('_', ' ')
                      .split(' ')
                      .map((word) => word.isNotEmpty
                          ? '${word[0].toUpperCase()}${word.substring(1)}'
                          : '')
                      .join(' ');

                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(displayText),
                  );
                }).toList(),
                onChanged: (newValue) async {
                  if (newValue != null) {
                    try {
                      await supabase.from('support_requests').update(
                          {'status': newValue}).eq('request_id', requestId);

                      if (newValue == 'resolved') {
                        await supabase.from('support_requests').update({
                          'resolved_at': DateTime.now().toIso8601String(),
                          'resolved_by': supabase.auth.currentUser?.id,
                        }).eq('request_id', requestId);
                      }

                      // Refresh interface
                      Navigator.pop(context);
                      _fetchNotifications();

                      // Format the status for display
                      String formattedStatus = newValue
                          .split('_')
                          .map((word) => word.isNotEmpty
                              ? '${word[0].toUpperCase()}${word.substring(1)}'
                              : '')
                          .join(' ');

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content:
                                Text('Status updated to $formattedStatus')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error updating status: $e')),
                      );
                    }
                  }
                },
              ),

              // Submit response button
              ElevatedButton(
                onPressed: () async {
                  final response = responseController.text;

                  // Validate response
                  if (response.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a response')),
                    );
                    return;
                  }

                  // Show loading indicator
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (BuildContext loadingContext) {
                      return const Dialog(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(width: 20),
                              Text("Submitting response..."),
                            ],
                          ),
                        ),
                      );
                    },
                  );

                  try {
                    // Update the support request
                    await supabase
                        .from('support_requests')
                        .update({'admin_response': response}).eq(
                            'request_id', requestId);

                    // Close the loading dialog
                    if (mounted) Navigator.of(context).pop();

                    // Close the support request dialog
                    if (mounted) Navigator.of(context).pop();

                    // Show success dialog - added delay to ensure previous dialogs are closed
                    Future.delayed(Duration(milliseconds: 300), () {
                      if (mounted) {
                        showDialog(
                          context: context,
                          builder: (successContext) => AlertDialog(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            contentPadding:
                                const EdgeInsets.fromLTRB(24, 20, 24, 10),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green, size: 28),
                                    const SizedBox(width: 12),
                                    const Text(
                                      "Success",
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Your response has been submitted successfully.",
                                  style: TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 24),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text(
                                      'OK',
                                      style: TextStyle(
                                        color: Colors.blue,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                    });

                    // Refresh notifications
                    _fetchNotifications();
                  } catch (e) {
                    // Close loading dialog if open
                    if (mounted) Navigator.of(context).pop();

                    // Show error dialog
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text('Error submitting response: $e')),
                      );
                    }
                  }
                },
                child: const Text('Submit Response'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Placeholder methods for other dialog types
  void _showBookingDetailsDialog(Map<String, dynamic> booking) {
    // Implement a dialog to display booking details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Booking Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Booking ID', booking['booking_id'] ?? 'N/A'),
                _buildDetailRow('Status', booking['status'] ?? 'N/A'),
                _buildDetailRow('Created At', booking['created_at'] ?? 'N/A'),
                // Add more booking details as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _showTransactionDetailsDialog(Map<String, dynamic> transaction) {
    // Implement a dialog to display transaction details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Transaction Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(
                    'Transaction ID', transaction['transaction_id'] ?? 'N/A'),
                _buildDetailRow('Amount',
                    '₱${transaction['amount']?.toStringAsFixed(2) ?? 'N/A'}'),
                _buildDetailRow('Status', transaction['status'] ?? 'N/A'),
                _buildDetailRow('Date', transaction['created_at'] ?? 'N/A'),
                // Add more transaction details as needed
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationIcon(String type, [String? title]) {
    IconData iconData;
    Color iconColor;

    switch (type) {
      case 'support_request':
        iconData = Icons.contact_support;
        iconColor = Colors.blue;
        break;
      case 'cook_registration':
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
        break;
      case 'family_update':
        iconData = Icons.family_restroom;
        iconColor = Colors.green;
        break;
      case 'meal_plan_generation':
        iconData = Icons.fastfood;
        iconColor = Colors.purple;
        break;
      case 'booking_request':
        iconData = Icons.book_online;
        iconColor = Colors.indigo;
        break;
      case 'payment':
        iconData = Icons.payment;
        iconColor = Colors.teal;
        break;
      case 'order_status':
        iconData = Icons.delivery_dining;
        iconColor = Colors.amber;
        break;
      case 'meal_completion':
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, color: iconColor),
    );
  }

  // Add this method to display user type badges
  Widget _buildUserTypeBadge(String? additionalData) {
    if (additionalData == null) return const SizedBox.shrink();

    Color badgeColor;
    String label;

    if (additionalData.contains('cook')) {
      badgeColor = Colors.blue;
      label = 'COOK';
    } else if (additionalData.contains('family_head')) {
      badgeColor = Colors.purple;
      label = 'FAMILY';
    } else if (additionalData.contains('admin')) {
      badgeColor = Colors.red;
      label = 'ADMIN';
    } else {
      badgeColor = Colors.grey;
      label = 'USER';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: badgeColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        _buildNotificationHeader(),
        Expanded(
          child: notifications.isEmpty
              ? _buildEmptyNotificationsView()
              : _buildNotificationsList(),
        ),
      ],
    );
  }

  Widget _buildNotificationHeader() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Notifications',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Row(
            children: [
              // Sort toggle button
              IconButton(
                icon: Icon(_sortOrder == 'newest'
                    ? Icons.arrow_downward
                    : Icons.arrow_upward),
                tooltip: _sortOrder == 'newest'
                    ? 'Showing newest first'
                    : 'Showing oldest first',
                onPressed: _toggleSortOrder,
              ),
              if (unreadCount > 0)
                TextButton.icon(
                  icon: const Icon(Icons.done_all),
                  label: const Text('Mark all as read'),
                  onPressed: markAllAsRead,
                ),
              // Refresh button
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh notifications',
                onPressed: _fetchNotifications,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyNotificationsView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'No notifications yet',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    if (groupedNotifications.isEmpty) {
      return _buildEmptyNotificationsView();
    }

    // Get the sorted date keys based on chronological order
    final sortedDateKeys = groupedNotifications.keys.toList()
      ..sort((a, b) {
        // Always keep 'Today' and 'Yesterday' at the top in that order
        if (a == 'Today') return _sortOrder == 'newest' ? -1 : 1;
        if (b == 'Today') return _sortOrder == 'newest' ? 1 : -1;
        if (a == 'Yesterday') return _sortOrder == 'newest' ? -1 : 1;
        if (b == 'Yesterday') return _sortOrder == 'newest' ? 1 : -1;

        // For day names of the week
        final weekdays = [
          'Monday',
          'Tuesday',
          'Wednesday',
          'Thursday',
          'Friday',
          'Saturday',
          'Sunday'
        ];
        if (weekdays.contains(a) && weekdays.contains(b)) {
          // Convert to day indices
          final aIndex = weekdays.indexOf(a);
          final bIndex = weekdays.indexOf(b);
          return _sortOrder == 'newest'
              ? bIndex.compareTo(aIndex)
              : aIndex.compareTo(bIndex);
        }

        // For dates in MMM d, yyyy format
        if (!weekdays.contains(a) &&
            !weekdays.contains(b) &&
            a != 'Today' &&
            a != 'Yesterday' &&
            b != 'Today' &&
            b != 'Yesterday') {
          try {
            final aDate = DateFormat('MMM d, yyyy').parse(a);
            final bDate = DateFormat('MMM d, yyyy').parse(b);
            return _sortOrder == 'newest'
                ? bDate.compareTo(aDate)
                : aDate.compareTo(bDate);
          } catch (e) {
            return a.compareTo(b); // Fallback to string comparison
          }
        }

        // Mixed cases (day name vs. date)
        if (weekdays.contains(a)) return _sortOrder == 'newest' ? -1 : 1;
        if (weekdays.contains(b)) return _sortOrder == 'newest' ? 1 : -1;

        return a.compareTo(b); // Fallback
      });

    return ListView.builder(
      itemCount: sortedDateKeys.length,
      itemBuilder: (context, groupIndex) {
        final dateKey = sortedDateKeys[groupIndex];
        final dateNotifications = groupedNotifications[dateKey]!;

        // Sort notifications within each group if needed
        if (_sortOrder == 'oldest') {
          dateNotifications.sort((a, b) => DateTime.parse(a['created_at'])
              .compareTo(DateTime.parse(b['created_at'])));
        } else {
          dateNotifications.sort((a, b) => DateTime.parse(b['created_at'])
              .compareTo(DateTime.parse(a['created_at'])));
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dateKey,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
            ...dateNotifications.map((notification) {
              final createdAt = DateTime.parse(notification['created_at']);
              final timeAgo = timeago.format(createdAt);
              final isRead = notification['is_read'] ?? false;

              return Dismissible(
                key: Key(notification['notification_id'].toString()),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: const Text("Confirm"),
                        content: const Text(
                            "Are you sure you want to delete this notification?"),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text("Delete"),
                          ),
                        ],
                      );
                    },
                  );
                },
                onDismissed: (direction) async {
                  try {
                    await supabase
                        .from('notifications')
                        .delete()
                        .eq('notification_id', notification['notification_id']);

                    if (!mounted) return;

                    setState(() {
                      final notificationId = notification['notification_id'];
                      // Remove from the notifications list
                      notifications.removeWhere(
                          (n) => n['notification_id'] == notificationId);
                      // Remove from the grouped notifications
                      groupedNotifications[dateKey]!.removeWhere(
                          (n) => n['notification_id'] == notificationId);
                      // If the group is now empty, remove it
                      if (groupedNotifications[dateKey]!.isEmpty) {
                        groupedNotifications.remove(dateKey);
                      }
                      _updateUnreadCount();
                    });
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Error deleting notification: $e')),
                    );
                  }
                },
                child: Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  elevation: isRead ? 1 : 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: isRead
                        ? BorderSide.none
                        : BorderSide(
                            color:
                                Theme.of(context).primaryColor.withOpacity(0.3),
                            width: 1),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(
                      children: [
                        _buildNotificationIcon(
                            notification['notification_type'],
                            notification['title']),
                        if (!isRead)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    title: Text(
                      notification['title'] ?? 'No Title',
                      style: TextStyle(
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          notification['message'] ?? 'No Message',
                          style: TextStyle(
                            color:
                                isRead ? Colors.grey.shade600 : Colors.black87,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              DateFormat('hh:mm a').format(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '($timeAgo)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => _handleNotificationTap(notification),
                    tileColor: isRead ? null : Colors.grey.withOpacity(0.05),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    trailing: !isRead
                        ? IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () => markAsRead(
                                notification['notification_id'].toString()),
                            tooltip: 'Mark as read',
                          )
                        : null,
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  // Static method to get unread count (for badges in UI)
  static Future<int> getUnreadCount() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return 0;

      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .eq('is_read', false);

      // Count the results
      return response.length;
    } catch (e) {
      return 0;
    }
  }

  // Helper method to delete a notification
  Future<void> _deleteNotification(String notificationId) async {
    try {
      await supabase
          .from('notifications')
          .delete()
          .eq('notification_id', notificationId);

      // Refresh notifications
      _fetchNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting notification: $e')),
        );
      }
    }
  }
}
