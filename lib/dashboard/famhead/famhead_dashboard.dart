// lib/fam_head_dashboard.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';
import 'meal_plan_dashboard.dart';
import 'my_family_page.dart';
import 'famhead_chat_page.dart';
import 'cook_page.dart';
import 'notifications_page.dart';
import 'bmi_calculator_page.dart';
import 'transactions_page.dart';
import 'custom_drawer.dart';

class FamHeadDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserUsername;

  const FamHeadDashboard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.currentUserUsername,
  });

  @override
  FamHeadDashboardState createState() => FamHeadDashboardState();
}

class FamHeadDashboardState extends State<FamHeadDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  // State variables to hold the retrieved meal plan data and family members data
  List<List<Map<String, dynamic>>> mealPlanData = [];
  List<Map<String, dynamic>> familyMembers = []; // Added familyMembers variable

  final List<String> _titles = [
    'Dashboard',
    'My Family',
    'Chat',
    'Cook',
    'Notifications',
    'BMI Calculator',
    'Transactions',
  ];

  // Define pages in the navigation
  List<Widget> get _pageDetails => [
        mealPlanData.isNotEmpty && familyMembers.isNotEmpty
            ? MealPlanDashboard(
                mealPlanData: mealPlanData,
                familyMembers: familyMembers, // Pass familyMembers here
              )
            : const Center(child: Text('No meal plan generated')),
        MyFamilyPage(
          initialFirstName: widget.firstName,
          initialLastName: widget.lastName,
        ),
        FamHeadChatPage(
          currentUserId: widget.firstName,
          currentUserUsername: widget.currentUserUsername,
        ),
        CookPage(
          userFirstName: widget.firstName,
          userLastName: widget.lastName,
        ),
        const NotificationsPage(),
        const BMICalculatorPage(),
        const TransactionPage(),
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
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  // Fetch the saved meal plan from the database
  Future<void> fetchMealPlan() async {
    try {
      final response = await Supabase.instance.client
          .from('mealplan')
          .select()
          .eq('family_head',
              '${widget.firstName} ${widget.lastName}') // Filter by family head's name
          .order('day', ascending: true)
          .then((data) => data as List<dynamic>);

      List<List<Map<String, dynamic>>> fetchedMealPlan =
          List.generate(7, (_) => []); // Initialize 7 days of meal plans

      for (var meal in response) {
        int day = meal['day'] - 1; // Convert day to 0-based index
        String mealType = meal['meal_type'];
        fetchedMealPlan[day].add({
          'meal_type': mealType,
          'meal_name': meal['meal_name'],
          'meal_id': meal['meal_id'],
        });
      }

      setState(() {
        mealPlanData = fetchedMealPlan;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meal plan: $e')),
      );
    }
  }

  // Fetch family members' data with age groups and portion sizes
  Future<void> fetchFamilyMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select('first_name, age, family_head') // Include fields you need
          .eq('family_head',
              '${widget.firstName} ${widget.lastName}') // Filter by family head's name
          .then((data) => data as List<dynamic>);

      final portionSizes = {
        'Kids 3-5': {'Carbohydrates': '1 cup', 'Proteins': '50 grams'},
        'Kids 6-9': {'Carbohydrates': '1.5 cups', 'Proteins': '75 grams'},
        'Adults': {'Carbohydrates': '2 cups', 'Proteins': '100 grams'},
      };

      final members = response.map((member) {
        final ageField = member['age'];
        final age = ageField is int
            ? ageField
            : int.tryParse(ageField ?? '0') ?? 0; // Convert age safely
        final ageGroup = determineAgeGroup(age); // Determine the age group
        return {
          'name': member['first_name'],
          'ageGroup': ageGroup,
          'portions': portionSizes[ageGroup],
        };
      }).toList();

      setState(() {
        familyMembers = members;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching family members: $e')),
      );
    }
  }

// Helper function to determine age group
  String determineAgeGroup(int age) {
    if (age >= 3 && age <= 5) return 'Kids 3-5';
    if (age >= 6 && age <= 9) return 'Kids 6-9';
    return 'Adults';
  }

  @override
  void initState() {
    super.initState();
    fetchMealPlan(); // Fetch the meal plan when the dashboard initializes
    fetchFamilyMembers(); // Fetch family members when the dashboard initializes
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isDrawerOpen) {
          setState(() {
            _isDrawerOpen = false;
          });
          return false;
        }
        return true;
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(56.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            transform: Matrix4.translationValues(
                _isDrawerOpen ? 300.0 : 0.0, 0.0, 0.0),
            child: AppBar(
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Color(0xFF1CBB80)),
              elevation: 0,
              title: Text(
                _titles[_selectedIndex],
                style: const TextStyle(
                    color: Colors.black, fontWeight: FontWeight.bold),
              ),
              leading: IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
              ),
            ),
          ),
        ),
        drawer: CustomDrawer(
          selectedIndex: _selectedIndex,
          onItemTap: _onSelectItem,
          userName: '${widget.firstName} ${widget.lastName}',
          onLogoutTap: () => _handleLogout(context),
        ),
        onDrawerChanged: _onDrawerStateChanged,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.only(left: _isDrawerOpen ? 200 : 0),
          child: _pageDetails[_selectedIndex],
        ),
      ),
    );
  }
}
