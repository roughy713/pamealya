import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/common/chat_room_page.dart';
import 'dart:async';

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
  bool isLoading = true;
  StreamSubscription? _notificationSubscription;

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

    print('Setting up notifications for family head with ID: $userId');

    _notificationSubscription = supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
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
    if (!mounted) return;

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      print('Fetching notifications for family head: $userId');

      final response = await supabase
          .from('notifications')
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        notifications = List<Map<String, dynamic>>.from(response);
        isLoading = false;
      });
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
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    if (!mounted) return;

    final notificationType = notification['notification_type'];
    final senderId = notification['sender_id'];

    // Mark notification as read first
    if (!(notification['is_read'] ?? false)) {
      try {
        await markAsRead(notification['notification_id'].toString());
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error marking notification as read: $e')),
        );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error opening chat: $e')),
            );
          }
        }
        break;
    }
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
        iconData = Icons.fastfood;
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

              if (!mounted) return;

              setState(() {
                notifications.removeAt(index);
              });
            } catch (e) {
              print('Error deleting notification: $e');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error deleting notification: $e')),
              );
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
              onTap: () => _handleNotificationTap(notification),
              tileColor: isRead ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }
}
