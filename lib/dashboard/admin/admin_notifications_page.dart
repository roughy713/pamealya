import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class AdminNotificationsPage extends StatefulWidget {
  const AdminNotificationsPage({super.key});

  @override
  _AdminNotificationsPageState createState() => _AdminNotificationsPageState();
}

class _AdminNotificationsPageState extends State<AdminNotificationsPage> {
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .order('created_at', ascending: false)
          .limit(50);

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching notifications: $e')),
        );
      }
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .update({'is_read': true}).eq('notification_id', notificationId);

      // Update the local list
      setState(() {
        final index = notifications.indexWhere((notification) =>
            notification['notification_id'] == notificationId);
        if (index != -1) {
          notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notification as read: $e')),
      );
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      // Get list of unread notification IDs
      final unreadNotifications = notifications
          .where((notification) => notification['is_read'] == false)
          .toList();

      if (unreadNotifications.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No unread notifications')),
        );
        return;
      }

      // Update each unread notification one by one
      for (var notification in unreadNotifications) {
        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true}).eq(
                'notification_id', notification['notification_id']);
      }

      // Update the local list
      setState(() {
        for (var notification in notifications) {
          if (notification['is_read'] == false) {
            notification['is_read'] = true;
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All notifications marked as read')),
      );
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error marking notifications as read: $e')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await Supabase.instance.client
          .from('notifications')
          .delete()
          .eq('notification_id', notificationId);

      // Remove from local list
      setState(() {
        notifications.removeWhere((notification) =>
            notification['notification_id'] == notificationId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notification deleted')),
      );
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting notification: $e')),
      );
    }
  }

  String _formatDateTime(String? dateTimeString) {
    if (dateTimeString == null) return 'N/A';
    try {
      final dateTime = DateTime.parse(dateTimeString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays == 0) {
        // Today - show time
        return 'Today at ${DateFormat.jm().format(dateTime)}';
      } else if (difference.inDays == 1) {
        // Yesterday
        return 'Yesterday at ${DateFormat.jm().format(dateTime)}';
      } else if (difference.inDays < 7) {
        // Within a week
        return '${DateFormat('EEEE').format(dateTime)} at ${DateFormat.jm().format(dateTime)}';
      } else {
        // More than a week ago
        return DateFormat('MMM d, yyyy').format(dateTime);
      }
    } catch (e) {
      return 'Invalid date';
    }
  }

  Color _getNotificationTypeColor(String? type) {
    switch (type?.toLowerCase()) {
      case 'new_cook':
        return Colors.blue;
      case 'new_family':
        return Colors.purple;
      case 'order':
        return Colors.orange;
      case 'system':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getNotificationTypeIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'new_cook':
        return Icons.person_add;
      case 'new_family':
        return Icons.family_restroom;
      case 'order':
        return Icons.food_bank;
      case 'system':
        return Icons.warning;
      default:
        return Icons.notifications;
    }
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final bool isRead = notification['is_read'] ?? false;
    final String title = notification['title'] ?? 'No Title';
    final String message = notification['message'] ?? 'No Message';
    final String? type = notification['type'];
    final String createdAt = _formatDateTime(notification['created_at']);
    final int notificationId = notification['notification_id'];

    return Card(
      elevation: isRead ? 1 : 3,
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: isRead
            ? BorderSide.none
            : BorderSide(color: _getNotificationTypeColor(type), width: 1.5),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationTypeColor(type).withOpacity(0.2),
          child: Icon(
            _getNotificationTypeIcon(type),
            color: _getNotificationTypeColor(type),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(message, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(
              createdAt,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRead)
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => _markAsRead(notificationId),
                tooltip: 'Mark as read',
              ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _deleteNotification(notificationId),
              tooltip: 'Delete notification',
            ),
          ],
        ),
        onTap: () {
          if (!isRead) {
            _markAsRead(notificationId);
          }

          // Show full notification details
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(title),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(message),
                    const SizedBox(height: 16),
                    Text(
                      'Created: $createdAt',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
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
        },
      ),
    );
  }

  // Static method to get unread count
  static Future<int> getUnreadCount() async {
    try {
      final response = await Supabase.instance.client
          .from('notifications')
          .select()
          .eq('is_read', false);

      // Count the results manually
      return response.length;
    } catch (e) {
      debugPrint('Error fetching unread notifications count: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: _fetchNotifications,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _markAllAsRead,
                      icon: const Icon(Icons.done_all),
                      label: const Text('Mark All as Read'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : hasError
                    ? const Center(
                        child: Text(
                          'Error loading notifications',
                          style: TextStyle(color: Colors.red),
                        ),
                      )
                    : notifications.isEmpty
                        ? const Center(
                            child: Text(
                              'No notifications',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: notifications.length,
                            itemBuilder: (context, index) {
                              return _buildNotificationItem(
                                  notifications[index]);
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
