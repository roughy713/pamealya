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
          .select('mealplan_id, meal_category_id, day, recipe_id, meal_name')
          .eq('family_head', '${widget.firstName} ${widget.lastName}')
          .order('day', ascending: true)
          .order('meal_category_id', ascending: true); // Sort by category

      // Initialize meal plan structure
      List<List<Map<String, dynamic>>> fetchedMealPlan = List.generate(
          7,
          (_) => [
                {
                  'meal_category_id': 1,
                  'meal_name': null,
                  'recipe_id': null,
                  'mealplan_id': null
                }, // Breakfast
                {
                  'meal_category_id': 2,
                  'meal_name': null,
                  'recipe_id': null,
                  'mealplan_id': null
                }, // Lunch
                {
                  'meal_category_id': 3,
                  'meal_name': null,
                  'recipe_id': null,
                  'mealplan_id': null
                }, // Dinner
              ]);

      for (var meal in response) {
        int day = meal['day'] - 1;

        if (day < 0 || day >= 7) continue;

        fetchedMealPlan[day][meal['meal_category_id'] - 1] = meal;
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
      final response =
          await Supabase.instance.client.from('familymember').select('''
          first_name, last_name, age, gender,
          familymember_specialconditions(is_pregnant, is_lactating)
          ''').eq('family_head', '${widget.firstName} ${widget.lastName}');

      final members = response.map((member) {
        final specialConditions = member['familymember_specialconditions'];
        return {
          'first_name': member['first_name'],
          'last_name': member['last_name'],
          'age': member['age'],
          'gender': member['gender'],
          'is_pregnant': specialConditions?['is_pregnant'] ?? false,
          'is_lactating': specialConditions?['is_lactating'] ?? false,
        };
      }).toList();

      setState(() {
        familyMembers = members;
      });
    } catch (e) {
      print('Error fetching family members: $e');
    }
  }

  Future<void> fetchPortionSizeData() async {
    try {
      final response =
          await Supabase.instance.client.from('PortionSize').select('*');

      // Initialize an empty map
      final Map<String, Map<String, dynamic>> portionSizeMap = {};

      for (var row in response) {
        final String? ageGroup = row['AgeGroup'] as String?;
        final String? gender = row['Gender'] as String?;

        if (ageGroup != null) {
          // Add special condition keys (Pregnant, Lactating)
          if (ageGroup == 'Pregnant') {
            portionSizeMap['Pregnant'] = row as Map<String, dynamic>;
          } else if (ageGroup == 'Lactating') {
            portionSizeMap['Lactating'] = row as Map<String, dynamic>;
          }

          // Add ageGroup + gender combination for non-special conditions
          if (gender != null) {
            portionSizeMap['$ageGroup$gender'] = row as Map<String, dynamic>;
          }
        }
      }

      // Update the state
      setState(() {
        portionSizeData = portionSizeMap;
      });

      print('PortionSize Data Loaded: $portionSizeMap');
    } catch (e) {
      print('Error fetching portion size data: $e');
    }
  }

  List<Widget> get _pageDetails => [
        MealPlanDashboard(
          mealPlanData: mealPlanData,
          familyMembers: familyMembers,
          portionSizeData: portionSizeData,
          familyHeadName: '${widget.firstName} ${widget.lastName}',
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          iconTheme: const IconThemeData(color: Color(0xFF1CBB80)),
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
        drawer: CustomDrawer(
          selectedIndex: _selectedIndex,
          onItemTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
            Navigator.pop(context);
          },
          userName: '${widget.firstName} ${widget.lastName}',
          onLogoutTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          },
        ),
        body: _pageDetails[_selectedIndex],
      ),
    );
  }
}
