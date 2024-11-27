import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealPlanDashboard extends StatefulWidget {
  List<List<Map<String, dynamic>>> mealPlanData;
  final List<Map<String, dynamic>> familyMembers;
  final Map<String, dynamic> portionSizeData;
  final String familyHeadName;

  MealPlanDashboard({
    super.key,
    required this.mealPlanData,
    required this.familyMembers,
    required this.portionSizeData,
    required this.familyHeadName,
  });

  @override
  _MealPlanDashboardState createState() => _MealPlanDashboardState();
}

class _MealPlanDashboardState extends State<MealPlanDashboard> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();
  late List<List<Map<String, dynamic>>> mealPlanData;
  StreamSubscription<dynamic>? _mealPlanSubscription;

  @override
  void initState() {
    super.initState();
    mealPlanData = widget.mealPlanData;
    fetchMealPlan(); // Initial fetch
    _setupMealPlanSubscription(); // Real-time updates
  }

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    _mealPlanSubscription?.cancel();
    super.dispose();
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

  void _processMealPlanData(List<dynamic> data) {
    List<List<Map<String, dynamic>>> updatedMealPlan =
        List.generate(7, (_) => []);

    for (var meal in data) {
      int day = meal['day'] - 1;
      if (day >= 0 && day < 7) {
        updatedMealPlan[day].add({
          'meal_category_id': meal['meal_category_id'],
          'meal_name': meal['meal_name'],
          'recipe_id': meal['recipe_id'],
          'mealplan_id': meal['mealplan_id'],
        });
      }
    }

    setState(() {
      mealPlanData = updatedMealPlan;
    });
  }

  Future<void> fetchMealPlan() async {
    try {
      // Fetch meal plans ordered by `day` and `meal_category_id`
      final response = await Supabase.instance.client
          .from('mealplan')
          .select()
          .eq('family_head', widget.familyHeadName)
          .order('day', ascending: true)
          .order('meal_category_id', ascending: true); // Ensure category order

      // Initialize the fetched meal plan structure for 7 days
      List<List<Map<String, dynamic>>> fetchedMealPlan = List.generate(
        7,
        (_) => [
          {
            'meal_category_id': 1,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null
          },
          {
            'meal_category_id': 2,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null
          },
          {
            'meal_category_id': 3,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null
          },
        ],
      );

      // Map response to appropriate day and category
      for (var meal in response) {
        int day =
            (meal['day'] ?? 1) - 1; // Days start from 1; map to 0-based index
        int categoryIndex =
            (meal['meal_category_id'] ?? 1) - 1; // Categories start from 1

        // Ensure valid range
        if (day >= 0 && day < 7 && categoryIndex >= 0 && categoryIndex < 3) {
          fetchedMealPlan[day][categoryIndex] = {
            'meal_category_id': meal['meal_category_id'],
            'meal_name': meal['meal_name'],
            'recipe_id': meal['recipe_id'],
            'mealplan_id': meal['mealplan_id'],
          };
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

  Future<void> regenerateMeal(int day, int mealCategoryId) async {
    try {
      // Find the specific meal for the given day and meal category
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

      // Fetch all meals in the same category that are not already in the current meal plan
      final allMealsResponse = await Supabase.instance.client
          .from('meal')
          .select()
          .eq('meal_category_id', mealCategoryId);

      final allMeals = allMealsResponse as List<dynamic>;

      // Get all recipe IDs currently in the meal plan
      final currentRecipeIds = mealPlanData
          .expand((dayMeals) => dayMeals)
          .map((meal) => meal['recipe_id'])
          .toSet();

      // Filter out meals that are already in the meal plan
      List<Map<String, dynamic>> availableMeals = allMeals
          .where((meal) => !currentRecipeIds.contains(meal['recipe_id']))
          .cast<Map<String, dynamic>>()
          .toList();

      if (availableMeals.isEmpty) {
        throw Exception(
            'No available meals left for this category that are not already in the meal plan.');
      }

      // Shuffle and select a new meal
      availableMeals.shuffle();
      final newMeal = availableMeals.first;

      // Update the specific meal in the database
      await Supabase.instance.client.from('mealplan').update({
        'recipe_id': newMeal['recipe_id'],
        'meal_name': newMeal['name'],
      }).eq('mealplan_id', mealPlanId);

      // Update the local state for this specific cell only
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
        SnackBar(content: Text('Meal regenerated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error regenerating meal: $e')),
      );
    }
  }

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
      decoration: BoxDecoration(
        color: dayIndex % 2 == 0 ? Colors.white : Colors.green.withOpacity(0.3),
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
        _buildMealCell(context, meals.isNotEmpty ? meals[0] : null, dayIndex,
            1), // 1 for Breakfast
        for (var member in widget.familyMembers) _buildServingCell(member),
        _buildMealCell(context, meals.length > 1 ? meals[1] : null, dayIndex,
            2), // 2 for Lunch
        for (var member in widget.familyMembers) _buildServingCell(member),
        _buildMealCell(context, meals.length > 2 ? meals[2] : null, dayIndex,
            3), // 3 for Dinner
        for (var member in widget.familyMembers) _buildServingCell(member),
      ],
    );
  }

  Widget _buildMealCell(BuildContext context, Map<String, dynamic>? meal,
      int day, int mealCategoryId) {
    if (meal == null || meal['meal_name'] == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'N/A',
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.only(
              left: 8.0, right: 24.0, top: 8.0, bottom: 8.0),
          child: Align(
            alignment: Alignment.centerLeft, // Align the text to the left
            child: Text(
              meal['meal_name'],
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 4, // Place the regenerate icon at the bottom
          right: 4, // Align it to the right
          child: Tooltip(
            message: 'Regenerate Meal',
            child: IconButton(
              icon: const Icon(Icons.refresh, size: 16, color: Colors.green),
              onPressed: () => regenerateMeal(day, mealCategoryId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildServingCell(Map<String, dynamic> member) {
    final ageGroup = getAgeGroup(member['age']);
    final gender = normalizeGender(member['gender']);
    final key = '${ageGroup}_${gender}';
    final portion = widget.portionSizeData[key];

    if (portion == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'N/A',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Rice: ${portion['Rice_breakfast']}',
              style: const TextStyle(fontSize: 12)),
          Text('Protein: ${portion['Proteins_per_meal']}',
              style: const TextStyle(fontSize: 12)),
          Text('Fruits and Vegetables: ${portion['FruitsVegetables_per_meal']}',
              style: const TextStyle(fontSize: 12)),
          Text('Water: ${portion['Water_per_meal']}',
              style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  String getAgeGroup(int age) {
    if (age >= 1 && age <= 6) return 'Toddler 1-6 years old';
    if (age >= 7 && age <= 12) return 'Kids 7-12 years old';
    if (age >= 13 && age <= 19) return 'Teen 13-19 years old';
    if (age >= 20 && age <= 59) return 'Adults 20-59 years old';
    if (age >= 60) return 'Elderly 60-69 years old';
    return 'Unknown';
  }

  String normalizeGender(String gender) {
    return gender[0].toUpperCase() + gender.substring(1).toLowerCase();
  }

  Future<Map<String, dynamic>> fetchMealDetails(int recipeId) async {
    try {
      final response = await Supabase.instance.client
          .from('meal')
          .select('description, image_url, link, calories, preparation_time')
          .eq('recipe_id', recipeId)
          .maybeSingle();

      if (response == null) {
        return {
          'description': 'No description available.',
          'image_url': null,
          'link': 'No link available.',
          'calories': 'N/A',
          'preparation_time': 'N/A',
        };
      }

      return {
        'description': response['description'] ?? 'No description available.',
        'image_url': response['image_url'],
        'link': response['link'] ?? 'No link available.',
        'calories': response['calories'] ?? 'N/A',
        'preparation_time': response['preparation_time'] ?? 'N/A',
      };
    } catch (error) {
      return {
        'description': 'Error fetching description.',
        'image_url': null,
        'link': 'Error fetching link.',
        'calories': 'Error fetching data.',
        'preparation_time': 'Error fetching data.',
      };
    }
  }

  void _showMealDetailsDialog(
      BuildContext context, Map<String, dynamic> meal) async {
    if (meal['recipe_id'] == null) return;

    final mealDetails = await fetchMealDetails(meal['recipe_id']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(meal['meal_name'] ?? 'Meal Details'),
          content: SizedBox(
            width: 500,
            height: 500,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (mealDetails['image_url'] != null)
                    Image.network(mealDetails['image_url'], fit: BoxFit.cover),
                  const SizedBox(height: 10),
                  Text(
                    'Description:\n${mealDetails['description']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Calories: ${mealDetails['calories']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Preparation Time: ${mealDetails['preparation_time']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () {
                      if (mealDetails['link'] != 'No link available.') {
                        // Logic to open the link
                      }
                    },
                    child: Text(
                      mealDetails['link'],
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
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
}
