import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

// Utility function
String constructImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl;
  }
  const bucketBaseUrl =
      'https://<supabase-url>/storage/v1/object/public/<bucket-name>';
  return '$bucketBaseUrl/$imageUrl';
}

// Main Widget
class MealPlanDashboard extends StatefulWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;
  final List<Map<String, dynamic>> familyMembers;
  final Map<String, dynamic> portionSizeData;
  final String familyHeadName;
  final Function(String mealPlanId)? onCompleteMeal;
  final String userFirstName;
  final String userLastName;

  const MealPlanDashboard({
    super.key,
    required this.mealPlanData,
    required this.familyMembers,
    required this.portionSizeData,
    required this.familyHeadName,
    this.onCompleteMeal,
    required this.userFirstName,
    required this.userLastName,
  });

  @override
  _MealPlanDashboardState createState() => _MealPlanDashboardState();
}

// State Class
class _MealPlanDashboardState extends State<MealPlanDashboard> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  final supabase = Supabase.instance.client;

  late List<List<Map<String, dynamic>>> mealPlanData;
  StreamSubscription<dynamic>? _mealPlanSubscription;

  // Initialization and Cleanup
  @override
  void initState() {
    super.initState();
    mealPlanData = widget.mealPlanData;
    fetchMealPlan();
    _setupMealPlanSubscription();
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _mealPlanSubscription?.cancel();
    super.dispose();
  }

  // Supabase Functions
  Future<void> fetchMealPlan() async {
    try {
      final response = await Supabase.instance.client
          .from('mealplan')
          .select(
              'mealplan_id, meal_category_id, day, recipe_id, meal_name, is_completed')
          .eq('family_head', widget.familyHeadName)
          .order('day', ascending: true)
          .order('meal_category_id', ascending: true);

      List<List<Map<String, dynamic>>> fetchedMealPlan = List.generate(
        7,
        (_) => [
          {
            'meal_category_id': 1,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null,
            'is_completed': false
          },
          {
            'meal_category_id': 2,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null,
            'is_completed': false
          },
          {
            'meal_category_id': 3,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null,
            'is_completed': false
          },
          {
            'meal_category_id': 4, // Adjust for Snacks
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null,
            'is_completed': false
          },
        ],
      );

      for (var meal in response ?? []) {
        try {
          if (meal == null) {
            print('Skipping null meal entry');
            continue;
          }
          int day = (meal['day'] ?? 1) - 1; // Default to day 1 if null
          if (day < 0 || day >= 7) {
            print('Invalid day value: ${meal['day']}');
            continue;
          }

          int categoryIndex = -1;
          switch (meal['meal_category_id']) {
            case 1:
              categoryIndex = 0;
              break;
            case 2:
              categoryIndex = 1;
              break;
            case 3:
              categoryIndex = 2;
              break;
            case 4:
              categoryIndex = 3;
              break;
            default:
              print('Invalid meal_category_id: ${meal['meal_category_id']}');
              continue;
          }

          if (categoryIndex < 0 ||
              categoryIndex >= fetchedMealPlan[day].length) {
            print('Invalid categoryIndex: $categoryIndex for day: $day');
            continue;
          }

          fetchedMealPlan[day][categoryIndex] = {
            'meal_category_id': meal['meal_category_id'],
            'meal_name': meal['meal_name']?.toString() ?? 'N/A',
            'recipe_id': meal['recipe_id']?.toString() ?? '',
            'mealplan_id': meal['mealplan_id']?.toString() ?? '',
            'is_completed': meal['is_completed'] ?? false,
            'day': day + 1,
          };
        } catch (e) {
          print('Error processing meal: $meal, Error: $e');
          continue;
        }
      }

      setState(() {
        mealPlanData = fetchedMealPlan;
      });

      print('Final fetchedMealPlan: $mealPlanData');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meal plan: $e')),
      );
    }
  }

  void _setupMealPlanSubscription() {
    _mealPlanSubscription = Supabase.instance.client
        .from('mealplan')
        .stream(primaryKey: ['mealplan_id'])
        .eq('family_head', widget.familyHeadName)
        .listen((data) {
          for (var meal in data) {
            int day = meal['day'] - 1;
            int categoryIndex = meal['meal_category_id'] - 1;

            if (day >= 0 &&
                day < 7 &&
                categoryIndex >= 0 &&
                categoryIndex < 3) {
              setState(() {
                mealPlanData[day][categoryIndex] = {
                  'meal_category_id': meal['meal_category_id'],
                  'meal_name': meal['meal_name'],
                  'recipe_id': meal['recipe_id'],
                  'mealplan_id': meal['mealplan_id'],
                };
              });
            }
          }
        });
  }

  Future<void> regenerateMeal(int day, int mealCategoryId) async {
    try {
      // Find the meal plan entry for the given day and mealCategoryId
      final existingMeal = mealPlanData[day].firstWhere(
        (meal) => meal['meal_category_id'] == mealCategoryId,
        orElse: () => {"mealplan_id": null, "recipe_id": null},
      );

      final mealPlanId = existingMeal['mealplan_id'];
      final oldRecipeId = existingMeal['recipe_id'];

      if (mealPlanId == null || oldRecipeId == null) {
        throw Exception(
            'Meal plan ID or old recipe ID is missing. MealPlan Data: $existingMeal');
      }

      // Fetch family members to determine allergens and religion
      final familyMembersResponse = await Supabase.instance.client
          .from('familymember')
          .select('familymember_id, religion')
          .eq('family_head', widget.familyHeadName);

      final familyMembers = familyMembersResponse as List<dynamic>;
      final familyMemberIds =
          familyMembers.map((member) => member['familymember_id']).toList();

      // Fetch allergens for family members
      final allergensResponse = await Supabase.instance.client
          .from('familymember_allergens')
          .select('familymember_id, is_dairy, is_nuts, is_seafood');

      final allergens = allergensResponse
          .where((allergen) =>
              familyMemberIds.contains(allergen['familymember_id']))
          .toList();

      // Consolidate allergy information
      final hasAllergy = {
        'is_dairy': allergens.any((a) => a['is_dairy'] == true),
        'is_nuts': allergens.any((a) => a['is_nuts'] == true),
        'is_seafood': allergens.any((a) => a['is_seafood'] == true),
      };

      // Check if anyone in the family is Islamic
      final isHalalRequired =
          familyMembers.any((member) => member['religion'] == 'Islam');

      // Fetch all meals of the same category
      final allMealsResponse = await Supabase.instance.client
          .from('meal')
          .select()
          .eq('meal_category_id', mealCategoryId);

      final allMeals = allMealsResponse as List<dynamic>;

      // Filter meals based on allergens and Halal requirements
      final filteredMeals = allMeals.where((meal) {
        final isExcludedForAllergens = (hasAllergy['is_dairy'] == true &&
                meal['is_dairy'] == true) ||
            (hasAllergy['is_nuts'] == true && meal['is_nuts'] == true) ||
            (hasAllergy['is_seafood'] == true && meal['is_seafood'] == true);

        final isExcludedForHalal = isHalalRequired && meal['is_halal'] != true;

        // Include only meals that are not excluded
        return !isExcludedForAllergens && !isExcludedForHalal;
      }).toList();

      // Filter out meals that are already in the meal plan
      final currentRecipeIds = mealPlanData
          .expand((dayMeals) => dayMeals)
          .map((meal) => meal['recipe_id'])
          .toSet();

      final availableMeals = filteredMeals
          .where((meal) => !currentRecipeIds.contains(meal['recipe_id']))
          .cast<Map<String, dynamic>>()
          .toList();

      if (availableMeals.isEmpty) {
        throw Exception(
            'No available meals left for this category that are not already in the meal plan.');
      }

      // Select a new meal randomly
      availableMeals.shuffle();
      final newMeal = availableMeals.first;

      // Update the meal in the database
      await Supabase.instance.client.from('mealplan').update({
        'recipe_id': newMeal['recipe_id'],
        'meal_name': newMeal['name'],
      }).eq('mealplan_id', mealPlanId);

      // Update the local state to reflect the new meal
      setState(() {
        mealPlanData[day] = mealPlanData[day].map((meal) {
          if (meal['mealplan_id'] == mealPlanId) {
            return {
              ...meal,
              'recipe_id': newMeal['recipe_id'],
              'meal_name': newMeal['name'],
            };
          }
          return meal;
        }).toList();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Meal regenerated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error regenerating meal: $e')),
      );
    }
  }

  Future<String?> fetchUserCity(String familyHeadName) async {
    try {
      final response = await supabase
          .from('familymember')
          .select('city')
          .eq('family_head', familyHeadName)
          .limit(1)
          .maybeSingle();

      return response?['city'] as String?;
    } catch (e) {
      print('Error fetching user city: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCooks(String userCity) async {
    try {
      final response = await supabase.from('Local_Cook').select('''
      localcookid, first_name, last_name, city, phone, availability_days,
      time_available_from, time_available_to, address_line1, barangay
    ''').eq('is_accepted', true).eq('city', userCity);

      return response != null ? List<Map<String, dynamic>>.from(response) : [];
    } catch (e) {
      print('Error fetching cooks: $e');
      return [];
    }
  }

  Future<void> bookCook(
      String cookId, DateTime desiredDeliveryTime, String mealPlanId) async {
    try {
      final familyMemberResponse = await supabase
          .from('familymember')
          .select('familymember_id')
          .eq('first_name', widget.userFirstName)
          .eq('last_name', widget.userLastName)
          .maybeSingle();

      if (familyMemberResponse == null ||
          familyMemberResponse['familymember_id'] == null) {
        throw Exception(
            'Family member not found for name: ${widget.userFirstName} ${widget.userLastName}');
      }

      final familyMemberId = familyMemberResponse['familymember_id'];
      final uuid = const Uuid().v4();

      await supabase.from('bookingrequest').insert({
        'bookingrequest_id': uuid,
        'localcookid': cookId,
        'family_head': widget.familyHeadName,
        'familymember_id': familyMemberId, // Use the retrieved familymember_id
        'mealplan_id': mealPlanId,
        'is_cook_booking': true,
        'request_date': DateTime.now().toIso8601String(),
        'desired_delivery_time': desiredDeliveryTime.toIso8601String(),
        'meal_price': 0.0,
      });

      await showSuccessDialog(
        context,
        'Booking was successful! Your cook has been booked.',
      );
    } catch (e) {
      await showErrorDialog(
        context,
        'Booking failed: ${e.toString()}',
      );
    }
  }

  Future<void> showSuccessDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Success',
            style: TextStyle(color: Colors.green),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> showErrorDialog(BuildContext context, String message) async {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text(
            'Error',
            style: TextStyle(color: Colors.red),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // UI Rendering
  @override
  Widget build(BuildContext context) {
    bool isMealPlanEmpty = mealPlanData.isEmpty ||
        mealPlanData.every(
          (day) =>
              day.isEmpty || day.every((meal) => meal['meal_name'] == null),
        );

    if (isMealPlanEmpty) {
      return const Center(
        child: Text(
          'No meal plan generated yet.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Scrollbar(
        thumbVisibility: true,
        controller: _horizontalScrollController,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          controller: _horizontalScrollController,
          child: Scrollbar(
            thumbVisibility: true,
            controller: _verticalScrollController,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              controller: _verticalScrollController,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16.0),
                child: Table(
                  defaultColumnWidth: const FixedColumnWidth(150),
                  border: TableBorder.all(
                    color: Colors.grey.withOpacity(0.5),
                    width: 1,
                  ),
                  children: [
                    TableRow(
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.3),
                      ),
                      children: [
                        _buildHeader('Day'),
                        _buildHeader('Breakfast'),
                        for (var member in widget.familyMembers)
                          _buildHeader(
                              '${member['first_name']} ${member['last_name']}'),
                        _buildHeader('Lunch'),
                        for (var member in widget.familyMembers)
                          _buildHeader(
                              '${member['first_name']} ${member['last_name']}'),
                        _buildHeader('Dinner'),
                        for (var member in widget.familyMembers)
                          _buildHeader(
                              '${member['first_name']} ${member['last_name']}'),
                        _buildHeader('Snacks'), // Snack header
                      ],
                    ),
                    for (int i = 0; i < mealPlanData.length; i++)
                      _buildTableRow(context, i, mealPlanData[i]),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
      ),
    );
  }

  TableRow _buildTableRow(
      BuildContext context, int dayIndex, List<Map<String, dynamic>> meals) {
    return TableRow(
      decoration: const BoxDecoration(
        color: Colors.white,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            'Day ${dayIndex + 1}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12),
          ),
        ),
        // Breakfast cells
        _buildMealCell(
            context, meals.isNotEmpty ? meals[0] : null, dayIndex, 1),
        for (var member in widget.familyMembers)
          _buildServingCell(member, 1), // Breakfast servings

        // Lunch cells
        _buildMealCell(
            context, meals.length > 1 ? meals[1] : null, dayIndex, 2),
        for (var member in widget.familyMembers)
          _buildServingCell(member, 2), // Lunch servings

        // Dinner cells
        _buildMealCell(
            context, meals.length > 2 ? meals[2] : null, dayIndex, 3),
        for (var member in widget.familyMembers)
          _buildServingCell(member, 3), // Dinner servings

        // Snacks cell
        _buildMealCell(
            context, meals.length > 3 ? meals[3] : null, dayIndex, 4),
        // Only meal cell for Snacks
      ],
    );
  }

  Widget _buildMealCell(BuildContext context, Map<String, dynamic>? meal,
      int dayIndex, int mealCategoryId) {
    if (meal == null || meal['meal_name'] == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'N/A',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    String? mealPlanId =
        meal['mealplan_id']?.toString(); // Ensure it's a string
    bool isCompleted = meal['is_completed'] == true;

    return Stack(
      children: [
        // Full cell container
        Container(
          color: isCompleted ? Colors.green : Colors.transparent,
          padding: const EdgeInsets.all(8.0),
          child: Align(
            alignment: Alignment.topLeft,
            child: Tooltip(
              message: !isCompleted ? 'View Meal Details' : '',
              child: MouseRegion(
                cursor: !isCompleted
                    ? SystemMouseCursors.click
                    : SystemMouseCursors.basic,
                child: GestureDetector(
                  onTap: () {
                    if (meal['recipe_id'] != null) {
                      _showMealDetailsTabsDialog(
                        context: context,
                        meal: meal,
                        familyMemberCount: widget.familyMembers.length,
                        onCompleteMeal: widget.onCompleteMeal,
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No details available for this meal.'),
                        ),
                      );
                    }
                  },
                  child: Text(
                    meal['meal_name'],
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    textAlign: TextAlign.left,
                  ),
                ),
              ),
            ),
          ),
        ),
        // Regenerate and check icons at the bottom-right
        Positioned(
          bottom: 4,
          right: 4,
          child: Row(
            children: [
              if (!isCompleted)
                Tooltip(
                  message: 'Regenerate Meal',
                  child: IconButton(
                    icon: const Icon(Icons.refresh,
                        color: Colors.green, size: 16),
                    onPressed: () => regenerateMeal(dayIndex, mealCategoryId),
                  ),
                ),
              if (isCompleted)
                const Tooltip(
                  message: 'Meal Completed',
                  child:
                      Icon(Icons.check_circle, color: Colors.white, size: 16),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildServingCell(Map<String, dynamic> member, int mealCategoryId) {
    String? portionKey;

    // Prioritize pregnant and lactating
    if (member['is_pregnant'] == true) {
      portionKey = 'Pregnant';
    } else if (member['is_lactating'] == true) {
      portionKey = 'Lactating';
    } else {
      final String? ageGroup = _getAgeGroup(member['age']);
      final String? gender = member['gender'];
      if (ageGroup != null && gender != null) {
        portionKey = '$ageGroup$gender';
      }
    }

    // Retrieve portion size data
    final portion =
        portionKey != null ? widget.portionSizeData[portionKey] : null;

    if (portion == null) {
      return Padding(
        padding: const EdgeInsets.all(12.0),
        child: const Text(
          'N/A',
          style: TextStyle(fontSize: 14),
          textAlign: TextAlign.left,
        ),
      );
    }

    // Filter data based on mealCategoryId
    Map<String, String> filteredPortion = {};
    if (mealCategoryId == 1) {
      filteredPortion = {
        'Water': portion['Water_Breakfast'] ?? 'N/A',
        'Rice': portion['Rice_Breakfast'] ?? 'N/A',
        'Fruits': portion['Fruits_Breakfast'] ?? 'N/A',
        'Vegetables': portion['Vegetables_Breakfast'] ?? 'N/A',
        'Milk': portion['Milk_Breakfast'] ?? 'N/A',
        'Egg': portion['Egg_Breakfast'] ?? 'N/A',
        'Fats': portion['Fats_Breakfast'] ?? 'N/A',
      };
    } else if (mealCategoryId == 2) {
      filteredPortion = {
        'Water': portion['Water_Lunch'] ?? 'N/A',
        'Rice': portion['Rice_Lunch'] ?? 'N/A',
        'Vegetables': portion['Vegetables_Lunch'] ?? 'N/A',
        'Fish/Meat': portion['FishMeat_Lunch'] ?? 'N/A',
        'Sugar': portion['Sugar_Lunch'] ?? 'N/A',
        'Fats': portion['Fats_Lunch'] ?? 'N/A',
      };
    } else if (mealCategoryId == 3) {
      filteredPortion = {
        'Water': portion['Water_Dinner'] ?? 'N/A',
        'Rice': portion['Rice_Dinner'] ?? 'N/A',
        'Vegetables': portion['Vegetables_Dinner'] ?? 'N/A',
        'Fish/Meat': portion['FishMeat_Dinner'] ?? 'N/A',
        'Fats': portion['Fats_Dinner'] ?? 'N/A',
      };
    } else if (mealCategoryId == 4) {
      filteredPortion = {
        'Water': portion['Water_PM_Snack'] ?? 'N/A',
        'Fruits': portion['Fruits_PM_Snack'] ?? 'N/A',
        'Sugar': portion['Sugar_PM_Snack'] ?? 'N/A',
      };
    }

    // Show dialog to display Pie and Pyramid images
    void showPortionDialog() {
      final String? pieUrl = portion['pie'];
      final String? pyramidUrl = portion['pyramid'];

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 600, // Adjust dialog size
              height: 500,
              child: DefaultTabController(
                length: 2,
                child: Column(
                  children: [
                    // Tab Bar
                    const TabBar(
                      labelColor: Colors.green,
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(icon: Icon(Icons.pie_chart), text: 'Pie'),
                        Tab(icon: Icon(Icons.area_chart), text: 'Pyramid'),
                      ],
                    ),
                    // Tab Views
                    Expanded(
                      child: TabBarView(
                        children: [
                          // Pie Image
                          Center(
                            child: pieUrl != null && pieUrl.isNotEmpty
                                ? Image.network(
                                    pieUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder: (context, error,
                                            stackTrace) =>
                                        const Text('Pie Image not available'),
                                  )
                                : const Text('Pie Image not available'),
                          ),
                          // Pyramid Image
                          Center(
                            child: pyramidUrl != null && pyramidUrl.isNotEmpty
                                ? Image.network(
                                    pyramidUrl,
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            const Text(
                                                'Pyramid Image not available'),
                                  )
                                : const Text('Pyramid Image not available'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    // Render serving details with clickable container
    return InkWell(
      onTap: showPortionDialog,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: filteredPortion.entries.map((entry) {
            final RegExp unitPattern = RegExp(r'(.+?)\s*\((.+?)\)');
            final match = unitPattern.firstMatch(entry.value);

            String mainText = entry.value;
            String unitText = '';

            if (match != null) {
              mainText = match.group(1) ?? entry.value;
              unitText = match.group(2) ?? '';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${entry.key}: $mainText',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                ),
                if (unitText.isNotEmpty)
                  Text(
                    '($unitText)',
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<String?> fetchPortionImage(String imageType, String portionKey) async {
    try {
      final response = await supabase
          .from('PortionSize')
          .select(imageType)
          .eq('pyramid', portionKey)
          .maybeSingle();

      return response?[imageType] != null
          ? constructImageUrl(response?[imageType])
          : null;
    } catch (e) {
      print('Error fetching $imageType image: $e');
      return null;
    }
  }

  void _showPortionImageDialog(
      BuildContext context, String? pyramidUrl, String? pieUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 500,
            height: 500,
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    indicatorColor: Colors.green,
                    tabs: [
                      Tab(icon: Icon(Icons.pie_chart), text: 'Pie'),
                      Tab(icon: Icon(Icons.category), text: 'Pyramid'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildImageView(pieUrl, 'Pie Image'),
                        _buildImageView(pyramidUrl, 'Pyramid Image'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageView(String? imageUrl, String placeholder) {
    return Center(
      child: imageUrl != null
          ? Image.network(
              imageUrl,
              errorBuilder: (context, error, stackTrace) =>
                  Text('$placeholder not available'),
            )
          : Text('$placeholder not available'),
    );
  }

  void _showImageDialog(BuildContext context, String? imageUrl) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: imageUrl != null && imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Image not available'),
                )
              : const Text('Image not available'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIngredientsTab(List<Map<String, dynamic>> ingredients,
      int familyMemberCount, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ingredients List
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ingredients List:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...ingredients.map((ingredient) {
                    final adjustedQuantity = _adjustQuantity(
                        ingredient['quantity'], familyMemberCount);
                    final unit = ingredient['unit'] ?? '';
                    final name = ingredient['name'] ?? 'Unknown Ingredient';

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        '$adjustedQuantity $unit $name',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Image
          Expanded(
            flex: 1,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Image not available'),
                  )
                : const Text('No Image Available'),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionsTab(
      List<Map<String, dynamic>> instructions, String imageUrl) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Instructions List
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cooking Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ...instructions.map((instruction) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        'Step ${instruction['step_number']}: ${instruction['instruction']}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          // Image
          Expanded(
            flex: 1,
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Text('Image not available'),
                  )
                : const Text('No Image Available'),
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalsTab(String mealDescription, String imageUrl) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'Additional Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            mealDescription,
            style: const TextStyle(fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          imageUrl.isNotEmpty
              ? Image.network(
                  imageUrl,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Text('Image not available'),
                )
              : const Text('No Image Available'),
        ],
      ),
    );
  }

  void _showCookBookingDialog(BuildContext context, String mealPlanId) async {
    String? userCity = await fetchUserCity(widget.familyHeadName);

    if (userCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User city not found.')),
      );
      return;
    }

    List<Map<String, dynamic>> cooks = await fetchCooks(userCity);

    if (cooks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No cooks available in your city.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 500,
            height: 500,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text(
                    'Available cooks near you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: cooks.length,
                      itemBuilder: (context, index) {
                        final cook = cooks[index];
                        final firstName = cook['first_name'] ?? 'N/A';
                        final lastName = cook['last_name'] ?? 'N/A';
                        final city = cook['city'] ?? 'N/A';

                        // Define formattedAddress
                        final addressLine1 =
                            cook['address_line1']?.toString().trim();
                        final barangay = cook['barangay']?.toString().trim();
                        final formattedAddress =
                            (addressLine1 != null && addressLine1.isNotEmpty)
                                ? (barangay != null && barangay.isNotEmpty
                                    ? '$addressLine1, $barangay'
                                    : addressLine1)
                                : 'No address provided';

                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundColor: Colors.green,
                              child: Text(
                                firstName.isNotEmpty
                                    ? firstName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              '$firstName $lastName',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'City: $city\n'
                              'Address: $formattedAddress\n'
                              'Availability: ${cook['availability_days'] ?? 'N/A'} '
                              '(${cook['time_available_from'] ?? 'N/A'} - ${cook['time_available_to'] ?? 'N/A'})',
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _showCookDetailsDialog(
                                context, cook, mealPlanId),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showCookDetailsDialog(
      BuildContext context, Map<String, dynamic> cook, String mealPlanId) {
    DateTime? selectedDateTime;

    final firstName = cook['first_name'] ?? 'N/A';
    final lastName = cook['last_name'] ?? 'N/A';
    final city = cook['city'] ?? 'N/A';
    final phone = cook['phone'] ?? 'N/A';
    final addressLine1 = cook['address_line1']?.toString().trim();
    final barangay = cook['barangay']?.toString().trim();

    final formattedAddress = (addressLine1 != null && addressLine1.isNotEmpty)
        ? (barangay != null && barangay.isNotEmpty
            ? '$addressLine1, $barangay'
            : addressLine1)
        : 'No address provided';

    final availabilityDaysStr =
        cook['availability_days'] ?? 'N/A'; // e.g. "Monday,Wednesday,Friday"
    final timeFromStr = cook['time_available_from'] ?? '8:00 AM';
    final timeToStr = cook['time_available_to'] ?? '8:00 PM';
    final rating = cook['rating'] ?? 4; // Placeholder rating

    // Convert availability days to a set of weekday names
    final availabilityDays =
        availabilityDaysStr.split(',').map((d) => d.trim()).toSet();

    // Function to check if selectedDateTime is within availability
    bool isWithinAvailability(DateTime dateTime) {
      // Check day
      final dayName = DateFormat('EEEE').format(dateTime); // e.g. "Monday"
      if (!availabilityDays.contains(dayName)) {
        return false;
      }

      // Parse times
      final timeFormatter = DateFormat('h:mm a');
      final parsedFrom = timeFormatter.parse(timeFromStr);
      final parsedTo = timeFormatter.parse(timeToStr);

      // Combine parsed times with the selected date
      final fromTime = DateTime(dateTime.year, dateTime.month, dateTime.day,
          parsedFrom.hour, parsedFrom.minute);
      final toTime = DateTime(dateTime.year, dateTime.month, dateTime.day,
          parsedTo.hour, parsedTo.minute);

      // Check time range
      return dateTime.isAfter(fromTime) && dateTime.isBefore(toTime) ||
          dateTime.isAtSameMomentAs(fromTime) ||
          dateTime.isAtSameMomentAs(toTime);
    }

    bool isTimeValid = false;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: StatefulBuilder(
            builder: (context, setState) {
              void pickDateTime() async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (time != null) {
                    final combinedDateTime = DateTime(
                      date.year,
                      date.month,
                      date.day,
                      time.hour,
                      time.minute,
                    );
                    final valid = isWithinAvailability(combinedDateTime);
                    setState(() {
                      selectedDateTime = combinedDateTime;
                      isTimeValid = valid;
                    });
                    if (!valid) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'Selected time is not within cook\'s availability.')),
                      );
                    }
                  }
                }
              }

              return SizedBox(
                width: 500,
                height: 500,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.green,
                            child: Text(
                              firstName.isNotEmpty
                                  ? firstName[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                fontSize: 24,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DefaultTextStyle(
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black),
                                      children: [
                                        const TextSpan(
                                            text: 'Phone: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(text: phone),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black),
                                      children: [
                                        const TextSpan(
                                            text: 'City: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(text: city),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black),
                                      children: [
                                        const TextSpan(
                                          text: 'Address: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(text: formattedAddress),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black),
                                      children: [
                                        const TextSpan(
                                            text: 'Availability Days: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(text: availabilityDaysStr),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: const TextStyle(
                                          fontSize: 14, color: Colors.black),
                                      children: [
                                        const TextSpan(
                                            text: 'Time: ',
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold)),
                                        TextSpan(
                                            text: '$timeFromStr - $timeToStr'),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      const Text('Rating: ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      for (int i = 1; i <= 5; i++)
                                        Icon(
                                          Icons.star,
                                          size: 20,
                                          color: i <= rating
                                              ? Colors.orangeAccent
                                              : Colors.grey,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  GestureDetector(
                                    onTap: pickDateTime,
                                    child: Text(
                                      selectedDateTime == null
                                          ? 'Select Delivery Date and Time'
                                          : 'Selected: ${DateFormat('MM-dd-yyyy – HH:mm').format(selectedDateTime!)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.blue,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          ElevatedButton(
                            onPressed: (selectedDateTime != null && isTimeValid)
                                ? () {
                                    Navigator.pop(context); // Close dialog
                                    bookCook(cook['localcookid'],
                                        selectedDateTime!, mealPlanId);
                                  }
                                : null,
                            child: const Text('Book'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showMealDetailsTabsDialog({
    required BuildContext context,
    required Map<String, dynamic> meal,
    required int familyMemberCount,
    required void Function(String mealPlanId)? onCompleteMeal,
  }) async {
    try {
      final recipeId = meal['recipe_id'];
      if (recipeId == null) return;

      // Fetch meal details
      final mealDetailsResponse = await supabase
          .from('meal')
          .select('description, image_url')
          .eq('recipe_id', recipeId)
          .maybeSingle();

      final ingredientsResponse = await supabase
          .from('ingredients')
          .select('name, quantity, unit')
          .eq('recipe_id', recipeId);

      final instructionsResponse = await supabase
          .from('instructions')
          .select('step_number, instruction')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);

      // Extract data
      final mealName = meal['meal_name'].toString();
      final mealDescription =
          mealDetailsResponse?['description'] ?? 'No description available';
      final imageUrl = constructImageUrl(mealDetailsResponse?['image_url']);
      final ingredients = List<Map<String, dynamic>>.from(ingredientsResponse);
      final instructions =
          List<Map<String, dynamic>>.from(instructionsResponse);

      // Show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 500, // Fixed size
              height: 500,
              child: DefaultTabController(
                length: 3, // Three tabs
                child: Column(
                  children: [
                    // Meal Title
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        mealName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    // TabBar
                    const TabBar(
                      indicatorColor: Colors.green,
                      tabs: [
                        Tab(icon: Icon(Icons.list), text: 'Ingredients'),
                        Tab(icon: Icon(Icons.receipt), text: 'Instructions'),
                        Tab(icon: Icon(Icons.add_circle), text: 'Additionals'),
                      ],
                    ),
                    // TabBarView
                    Expanded(
                      child: TabBarView(
                        children: [
                          _buildIngredientsTab(
                              ingredients, familyMemberCount, imageUrl),
                          _buildInstructionsTab(instructions, imageUrl),
                          _buildAdditionalsTab(mealDescription, imageUrl),
                        ],
                      ),
                    ),
                    // Buttons Row
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          ElevatedButton(
                            onPressed: () => _showCookBookingDialog(
                                context, meal['mealplan_id']),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Book Cook'),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              if (onCompleteMeal != null) {
                                onCompleteMeal(meal['mealplan_id']);
                              }
                              Navigator.of(context).pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                              foregroundColor: Colors.black,
                            ),
                            child: const Text('Complete'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading meal details: $error')),
      );
    }
  }

  // Helper function to adjust the quantity
  dynamic _adjustQuantity(dynamic quantity, int familyMemberCount) {
    if (quantity is num) {
      // For numeric values, multiply by familyMemberCount
      return (quantity * familyMemberCount).toStringAsFixed(0);
    } else if (quantity is String) {
      // Handle string quantities (e.g., "50 grams")
      final match = RegExp(r'^(\d+(\.\d+)?)\s*(\w+)?$').firstMatch(quantity);
      if (match != null) {
        final value = double.tryParse(match.group(1) ?? '0') ?? 0;
        final unit = match.group(3) ?? '';
        final adjustedValue = (value * familyMemberCount).toStringAsFixed(0);
        return '$adjustedValue $unit';
      } else if (quantity.contains('/')) {
        // Handle fractional quantities (e.g., "1/4 cup")
        final parts = quantity.split('/').map(int.tryParse).toList();
        if (parts.length == 2 && parts[0] != null && parts[1] != null) {
          // Calculate the fractional value and scale it
          final fractionValue = parts[0]! / parts[1]!;
          final adjustedFraction = fractionValue * familyMemberCount;

          // Split into whole number and remaining fraction
          final wholeNumber = adjustedFraction.floor();
          final remainingFraction = adjustedFraction - wholeNumber;

          if (remainingFraction == 0) {
            return wholeNumber.toString(); // No fraction remains
          } else {
            // Reduce the fraction
            final gcd = _greatestCommonDivisor(
              (remainingFraction * parts[1]!).round(),
              parts[1]!,
            );
            final numerator = (remainingFraction * parts[1]!).round() ~/ gcd;
            final denominator = parts[1]! ~/ gcd;

            if (wholeNumber > 0) {
              return '$wholeNumber $numerator/$denominator';
            } else {
              return '$numerator/$denominator';
            }
          }
        }
      }
    }

    // Return the original quantity if it can't be adjusted
    return quantity;
  }

  // Helper function to calculate the greatest common divisor
  int _greatestCommonDivisor(int a, int b) {
    return b == 0 ? a.abs() : _greatestCommonDivisor(b, a % b);
  }

  // Helper function to determine age group based on age
  String? _getAgeGroup(int? age) {
    if (age == null) return null;

    if (age >= 1 && age <= 6) return 'Toddler 1-6 years old';
    if (age >= 7 && age <= 12) return 'Kids 7-12 years old';
    if (age >= 13 && age <= 19) return 'Teen 13-19 years old';
    if (age >= 20 && age <= 59) return 'Adults 20-59 years old';
    if (age >= 60 && age <= 69) return 'Elderly 60-69 years old';
    return null;
  }

  String normalizeGender(String gender) {
    return gender[0].toUpperCase() + gender.substring(1).toLowerCase();
  }
}
