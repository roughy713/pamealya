import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '/home_page.dart';
import 'meal_plan_dashboard.dart';
import 'my_family_page.dart';
import 'famhead_chat_page.dart';
import 'my_bookings_page.dart';
import 'famhead_notifications_page.dart';
import 'transactions_page.dart';
import 'meal_completion_handler.dart';
import 'custom_drawer.dart';

class FamHeadDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String currentUserUsername;
  final String currentUserId;

  const FamHeadDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
    required this.currentUserUsername,
    required this.currentUserId,
  }) : super(key: key);

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
    'Bookings',
    'Notifications',
    'Transactions',
  ];

  @override
  void initState() {
    super.initState();
    fetchMealPlan();
    fetchFamilyMembers();
    fetchPortionSizeData();

    // Add this to check completion after fetching meal plan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkMealPlanCompletion();
    });
  }

  void checkMealPlanCompletion() async {
    if (mealPlanData.isEmpty) return;

    bool allCompleted = true;
    for (var dayMeals in mealPlanData) {
      for (var meal in dayMeals) {
        if (meal['mealplan_id'] != null && meal['is_completed'] != true) {
          allCompleted = false;
          break;
        }
      }
      if (!allCompleted) break;
    }

    print('Checking meal plan completion...');
    print('All meals completed: $allCompleted');

    if (allCompleted && mounted) {
      print('Showing completion dialog');
      MealPlanCompletionHandler.showCompletionDialog(
        context,
        '${widget.firstName} ${widget.lastName}',
        widget.currentUserId,
      );
    }
  }

  String formatDate(String? dateString) {
    try {
      final parsedDate = DateTime.parse(dateString!);
      return DateFormat('MM/dd/yyyy').format(parsedDate);
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Future<void> fetchFamilyMembers() async {
    try {
      // First get the family_head record for this user
      final familyHeadRecord = await Supabase.instance.client
          .from('familymember')
          .select('family_head')
          .eq('user_id', widget.currentUserId)
          .single();

      if (familyHeadRecord == null) return;

      final familyHeadName = familyHeadRecord['family_head'];

      // Then get all family members associated with this specific family head
      final response =
          await Supabase.instance.client.from('familymember').select('''
            first_name, last_name, age, gender,
            familymember_specialconditions(is_pregnant, is_lactating)
          ''').eq('family_head', familyHeadName);

      if (!mounted) return;

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

  Future<void> fetchMealPlan() async {
    try {
      // First get the family_head record for this user
      final familyHeadRecord = await Supabase.instance.client
          .from('familymember')
          .select('family_head')
          .eq('user_id', widget.currentUserId)
          .single();

      if (familyHeadRecord == null) return;

      final familyHeadName = familyHeadRecord['family_head'];

      final response = await Supabase.instance.client
          .from('mealplan')
          .select(
              'mealplan_id, meal_category_id, day, recipe_id, meal_name, is_completed')
          .eq('family_head', familyHeadName)
          .order('day', ascending: true)
          .order('meal_category_id', ascending: true);

      if (!mounted) return;

      // Initialize a 7x4 grid for the week (7 days, 4 categories per day)
      List<List<Map<String, dynamic>>> fetchedMealPlan = List.generate(
        7,
        (_) => List.generate(
          4,
          (categoryId) => {
            'meal_category_id': categoryId + 1,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null,
            'is_completed': false,
          },
        ),
      );

      // Process response and populate the meal plan
      if (response != null) {
        for (var meal in response) {
          int day = (meal['day'] ?? 1) - 1;
          int categoryIndex = (meal['meal_category_id'] ?? 1) - 1;

          if (day >= 0 && day < 7 && categoryIndex >= 0 && categoryIndex < 4) {
            fetchedMealPlan[day][categoryIndex] = {
              'meal_category_id': meal['meal_category_id'],
              'meal_name': meal['meal_name'] ?? 'N/A',
              'recipe_id': meal['recipe_id'] ?? null,
              'mealplan_id': meal['mealplan_id'],
              'is_completed': meal['is_completed'] ?? false,
            };
          }
        }
      }

      setState(() {
        mealPlanData = fetchedMealPlan;
      });

      // Check completion status
      checkMealPlanCompletion();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching meal plan: $e')),
        );
      }
    }
  }

  Future<void> markMealAsCompleted(String mealPlanId) async {
    try {
      final supabase = Supabase.instance.client;

      // First get the family_head record for this user
      final familyHeadRecord = await supabase
          .from('familymember')
          .select('family_head')
          .eq('user_id', widget.currentUserId)
          .single();

      if (familyHeadRecord == null) return;

      final familyHeadName = familyHeadRecord['family_head'];

      // Get the meal details
      final mealDetails = await supabase
          .from('mealplan')
          .select('day, meal_category_id, meal_name')
          .eq('mealplan_id', mealPlanId)
          .single();

      if (mealDetails == null) return;

      // Update in database
      await supabase
          .from('mealplan')
          .update({'is_completed': true})
          .eq('mealplan_id', mealPlanId)
          .eq('family_head', familyHeadName);

      // Get meal type name
      String mealType;
      switch (mealDetails['meal_category_id']) {
        case 1:
          mealType = "Breakfast";
          break;
        case 2:
          mealType = "Lunch";
          break;
        case 3:
          mealType = "Dinner";
          break;
        case 4:
          mealType = "Snacks";
          break;
        default:
          mealType = "Meal";
      }

      // Send notification for meal completion
      await supabase.rpc(
        'create_notification',
        params: {
          'p_recipient_id': widget.currentUserId,
          'p_sender_id': widget.currentUserId,
          'p_title': 'Day ${mealDetails['day']} $mealType Completed',
          'p_message': 'You have completed ${mealDetails['meal_name']}',
          'p_notification_type': 'meal_completion',
          'p_related_id': mealPlanId,
        },
      );

      // Update local state
      setState(() {
        for (var dayMeals in mealPlanData) {
          for (var meal in dayMeals) {
            if (meal['mealplan_id'] == mealPlanId) {
              meal['is_completed'] = true;
            }
          }
        }
      });

      if (mounted) {
        // Show completion message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Meal marked as completed!'),
            duration: Duration(seconds: 2),
          ),
        );

        // Check completion status
        checkMealPlanCompletion();

        // Refresh the page
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => FamHeadDashboard(
              firstName: widget.firstName,
              lastName: widget.lastName,
              currentUserUsername: widget.currentUserUsername,
              currentUserId: widget.currentUserId,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mark meal as completed: $e')),
        );
      }
    }
  }

  Future<void> fetchPortionSizeData() async {
    try {
      final response =
          await Supabase.instance.client.from('PortionSize').select('*');

      final Map<String, Map<String, dynamic>> portionSizeMap = {};

      for (var row in response) {
        final String? ageGroup = row['AgeGroup'] as String?;
        final String? gender = row['Gender'] as String?;

        if (ageGroup != null) {
          if (ageGroup == 'Pregnant') {
            portionSizeMap['Pregnant'] = row as Map<String, dynamic>;
          } else if (ageGroup == 'Lactating') {
            portionSizeMap['Lactating'] = row as Map<String, dynamic>;
          }

          if (gender != null) {
            portionSizeMap['$ageGroup$gender'] = row as Map<String, dynamic>;
          }
        }
      }

      setState(() {
        portionSizeData = portionSizeMap;
      });
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
          onCompleteMeal: markMealAsCompleted,
          userFirstName: widget.firstName,
          userLastName: widget.lastName,
          currentUserId: widget.currentUserId,
        ),
        MyFamilyPage(
          initialFirstName: widget.firstName,
          initialLastName: widget.lastName,
          currentUserId: widget.currentUserId,
        ),
        FamHeadChatPage(
          currentUserId: widget.currentUserId,
        ),
        MyBookingsPage(
          currentUserId: widget.currentUserId,
        ),
        const FamHeadNotificationsPage(),
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
            if (index >= 0 && index < _pageDetails.length) {
              setState(() {
                _selectedIndex = index;
              });
            }
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
