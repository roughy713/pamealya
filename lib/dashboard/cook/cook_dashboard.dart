import 'package:flutter/material.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'booking_requests_page.dart';
import 'orders_page.dart';
import 'cook_chat_page.dart';
import 'reviews_page.dart';
import 'earnings_page.dart';
import 'support_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';

class CookDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserId; // Receive the current cook user ID
  final String currentUserUsername; // Add username field for current user

  const CookDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.currentUserId,
    required this.currentUserUsername, // Add currentUserUsername to constructor
  }) : super(key: key);

  @override
  CookDashboardState createState() => CookDashboardState();
}

class CookDashboardState extends State<CookDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<String> _titles = [
    'Dashboard',
    'Booking Requests',
    'Orders',
    'Chat',
    'Reviews',
    'Earnings',
    'Support',
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _scaffoldKey.currentState?.closeDrawer();
    });
  }

  void _onDrawerStateChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // This removes all previous routes
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: CustomDrawer(
        selectedIndex: _selectedIndex,
        onItemTap: _onSelectItem,
        userName: '${widget.firstName} ${widget.lastName}',
        onLogoutTap: () => _handleLogout(context),
      ),
      onDrawerChanged: _onDrawerStateChanged,
      body: _selectedIndex == 3
          ? CookChatPage(
              currentUserId: widget.currentUserId,
              currentUserUsername:
                  widget.currentUserUsername, // Pass username here
            )
          : _getPage(_selectedIndex),
    );
  }

  Widget _getPage(int index) {
    List<Widget> pageDetails = [
      const DashboardPage(),
      const BookingRequestsPage(),
      const OrdersPage(),
      const Center(child: Text('Select a Family Head to chat')),
      const ReviewsPage(),
      const EarningsPage(),
      const SupportPage(),
    ];
    return pageDetails[index];
  }
}
