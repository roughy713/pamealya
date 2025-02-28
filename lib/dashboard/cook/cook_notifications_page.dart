import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';
import '/common/chat_room_page.dart';
import 'dart:async';

class CookNotificationsPage extends StatefulWidget {
  final Function(int)? onPageChange;
  final String? currentUserId;

  const CookNotificationsPage({
    super.key,
    this.onPageChange,
    this.currentUserId,
  });

  @override
  _CookNotificationsPageState createState() => _CookNotificationsPageState();
}

class _CookNotificationsPageState extends State<CookNotificationsPage> {
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

  void _setupNotificationSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    print('Setting up notifications for cook with ID: $userId');

    _notificationSubscription = supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: _sortOrder == 'oldest')
        .listen((List<Map<String, dynamic>> data) {
          print('Cook received notification data: $data');
          if (mounted) {
            setState(() {
              notifications = data;
              _updateUnreadCount();
              _groupNotificationsByDate();
            });
          }
        }, onError: (error) {
          print('Cook notification subscription error: $error');
        });
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
    fetchNotifications();
    // Update the subscription with the new sort order
    _notificationSubscription?.cancel();
    _setupNotificationSubscription();
  }

  Future<void> fetchNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('Fetching notifications for cook: $userId');

      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: _sortOrder == 'oldest');

      print('Cook fetched notifications: $response');

      if (mounted) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(response);
          _updateUnreadCount();
          _groupNotificationsByDate();
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching cook notifications: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
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
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
    }
  }

  Future<void> markAllAsRead() async {
    if (!mounted || notifications.isEmpty) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await supabase.rpc(
        'mark_all_notifications_read',
        params: {'p_user_id': userId},
      );

      if (!mounted) return;

      setState(() {
        for (var i = 0; i < notifications.length; i++) {
          notifications[i]['is_read'] = true;
        }
        unreadCount = 0;
        _groupNotificationsByDate(); // Update groupings with new read status
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notifications as read: $e')),
      );
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final notificationType = notification['notification_type'];
    final senderId = notification['sender_id'];
    print('Handling notification type: $notificationType');

    // Mark notification as read when clicked
    if (!(notification['is_read'] ?? false)) {
      await markAsRead(notification['notification_id'].toString());
    }

    switch (notificationType) {
      case 'booking':
        print('Navigating to booking requests page...');
        widget.onPageChange?.call(1);
        break;

      case 'delivery_status':
        print('Navigating to orders page...');
        widget.onPageChange?.call(2);
        break;

      case 'message':
        print('Navigating to chat room...');
        if (senderId != null && widget.currentUserId != null) {
          try {
            // Get or create chat room
            final String chatRoomId =
                await getOrCreateChatRoom(senderId, widget.currentUserId!);

            // Get sender's name
            final senderData = await supabase
                .from('familymember')
                .select('first_name, last_name')
                .eq('user_id', senderId)
                .single();

            final senderName =
                '${senderData['first_name']} ${senderData['last_name']}';

            if (mounted) {
              // Navigate to chat room
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ChatRoomPage(
                    chatRoomId: chatRoomId,
                    recipientName: senderName,
                  ),
                ),
              );
            }
          } catch (e) {
            print('Error navigating to chat room: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error opening chat: $e')),
              );
            }
          }
        }
        break;

      default:
        print('Unknown notification type: $notificationType');
    }
  }

  Future<String> getOrCreateChatRoom(
      String familyMemberUserId, String cookUserId) async {
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

    // First check if it's an order status notification
    if (title != null && title.startsWith('Order Status:')) {
      if (title.contains('Preparing')) {
        iconData = Icons.fastfood; // Food icon for preparing
        iconColor = Colors.orange;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        );
      } else if (title.contains('On Delivery')) {
        iconData = Icons.delivery_dining; // Delivery icon
        iconColor = Colors.blue;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        );
      } else if (title.contains('Completed')) {
        iconData = Icons.check_circle; // Checkmark circle icon
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
        iconData = Icons.delivery_dining;
        iconColor = Colors.purple;
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
                    print('Error deleting notification: $e');
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
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }
}
