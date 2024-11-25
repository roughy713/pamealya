import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';
import 'meal_plan_dashboard.dart';
import 'my_family_page.dart';
import 'famhead_chat_page.dart';
import 'cook_page.dart';
import 'notifications_page.dart';
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

  List<List<Map<String, dynamic>>> mealPlanData = [];
  List<Map<String, dynamic>> familyMembers = [];
  Map<String, dynamic> portionSizeData = {};

  final List<String> _titles = [
    'Dashboard',
    'My Family',
    'Chat',
    'Cook',
    'Notifications',
    'Transactions',
  ];

  @override
  void initState() {
    super.initState();
    fetchMealPlan();
    fetchFamilyMembers();
    fetchPortionSizeData();
  }

  Future<void> fetchMealPlan() async {
    try {
      final response = await Supabase.instance.client
          .from('mealplan')
          .select()
          .eq('family_head', '${widget.firstName} ${widget.lastName}')
          .order('day', ascending: true)
          .then((data) => data as List<dynamic>);

      List<List<Map<String, dynamic>>> fetchedMealPlan =
          List.generate(7, (_) => []);

      for (var meal in response) {
        int day = meal['day'] - 1;
        fetchedMealPlan[day].add({
          'meal_type': meal['meal_type'],
          'meal_name': meal['meal_name'],
          'recipe_id': meal['meal_id'],
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

  Future<void> fetchFamilyMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select('first_name, last_name, age, gender')
          .eq('family_head', '${widget.firstName} ${widget.lastName}')
          .then((data) => data as List<dynamic>);

      final members = response.map((member) {
        return {
          'first_name': member['first_name'],
          'last_name': member['last_name'],
          'age': member['age'],
          'gender': member['gender'],
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

  Future<void> fetchPortionSizeData() async {
    try {
      final response = await Supabase.instance.client
          .from('PortionSize')
          .select(
              'AgeGroup, Gender, Rice_breakfast, Rice_lunch, Rice_dinner, Proteins_per_meal, FruitsVegetables_per_meal, Water_per_meal')
          .then((data) => data as List<dynamic>);

      Map<String, dynamic> portionMap = {};
      for (var portion in response) {
        portionMap['${portion['AgeGroup']}_${portion['Gender']}'] = portion;
      }

      setState(() {
        portionSizeData = portionMap;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching portion size data: $e')),
      );
    }
  }

  List<Widget> get _pageDetails => [
        MealPlanDashboard(
          mealPlanData: mealPlanData,
          familyMembers: familyMembers,
          portionSizeData: portionSizeData,
        ),
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
