import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;

class FamHeadNotificationsPage extends StatefulWidget {
  const FamHeadNotificationsPage({super.key});

  @override
  _FamHeadNotificationsPageState createState() =>
      _FamHeadNotificationsPageState();
}

class _FamHeadNotificationsPageState extends State<FamHeadNotificationsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchNotifications();
    _setupNotificationSubscription();
  }

  void _setupNotificationSubscription() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    print('Setting up notifications for family head with ID: $userId');

    supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          print('Family head received notification data: $data');
          if (mounted) {
            setState(() {
              notifications = data;
            });
          }
        }, onError: (error) {
          print('Family head notification subscription error: $error');
        });
  }

  Future<void> fetchNotifications() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('Fetching notifications for family head: $userId');

      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      print('Raw notification response: $response'); // Debug print

      if (response == null) {
        print('No notifications found');
        return;
      }

      if (mounted) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });
        print(
            'Number of notifications loaded: ${notifications.length}'); // Debug print
        // Print first few notifications for debugging
        for (var i = 0; i < notifications.length && i < 3; i++) {
          print('Notification ${i + 1}: ${notifications[i]}');
        }
      }
    } catch (e) {
      print('Error fetching family head notifications: $e');
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

      setState(() {
        final index = notifications.indexWhere(
            (n) => n['notification_id'].toString() == notificationId);
        if (index != -1) {
          notifications[index]['is_read'] = true;
        }
      });
    } catch (e) {
      print('Error marking notification as read: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
      }
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
        iconData = Icons.fastfood;
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
        iconData = Icons.delivery_dining;
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
        iconData = Icons.check_circle;
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

    // Check for booking status notifications
    if (title != null) {
      if (title == 'Booking Accepted') {
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor),
        );
      } else if (title == 'Booking Declined') {
        iconData = Icons.close;
        iconColor = Colors.red;
        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
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

    if (notifications.isEmpty) {
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

    return ListView.builder(
      itemCount: notifications.length,
      itemBuilder: (context, index) {
        final notification = notifications[index];
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
          onDismissed: (direction) async {
            try {
              await supabase
                  .from('notifications')
                  .delete()
                  .eq('notification_id', notification['notification_id']);

              setState(() {
                notifications.removeAt(index);
              });
            } catch (e) {
              print('Error deleting notification: $e');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting notification: $e')),
                );
              }
            }
          },
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ListTile(
              leading: _buildNotificationIcon(
                  notification['notification_type'], notification['title']),
              title: Text(
                notification['title'],
                style: TextStyle(
                  fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(notification['message']),
                  Text(
                    timeAgo,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
              onTap: () {
                if (!isRead) {
                  markAsRead(notification['notification_id'].toString());
                }
              },
              tileColor: isRead ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }
}
