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
import '/home_page.dart'; // Assuming HomePage is your login screen

class CookDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserId; // Receive the current user ID

  const CookDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.currentUserId,
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
    'Chat with Family Head',
    'Reviews',
    'Earnings',
    'Support',
  ];

  Future<List<Map<String, dynamic>>> _fetchFamilyHeads() async {
    // Fetch Family Heads from the Family_Head table
    final response =
        await Supabase.instance.client.from('Family_Head').select();

    // Check if the response has data
    if (response != null) {
      return List<Map<String, dynamic>>.from(response as List);
    } else {
      throw Exception('Error fetching family heads');
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
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
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
        onLogoutTap: () => _handleLogout(context), // Pass the logout handler
      ),
      onDrawerChanged: _onDrawerStateChanged,
      body: _selectedIndex == 3
          ? FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchFamilyHeads(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final familyHeads = snapshot.data ?? [];
                if (familyHeads.isEmpty) {
                  return const Center(
                      child: Text('No Family Heads available.'));
                }

                // Display list of Family Heads
                return ListView.builder(
                  itemCount: familyHeads.length,
                  itemBuilder: (context, index) {
                    final familyHead = familyHeads[index];
                    return ListTile(
                      title: Text(
                          '${familyHead['first_name']} ${familyHead['last_name']}'),
                      onTap: () {
                        // Navigate to CookChatPage when a Family Head is selected
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CookChatPage(
                              currentUserId: widget.currentUserId,
                              otherUserId: familyHead['user_id'],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            )
          : _getPage(_selectedIndex),
      floatingActionButton: _selectedIndex == 3
          ? null // No floating action button for family head chat selection
          : null,
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
