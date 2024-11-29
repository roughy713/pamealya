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

  Future<void> fetchMealPlan() async {
    try {
      final response = await Supabase.instance.client
          .from('mealplan')
          .select()
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

      for (var meal in response) {
        int day = (meal['day'] ?? 1) - 1;
        int categoryIndex = (meal['meal_category_id'] ?? 1) - 1;

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
        // Breakfast meal cell
        _buildMealCell(
          context,
          meals.isNotEmpty ? meals[0] : null,
          dayIndex,
          1, // Meal category ID for Breakfast
        ),
        for (var member in widget.familyMembers)
          _buildServingCell(
            member,
            1, // Meal category ID for Breakfast
          ),
        // Lunch meal cell
        _buildMealCell(
          context,
          meals.length > 1 ? meals[1] : null,
          dayIndex,
          2, // Meal category ID for Lunch
        ),
        for (var member in widget.familyMembers)
          _buildServingCell(
            member,
            2, // Meal category ID for Lunch
          ),
        // Dinner meal cell
        _buildMealCell(
          context,
          meals.length > 2 ? meals[2] : null,
          dayIndex,
          3, // Meal category ID for Dinner
        ),
        for (var member in widget.familyMembers)
          _buildServingCell(
            member,
            3, // Meal category ID for Dinner
          ),
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
              ? () => _showMealDetailsDialog(
                    context,
                    meal,
                    widget.familyMembers.length, // Use widget.familyMembers
                  )
              : null,
          child: Padding(
            padding: const EdgeInsets.only(
                left: 8.0, right: 24.0, top: 8.0, bottom: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
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

  Widget _buildServingCell(Map<String, dynamic> member, int mealCategoryId) {
    String? portionKey;

    // Check for special conditions first
    if (member['is_pregnant'] == true) {
      portionKey = 'Pregnant';
    } else if (member['is_lactating'] == true) {
      portionKey = 'Lactating';
    } else {
      // Construct key for non-special conditions
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
        padding: const EdgeInsets.all(8.0),
        child: Text('N/A', textAlign: TextAlign.center),
      );
    }

    // Determine rice type based on meal category
    String riceType = '';
    if (mealCategoryId == 1) {
      riceType = portion['Rice_breakfast'];
    } else if (mealCategoryId == 2) {
      riceType = portion['Rice_lunch'];
    } else if (mealCategoryId == 3) {
      riceType = portion['Rice_dinner'];
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Rice: $riceType\n'
        'Protein: ${portion['Proteins_per_meal']}\n'
        'Fruits: ${portion['FruitsVegetables_per_meal']}\n'
        'Water: ${portion['Water_per_meal']}',
        textAlign: TextAlign.center,
      ),
    );
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
  BuildContext context,
  Map<String, dynamic> meal,
  int familyMemberCount,
) async {
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
    final imageUrl = constructImageUrl(mealDetailsResponse?['image_url'] ?? '');

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
    final mealDescription =
        mealDetailsResponse?['description'] ?? 'No description available';
    final ingredients = (ingredientsResponse as List<dynamic>)
        .map((ingredient) => ingredient as Map<String, dynamic>)
        .toList();
    final instructions = (instructionsResponse as List<dynamic>)
        .map((instruction) => instruction as Map<String, dynamic>)
        .toList();

    // Show Ingredients Dialog
    _showIngredientsDialog(
      context: context,
      mealName: meal['meal_name'],
      mealDescription: mealDescription,
      ingredients: ingredients,
      instructions: instructions,
      familyMemberCount: familyMemberCount, // Pass family member count
      imageUrl: imageUrl, // Pass image URL
    );
  } catch (error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error fetching meal details: $error')),
    );
  }
}

void _showIngredientsDialog({
  required BuildContext context,
  required String mealName,
  required String mealDescription,
  required List<Map<String, dynamic>> ingredients,
  required List<Map<String, dynamic>> instructions, // Needed for "Proceed"
  required int familyMemberCount,
  required String imageUrl, // Pass to display in dialog
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 600,
          height: 400,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Meal name header
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
                      // Ingredients list on the left
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Ingredients List:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...ingredients.map((ingredient) {
                                final adjustedQuantity = _adjustQuantity(
                                    ingredient['quantity'], familyMemberCount);
                                final unit = ingredient['unit'] ?? '';
                                final name =
                                    ingredient['name'] ?? 'Unknown Ingredient';

                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Text(
                                    '$adjustedQuantity $unit $name',
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
                              const Center(child: Text('Image not available')),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        // Placeholder for booking action
                      },
                      child: const Text('Book Cook'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showInstructionsDialog(
                          context: context,
                          mealName: mealName,
                          mealDescription: mealDescription,
                          instructions: instructions, // Pass instructions
                          imageUrl: imageUrl, // Pass image URL
                          ingredients: ingredients, // Pass ingredients back
                          familyMemberCount: familyMemberCount, // Pass count
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
            return '$wholeNumber ${numerator}/${denominator}';
          } else {
            return '${numerator}/${denominator}';
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

void _showInstructionsDialog({
  required BuildContext context,
  required String mealName,
  required String mealDescription,
  required List<Map<String, dynamic>> instructions,
  required String imageUrl, // Image URL
  required List<Map<String, dynamic>> ingredients, // Added for navigating back
  required int familyMemberCount, // Added for navigating back
}) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 600,
          height: 400,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                      // Instructions list on the left
                      Expanded(
                        flex: 2,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Instructions:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 8),
                              ...instructions.map((instruction) {
                                return Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
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
                              const Center(child: Text('Image not available')),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _showIngredientsDialog(
                          context: context,
                          mealName: mealName,
                          mealDescription: mealDescription,
                          ingredients: ingredients, // Pass ingredients
                          instructions: instructions, // Pass instructions
                          familyMemberCount: familyMemberCount, // Pass count
                          imageUrl: imageUrl, // Pass image URL
                        );
                      },
                      child: const Text('Previous'),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow,
                        foregroundColor: Colors.black,
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
