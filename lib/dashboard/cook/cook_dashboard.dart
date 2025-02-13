import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';
import 'custom_drawer.dart';
import 'dashboard_page.dart';
import 'booking_requests_page.dart';
import 'orders_page.dart';
import 'cook_chat_page.dart';
import 'reviews_page.dart';
import 'earnings_page.dart';
import 'support_page.dart';
import 'cook_notifications_page.dart';

class CookDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserId;
  final String currentUserUsername;

  const CookDashboard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.currentUserId,
    required this.currentUserUsername,
  });

  @override
  CookDashboardState createState() => CookDashboardState();
}

class CookDashboardState extends State<CookDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;
  bool _isSessionRestoring = true;
  bool _isLoggingOut = false;

  final List<String> _titles = [
    'Dashboard',
    'Booking Requests',
    'Orders',
    'Chat',
    'Notifications',
    'Reviews',
    'Earnings',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    _restoreSession();
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.signedOut && !_isLoggingOut) {
        _handleLogout(context);
      }
    });
  }

  Future<void> _restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } else {
      setState(() {
        _isSessionRestoring = false;
      });
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    setState(() {
      _isLoggingOut = true;
    });
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false,
      );
    } catch (e) {
      setState(() {
        _isLoggingOut = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionRestoring) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      drawer: CustomDrawer(
        selectedIndex: _selectedIndex,
        userName: '${widget.firstName} ${widget.lastName}',
        onItemTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          Navigator.pop(context);
        },
        onLogoutTap: () => _handleLogout(context),
      ),
      body: _getPage(_selectedIndex),
    );
  }

  void changePage(int index) {
    print('Changing page to index: $index'); // Debug print
    setState(() {
      _selectedIndex = index;
    });
  }

  Widget _getPage(int index) {
    List<Widget> pageDetails = [
      const DashboardPage(),
      const BookingRequestsPage(),
      const OrdersPage(),
      CookChatPage(
        currentUserId: widget.currentUserId,
      ),
      CookNotificationsPage(
        onPageChange: (pageIndex) {
          print('onPageChange called with index: $pageIndex');
          changePage(pageIndex);
        },
        currentUserId: widget.currentUserId, // Add this line
      ),
      const ReviewsPage(),
      const EarningsPage(),
      const SupportPage(),
    ];
    return pageDetails[index];
  }
}
