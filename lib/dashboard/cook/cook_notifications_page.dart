import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:timeago/timeago.dart' as timeago;
import '/common/chat_room_page.dart';

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

    print('Setting up notifications for cook with ID: $userId');

    supabase
        .from('notifications')
        .stream(primaryKey: ['notification_id'])
        .eq('recipient_id', userId)
        .order('created_at', ascending: false)
        .listen((List<Map<String, dynamic>> data) {
          print('Cook received notification data: $data');
          if (mounted) {
            setState(() {
              notifications = data;
            });
          }
        }, onError: (error) {
          print('Cook notification subscription error: $error');
        });
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
          .order('created_at', ascending: false);

      print('Cook fetched notifications: $response');

      if (mounted) {
        setState(() {
          notifications = List<Map<String, dynamic>>.from(response);
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

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final notificationType = notification['notification_type'];
    final senderId = notification['sender_id'];
    print('Handling notification type: $notificationType');

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

    // Mark notification as read when clicked
    if (!(notification['is_read'] ?? false)) {
      markAsRead(notification['notification_id'].toString());
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
                notification['notification_type'],
                notification['title'],
              ),
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
                _handleNotificationTap(notification);
              },
              tileColor: isRead ? null : Colors.grey.withOpacity(0.1),
            ),
          ),
        );
      },
    );
  }
}
