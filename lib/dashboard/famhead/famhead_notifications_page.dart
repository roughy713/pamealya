import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '/common/chat_room_page.dart';
import 'dart:async';

// OrderActionButton class at top level
class OrderActionButton extends StatefulWidget {
  final Map<String, dynamic> notification;
  final Function(Map<String, dynamic>) onTap;

  const OrderActionButton({
    Key? key,
    required this.notification,
    required this.onTap,
  }) : super(key: key);

  @override
  _OrderActionButtonState createState() => _OrderActionButtonState();
}

class _OrderActionButtonState extends State<OrderActionButton> {
  bool _isLoading = true;
  bool _isMealCompleted = false;
  bool _isReceived = false;

  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    try {
      final supabase = Supabase.instance.client;
      final bookingRequestId = widget.notification['related_id'];

      if (bookingRequestId != null) {
        // Check if the booking has received status
        final bookingDetails = await supabase
            .from('bookingrequest')
            .select('is_received, mealplan_id')
            .eq('bookingrequest_id', bookingRequestId)
            .maybeSingle();

        if (bookingDetails != null) {
          _isReceived = bookingDetails['is_received'] == true;

          // If we have a mealplan_id, check if it's completed
          if (bookingDetails['mealplan_id'] != null) {
            final mealDetails = await supabase
                .from('mealplan')
                .select('is_completed')
                .eq('mealplan_id', bookingDetails['mealplan_id'])
                .maybeSingle();

            if (mealDetails != null) {
              _isMealCompleted = mealDetails['is_completed'] == true;
            }
          }
        }
      }
    } catch (e) {
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading indicator while checking
    if (_isLoading) {
      return const SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
          strokeWidth: 2,
        ),
      );
    }

    // If the order has been received or meal is completed, show completed text
    if (_isReceived || _isMealCompleted) {
      return const Text(
        'Completed',
        style: TextStyle(
          color: Colors.green,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      );
    }

    // Otherwise show the confirm button
    return ElevatedButton(
      onPressed: () => widget.onTap(widget.notification),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 14),
        minimumSize: const Size(0, 0),
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
      ),
      child: const Text(
        'Confirm Order',
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class FamHeadNotificationsPage extends StatefulWidget {
  final Function(int)? onPageChange;
  final String? currentUserId;

  const FamHeadNotificationsPage({
    super.key,
    this.onPageChange,
    this.currentUserId,
  });

  @override
  _FamHeadNotificationsPageState createState() =>
      _FamHeadNotificationsPageState();
}

class _FamHeadNotificationsPageState extends State<FamHeadNotificationsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  Map<String, List<Map<String, dynamic>>> groupedNotifications = {};
  bool isLoading = true;
  StreamSubscription? _notificationSubscription;
  int unreadCount = 0;

  // Sorting options
  String _sortOrder = 'newest'; // 'newest' or 'oldest'

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _setupNotificationSubscription();
  }

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // Helper method to check if the meal related to a notification is already completed
  Future<bool> _checkIfMealCompleted(Map<String, dynamic> notification) async {
    try {
      final bookingRequestId = notification['related_id'];
      if (bookingRequestId == null) return false;

      // First get the mealplan_id from the booking request
      final bookingDetails = await supabase
          .from('bookingrequest')
          .select('mealplan_id, is_received')
          .eq('bookingrequest_id', bookingRequestId)
          .maybeSingle();

      // If order is already received or there's no mealplan_id, return appropriate status
      if (bookingDetails == null) {
        return false;
      }

      // If order is already received, consider it completed
      if (bookingDetails['is_received'] == true) {
        return true;
      }

      // If there's no mealplan_id, we can't check meal status
      if (bookingDetails['mealplan_id'] == null) {
        return false;
      }

      final mealplanId = bookingDetails['mealplan_id'];

      // Check if the meal is completed
      final mealDetails = await supabase
          .from('mealplan')
          .select('is_completed')
          .eq('mealplan_id', mealplanId)
          .maybeSingle();

      return mealDetails != null && mealDetails['is_completed'] == true;
    } catch (e) {
      return false;
    }
  }

  // Add dialog methods to replace SnackBars
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

  Future<void> _handleSupportResponseNotification(
      Map<String, dynamic> notification) async {
    final relatedId = notification['related_id'];
    if (relatedId == null) return;

    try {
      // Fetch the support request details
      final supportRequest = await supabase
          .from('support_requests')
          .select('*')
          .eq('request_id', relatedId)
          .single();

      if (mounted) {
        _showSupportResponseDialog(supportRequest);
      }

      // Mark notification as read
      if (!(notification['is_read'] ?? false)) {
        await markAsRead(notification['notification_id'].toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading support response: $e')),
        );
      }
    }
  }

  void _showSupportResponseDialog(Map<String, dynamic> supportRequest) {
    final issueType = supportRequest['issue_type'] ?? 'No issue type';
    final message = supportRequest['message'] ?? 'No message';
    final adminResponse = supportRequest['admin_response'] ?? 'No response yet';
    final status = supportRequest['status'] ?? 'pending';
    final timestamp = supportRequest['timestamp'] != null
        ? DateTime.parse(supportRequest['timestamp'])
        : DateTime.now();
    final formattedDate = DateFormat('MMM d, y - h:mm a').format(timestamp);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support Request Response'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Issue Type', issueType),
              _buildDetailRow('Submitted', formattedDate),
              _buildDetailRow('Status', status.toUpperCase()),
              const Divider(),
              const Text(
                'Your Message:',
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
                'Admin Response:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Text(adminResponse),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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

  Future<void> fetchNotifications() async {
    if (!mounted) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: _sortOrder == 'oldest');

      if (!mounted) return;

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        _updateUnreadCount();
        _groupNotificationsByDate();
        isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        // Replace SnackBar with dialog
        _showErrorDialog(context, 'Error', 'Error fetching notifications: $e');
      }
    }
  }

  void _toggleSortOrder() {
    setState(() {
      _sortOrder = _sortOrder == 'newest' ? 'oldest' : 'newest';
    });
    // Re-fetch notifications with the new sort order
    fetchNotifications();
    // Update the subscription with the new sort order
    _notificationSubscription?.cancel();
    _setupNotificationSubscription();
  }

  Future<void> markAsRead(String notificationId) async {
    if (!mounted) return;

    try {
      await supabase.rpc(
        'mark_notification_read',
        params: {'p_notification_id': notificationId},
      );

      if (!mounted) return;

      setState(() {
        final index = notifications.indexWhere(
            (n) => n['notification_id'].toString() == notificationId);
        if (index != -1) {
          notifications[index]['is_read'] = true;
          _updateUnreadCount();
          _groupNotificationsByDate(); // Regrouping not strictly necessary but keeps consistency
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markAllAsRead() async {
    if (!mounted || notifications.isEmpty) return;

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

      if (!mounted) return;

      // Close loading dialog
      Navigator.of(context).pop();

      setState(() {
        for (var i = 0; i < notifications.length; i++) {
          notifications[i]['is_read'] = true;
        }
        unreadCount = 0;
        _groupNotificationsByDate(); // Update groupings with new read status
      });

      // Show success dialog
      _showSuccessDialog(
          context, 'Success', 'All notifications marked as read');
    } catch (e) {
      if (!mounted) return;

      // Close loading dialog if open
      try {
        Navigator.of(context).pop();
      } catch (_) {
        // Ignore if dialog is not open
      }

      // Show error dialog
      _showErrorDialog(
          context, 'Error', 'Error marking notifications as read: $e');
    }
  }

  // Add method to handle order completion confirmation
  Future<void> _showOrderCompletionDialog(
      Map<String, dynamic> notification) async {
    final bookingRequestId = notification['related_id'];

    try {
      // Debug query to check what's in the booking request table
      final allRequests = await supabase
          .from('bookingrequest')
          .select('bookingrequest_id')
          .limit(5); // Just get a few to check format

      // Check if booking request exists first
      final bookingExists = await supabase
          .from('bookingrequest')
          .select('bookingrequest_id')
          .eq('bookingrequest_id', bookingRequestId)
          .maybeSingle();

      // If null, booking request not found
      if (bookingExists == null) {
        throw Exception('Order not found or invalid booking request ID');
      }

      // Now fetch with details
      final orderResponse = await supabase.from('bookingrequest').select('''
          bookingrequest_id, 
          Local_Cook:localcookid(first_name, last_name, user_id, phone),
          mealplan:mealplan_id(meal_name)
        ''').eq('bookingrequest_id', bookingRequestId).single();

      if (orderResponse.isEmpty) {
        throw Exception('Order details are incomplete');
      }

      final mealName = orderResponse['mealplan']?['meal_name'] ?? 'your meal';
      final cookFirstName =
          orderResponse['Local_Cook']?['first_name'] ?? 'Your cook';
      final cookLastName = orderResponse['Local_Cook']?['last_name'] ?? '';
      final cookName = '$cookFirstName $cookLastName'.trim();
      final cookUserId = orderResponse['Local_Cook']?['user_id'];
      final cookPhone = orderResponse['Local_Cook']?['phone'] ?? 'N/A';

      if (!mounted) return;

      // Show confirmation dialog
      return showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Order Completed',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$cookName has completed your order for $mealName.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Did you receive your order?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 8),
                // Add cook's phone for contact if needed
                Text(
                  'Cook\'s contact: $cookPhone',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text(
                        'Not Yet',
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () async {
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
                                      Text("Confirming receipt..."),
                                    ],
                                  ),
                                ),
                              );
                            },
                          );

                          // Mark notification as read first
                          await markAsRead(
                              notification['notification_id'].toString());

                          // Get the meal plan ID from the booking request
                          final bookingDetails = await supabase
                              .from('bookingrequest')
                              .select('mealplan_id')
                              .eq('bookingrequest_id', bookingRequestId)
                              .single();

                          // If there's a mealplan_id, mark it as completed
                          if (bookingDetails != null &&
                              bookingDetails['mealplan_id'] != null) {
                            try {
                              final mealplanId = bookingDetails['mealplan_id'];

                              // Update the meal plan to mark it as completed
                              await supabase
                                  .from('mealplan')
                                  .update({'is_completed': true}).eq(
                                      'mealplan_id', mealplanId);
                            } catch (e) {
                              // Continue with the process even if this update fails
                            }
                          }

                          try {
                            // Try to update is_received, but handle missing column gracefully
                            await supabase
                                .from('bookingrequest')
                                .update({'is_received': true}).eq(
                                    'bookingrequest_id', bookingRequestId);
                          } catch (e) {
                            // Continue with the process even if this update fails
                          }

                          // Confirm receipt by updating is_received
                          await supabase
                              .from('bookingrequest')
                              .update({'is_received': true}).eq(
                                  'bookingrequest_id', bookingRequestId);

                          if (!mounted) return;

                          // Update the notification's local state to reflect the receipt confirmation
                          setState(() {
                            final notificationId =
                                notification['notification_id'];

                            // Find and update the notification in our local state
                            for (var dateKey in groupedNotifications.keys) {
                              final notifications =
                                  groupedNotifications[dateKey]!;
                              for (var i = 0; i < notifications.length; i++) {
                                if (notifications[i]['notification_id'] ==
                                    notificationId) {
                                  // Mark the notification with a custom property to indicate receipt
                                  notifications[i]['is_receipt_confirmed'] =
                                      true;
                                  break;
                                }
                              }
                            }
                          });

                          // Send notification to cook about confirmation
                          if (cookUserId != null) {
                            await supabase.rpc(
                              'create_notification',
                              params: {
                                'p_recipient_id': cookUserId,
                                'p_sender_id': widget.currentUserId,
                                'p_title': 'Order Receipt Confirmed',
                                'p_message':
                                    'The family has confirmed receipt of the order for $mealName',
                                'p_notification_type': 'delivery_status',
                                'p_related_id': bookingRequestId,
                              },
                            );
                          }

                          if (!mounted) return;

                          // Close loading dialog
                          Navigator.of(context).pop();
                          // Close confirmation dialog
                          Navigator.of(context).pop();

                          // Show success confirmation
                          _showSuccessDialog(context, 'Receipt Confirmed',
                              'Thank you for confirming receipt of your order for $mealName.');

                          // Refresh notifications list
                          fetchNotifications();
                        } catch (e) {
                          if (!mounted) return;

                          // Close loading dialog if open
                          Navigator.of(context).pop();
                          // Close confirmation dialog
                          Navigator.of(context).pop();

                          String errorMessage =
                              'Could not confirm order receipt';
                          if (e.toString().contains('foreign key constraint')) {
                            errorMessage =
                                'This order appears to be invalid in the system.';
                          }

                          _showErrorDialog(context, 'Error',
                              '$errorMessage: ${e.toString()}');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Order Received',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      // Handle the case where the booking request is missing
      return showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Order Not Found"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  "This order appears to have been removed from the system."),
              const SizedBox(height: 12),
              Text("Technical details: ${e.toString()}",
                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
              const SizedBox(height: 12),
              const Text("Would you like to dismiss this notification?"),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("Keep"),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text("Dismiss Notification"),
              onPressed: () async {
                Navigator.of(context).pop(); // Close the current dialog

                // Show loading dialog
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (BuildContext context) => const Dialog(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(width: 20),
                          Text("Removing notification..."),
                        ],
                      ),
                    ),
                  ),
                );

                try {
                  await supabase
                      .from('notifications')
                      .delete()
                      .eq('notification_id', notification['notification_id']);

                  if (!mounted) return;

                  // Close loading dialog
                  Navigator.of(context).pop();

                  // Show success message
                  _showSuccessDialog(context, 'Notification Removed',
                      'The notification has been removed from your list.');

                  // Refresh notifications list
                  fetchNotifications();
                } catch (e) {
                  if (!mounted) return;

                  // Close loading dialog
                  Navigator.of(context).pop();

                  _showErrorDialog(context, 'Error',
                      'Failed to remove notification: ${e.toString()}');
                }
              },
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    if (!mounted) return;

    final notificationType = notification['notification_type'];
    final title = notification['title'];
    final senderId = notification['sender_id'];

    // Special handling for order status completion notifications
    if (notificationType == 'delivery_status' &&
        title == 'Order Status: Completed') {
      await _showOrderCompletionDialog(notification);
      return;
    }

    // For other notifications, mark as read first
    if (!(notification['is_read'] ?? false)) {
      try {
        await markAsRead(notification['notification_id'].toString());
      } catch (e) {
        if (!mounted) return;
        _showErrorDialog(
            context, 'Error', 'Error marking notification as read: $e');
      }
    }

    // Then handle navigation
    switch (notificationType) {
      case 'meal_plan':
      case 'meal_completion':
        widget.onPageChange?.call(0);
        break;

      case 'booking_status':
        widget.onPageChange?.call(3);
        break;

      case 'message':
        if (senderId != null && widget.currentUserId != null) {
          try {
            final chatRoomId =
                await getOrCreateChatRoom(senderId, widget.currentUserId!);
            final cookData = await supabase
                .from('Local_Cook')
                .select('first_name, last_name')
                .eq('user_id', senderId)
                .single();

            if (!mounted) return;

            final cookName =
                '${cookData['first_name']} ${cookData['last_name']}';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatRoomPage(
                  chatRoomId: chatRoomId,
                  recipientName: cookName,
                ),
              ),
            );
          } catch (e) {
            if (!mounted) return;
            _showErrorDialog(context, 'Error', 'Error opening chat: $e');
          }
        }
        break;

      // For delivery_status notifications (not "completed" ones)
      case 'delivery_status':
        _showOrderStatusDetails(notification);
        break;

      case 'support_response':
        await _handleSupportResponseNotification(notification);
        break;
    }
  }

  // Add method to show order status details
  Future<void> _showOrderStatusDetails(
      Map<String, dynamic> notification) async {
    final bookingRequestId = notification['related_id'];

    try {
      var statusTitle = notification['title'];
      final message = notification['message'];

      // Get more details about this order
      final orderResponse = await supabase.from('bookingrequest').select('''
            bookingrequest_id, 
            delivery_status_id,
            desired_delivery_time,
            is_received,
            mealplan:mealplan_id(meal_name, is_completed),
            Local_Cook:localcookid(first_name, last_name, phone)
          ''').eq('bookingrequest_id', bookingRequestId).single();

      final statusId = orderResponse['delivery_status_id'];
      final mealName = orderResponse['mealplan']?['meal_name'] ?? 'N/A';
      final cookFirstName = orderResponse['Local_Cook']?['first_name'] ?? '';
      final cookLastName = orderResponse['Local_Cook']?['last_name'] ?? '';
      final cookPhone = orderResponse['Local_Cook']?['phone'] ?? 'N/A';
      final cookName = '$cookFirstName $cookLastName'.trim();
      final isReceived = orderResponse['is_received'] == true;
      final isMealCompleted =
          orderResponse['mealplan']?['is_completed'] == true;

      // Format delivery time
      String deliveryTime = 'N/A';
      if (orderResponse['desired_delivery_time'] != null) {
        try {
          final dateTime =
              DateTime.parse(orderResponse['desired_delivery_time']);
          deliveryTime = DateFormat('MMM dd, yyyy - hh:mm a').format(dateTime);
        } catch (e) {}
      }

      // Determine status color and icon
      IconData statusIcon;
      Color statusColor;

      switch (statusId) {
        case 2:
          statusIcon = Icons.restaurant;
          statusColor = Colors.orange;
          break;
        case 3:
          statusIcon = Icons.delivery_dining;
          statusColor = Colors.blue;
          break;
        case 4:
          statusIcon = Icons.check_circle;
          statusColor = Colors.green;
          break;
        default:
          statusIcon = Icons.hourglass_bottom;
          statusColor = Colors.amber;
      }

      // Check if order has been received
      if (isReceived) {
        statusIcon = Icons.verified;
        statusColor = Colors.green;
        // Update status title to show it's received
        statusTitle = 'Order Received';
      }

      if (!mounted) return;

      // Show the order status details dialog
      showDialog(
        context: context,
        builder: (context) => Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status header
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 32),
                    const SizedBox(width: 12),
                    Text(
                      statusTitle.replaceAll('Order Status: ', ''),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Order details
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDetailRow('Order', mealName),
                      _buildDetailRow('Cook', cookName),
                      _buildDetailRow('Phone', cookPhone),
                      _buildDetailRow('Delivery Time', deliveryTime),
                      _buildDetailRow('Status Update', message),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: statusId == 4
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.end,
                  children: [
                    if (statusId == 4 && !isReceived)
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showOrderCompletionDialog(notification);
                        },
                        child: const Text(
                          'Order received?',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    if (isReceived)
                      Text(
                        'Order confirmed on ${DateFormat('MMM dd, yyyy - hh:mm a').format(DateTime.parse(notification['updated_at'] ?? notification['created_at']))}',
                        style: TextStyle(
                          color: Colors.green,
                          fontStyle: FontStyle.italic,
                          fontSize: 12,
                        ),
                      ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorDialog(context, 'Error', 'Could not load order details: $e');
      }
    }
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

  Future<String> getOrCreateChatRoom(
      String cookUserId, String familyMemberUserId) async {
    try {
      final response = await supabase.rpc(
        'get_or_create_chat_room',
        params: {
          'family_member_user_id': familyMemberUserId,
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

  Widget _buildNotificationIcon(String type, [String? title]) {
    IconData iconData;
    Color iconColor;

    // First check meal plan notifications
    if (type == 'meal_plan' || type == 'meal_completion') {
      iconData = Icons.restaurant_menu;
      iconColor = Colors.green;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor),
      );
    }

    // Check for order status notifications
    if (title != null && title.startsWith('Order Status:')) {
      if (title.contains('Preparing')) {
        iconData = Icons.restaurant;
        iconColor = Colors.orange;
      } else if (title.contains('On Delivery')) {
        iconData = Icons.delivery_dining;
        iconColor = Colors.blue;
      } else if (title.contains('Completed')) {
        iconData = Icons.check_circle;
        iconColor = Colors.green;
      } else {
        iconData = Icons.notifications;
        iconColor = Colors.grey;
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

    // Check for receipt confirmation notification
    if (title != null && title == 'Order Receipt Confirmed') {
      iconData = Icons.verified;
      iconColor = Colors.green;
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(iconData, color: iconColor),
      );
    }

    // Check for booking status notifications
    if (title != null) {
      if (title == 'Booking Accepted') {
        iconData = Icons.check_circle;
        iconColor = Colors.green;
      } else if (title == 'Booking Declined') {
        iconData = Icons.close;
        iconColor = Colors.red;
      } else {
        iconData = Icons.notifications;
        iconColor = Colors.grey;
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

    // Default handling for other notification types
    switch (type) {
      case 'message':
        iconData = Icons.message;
        iconColor = Colors.blue;
        break;
      case 'booking':
        iconData = Icons.book_online;
        iconColor = Colors.green;
        break;
      case 'delivery':
      case 'delivery_status':
        iconData = Icons.delivery_dining;
        iconColor = Colors.purple;
        break;
      case 'support_response':
        iconData = Icons.question_answer;
        iconColor = Colors.green;
        break;
      default:
        iconData = Icons.notifications;
        iconColor = Colors.grey;
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
          // Convert to day indices (0 is Sunday in DateTime)
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

              // Check if this is order completion notification
              final bool isOrderCompletion =
                  notification['notification_type'] == 'delivery_status' &&
                      notification['title'] == 'Order Status: Completed';

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
                    _showErrorDialog(
                        context, 'Error', 'Error deleting notification: $e');
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
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
                        notification['title'],
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
                            notification['message'],
                            style: TextStyle(
                              color: isRead
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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

                              // Add action button for completed orders using the OrderActionButton widget
                              if (isOrderCompletion)
                                OrderActionButton(
                                  notification: notification,
                                  onTap: _showOrderCompletionDialog,
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
                    ),
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }
}
