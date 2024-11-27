import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Utility function to construct the full image URL from a relative path
String constructImageUrl(String? imageUrl) {
  if (imageUrl == null || imageUrl.isEmpty) return '';
  if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
    return imageUrl; // Already a complete URL
  }
  const bucketBaseUrl =
      'https://<supabase-url>/storage/v1/object/public/<bucket-name>';
  return '$bucketBaseUrl/$imageUrl';
}

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
        GestureDetector(
          onTap: meal['recipe_id'] != null
              ? () => _showMealDetailsDialog(context, meal)
              : null,
          child: Padding(
            padding: const EdgeInsets.only(
                left: 8.0, right: 24.0, top: 8.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft, // Align the text to the left
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
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

    try {
      final recipeId = meal['recipe_id'];

      // Fetch meal details
      final mealDetailsResponse = await Supabase.instance.client
          .from('meal')
          .select('description, image_url')
          .eq('recipe_id', recipeId)
          .maybeSingle();

      // Construct image URL
      final imageUrl = constructImageUrl(mealDetailsResponse?['image_url']);

      // Fetch ingredients
      final ingredientsResponse = await Supabase.instance.client
          .from('ingredients')
          .select('name, quantity, unit')
          .eq('recipe_id', recipeId);

      // Fetch instructions
      final instructionsResponse = await Supabase.instance.client
          .from('instructions')
          .select('step_number, instruction')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);

      // Process fetched data
      final mealDescription = mealDetailsResponse?['description'];
      final ingredients = (ingredientsResponse as List<dynamic>)
          .map((ingredient) => ingredient as Map<String, dynamic>)
          .toList();
      final instructions = (instructionsResponse as List<dynamic>)
          .map((instruction) => instruction as Map<String, dynamic>)
          .toList();

      // Show Ingredients Dialog
      _showIngredientsDialog(
        context,
        meal['meal_name'],
        imageUrl,
        mealDescription,
        ingredients,
        instructions,
      );
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching meal details: $error')),
      );
    }
  }

  void _showIngredientsDialog(
    BuildContext context,
    String mealName,
    String imageUrl,
    String mealDescription,
    List<Map<String, dynamic>> ingredients,
    List<Map<String, dynamic>> instructions,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 600, // Set dialog width
            height: 400, // Set dialog height
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Center(
                    child: Text(
                      mealName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Ingredients List:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  // Ingredients Table
                  Expanded(
                    child: SingleChildScrollView(
                      child: Table(
                        columnWidths: const {
                          0: IntrinsicColumnWidth(),
                          1: FixedColumnWidth(20), // Add spacing
                          2: IntrinsicColumnWidth(),
                        },
                        defaultVerticalAlignment:
                            TableCellVerticalAlignment.middle,
                        children: ingredients.map((ingredient) {
                          return TableRow(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  '${ingredient['quantity']} ${ingredient['unit']}',
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                              const SizedBox.shrink(), // Spacer column
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4.0),
                                child: Text(
                                  ingredient['name'],
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          // Placeholder for Book Cook action
                        },
                        child: const Text('Book Cook'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showInstructionsDialog(
                            context,
                            mealName,
                            imageUrl,
                            instructions,
                            mealDescription,
                            ingredients,
                          );
                        },
                        child: const Text('Proceed →'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showInstructionsDialog(
      BuildContext context,
      String mealName,
      String imageUrl,
      List<Map<String, dynamic>> instructions,
      String mealDescription,
      List<Map<String, dynamic>> ingredients) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SizedBox(
            width: 600, // Restrict width
            height: 400, // Restrict height
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      mealName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Instructions on the left
                        Expanded(
                          flex: 2,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Procedures:',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                                const SizedBox(height: 8),
                                ...instructions.map((instruction) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
                                    child: Text(
                                      'Step ${instruction['step_number']}: ${instruction['instruction']}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Image on the right
                        Expanded(
                          flex: 1,
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                const Center(
                                    child: Text('Image not available')),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showIngredientsDialog(
                            context,
                            mealName,
                            imageUrl,
                            mealDescription,
                            ingredients,
                            instructions,
                          );
                        },
                        child: const Text('Previous'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Complete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
