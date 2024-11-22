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
  bool _isLoggingOut = false; // To prevent redundant logout handling

  final List<String> _titles = [
    'Dashboard',
    'Booking Requests',
    'Orders',
    'Chat',
    'Reviews',
    'Earnings',
    'Support',
  ];

  @override
  void initState() {
    super.initState();
    _restoreSession();

    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      final session = event.session;

      if (event.event == AuthChangeEvent.signedOut) {
        if (!_isLoggingOut) {
          _isLoggingOut = true;
          _handleLogout(context); // Redirect to login if the session is lost
        }
      }
    });
  }

  Future<void> _restoreSession() async {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      // Redirect to the home page if there's no session
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
    if (_isLoggingOut) return; // Prevent redundant logout handling
    setState(() {
      _isLoggingOut = true;
    });

    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const HomePage()),
        (route) => false, // Remove all previous routes
      );
    } catch (e) {
      setState(() {
        _isLoggingOut = false; // Allow retry in case of error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSessionRestoring) {
      // Show a loading indicator while restoring session
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
        onItemTap: _onSelectItem,
        userName: '${widget.firstName} ${widget.lastName}',
        onLogoutTap: () => _handleLogout(context),
      ),
      onDrawerChanged: _onDrawerStateChanged,
      body: _selectedIndex == 3
          ? CookChatPage(
              currentUserId: widget.currentUserId,
              currentUserUsername: widget.currentUserUsername,
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
