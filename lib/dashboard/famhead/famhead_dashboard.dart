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
          .order('day', ascending: true);

      // Initialize a list with 7 days, each containing 3 empty maps (for Breakfast, Lunch, Dinner)
      List<List<Map<String, dynamic>>> fetchedMealPlan = List.generate(
          7,
          (_) => [
                {
                  'meal_type': 'Breakfast',
                  'meal_name': null,
                  'recipe_id': null,
                  'mealplan_id': null
                },
                {
                  'meal_type': 'Lunch',
                  'meal_name': null,
                  'recipe_id': null,
                  'mealplan_id': null
                },
                {
                  'meal_type': 'Dinner',
                  'meal_name': null,
                  'recipe_id': null,
                  'mealplan_id': null
                },
              ]);

      for (var meal in response) {
        int day = meal['day'] - 1;

        if (day < 0 || day >= 7) {
          continue; // Ignore invalid day values
        }

        // Capitalize the meal_type
        String mealTypeCapitalized =
            '${meal['meal_type'][0].toUpperCase()}${meal['meal_type'].substring(1)}';

        Map<String, dynamic> mealData = {
          'meal_type': mealTypeCapitalized,
          'meal_name': meal['meal_name'],
          'recipe_id': meal['recipe_id'],
          'mealplan_id': meal['mealplan_id'],
        };

        // Place meals in the correct slot based on meal_type
        if (mealTypeCapitalized == 'Breakfast') {
          fetchedMealPlan[day][0] = mealData;
        } else if (mealTypeCapitalized == 'Lunch') {
          fetchedMealPlan[day][1] = mealData;
        } else if (mealTypeCapitalized == 'Dinner') {
          fetchedMealPlan[day][2] = mealData;
        }
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
          .eq('family_head', '${widget.firstName} ${widget.lastName}');

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
      final response = await Supabase.instance.client.from('PortionSize').select(
          'AgeGroup, Gender, Rice_breakfast, Rice_lunch, Rice_dinner, Proteins_per_meal, FruitsVegetables_per_meal, Water_per_meal');

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
