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

  MealPlanDashboard({
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
            'meal_category_id': 5,
            'meal_name': null,
            'recipe_id': null,
            'mealplan_id': null,
            'is_completed': false
          },
        ],
      );

      for (var meal in response) {
        int day = (meal['day'] ?? 1) - 1; // Ensure day is int
        String mealPlanId =
            meal['mealplan_id'].toString(); // Ensure mealplan_id is String

        int categoryIndex;
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
          case 5:
            categoryIndex = 3;
            break;
          default:
            continue;
        }

        if (day >= 0 && day < 7 && categoryIndex >= 0 && categoryIndex < 4) {
          fetchedMealPlan[day][categoryIndex] = {
            ...meal,
            'mealplan_id': mealPlanId, // Convert mealplan_id to String
            'day': day + 1 // Ensure day is a proper value
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
        SnackBar(content: Text('Meal regenerated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error regenerating meal: $e')),
      );
    }
  }

  Future<String?> fetchUserCity(String firstName, String lastName) async {
    try {
      final response = await supabase
          .from('familymember')
          .select('city')
          .eq('first_name', firstName)
          .eq('last_name', lastName)
          .maybeSingle();

      return response != null ? response['city'] as String : null;
    } catch (e) {
      print('Error fetching user city: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> fetchCooks(String userCity) async {
    try {
      final response = await supabase
          .from('Local_Cook')
          .select(
            '''
          localcookid, first_name, last_name, age, gender, dateofbirth, phone,
          address_line1, barangay, city, province, postal_code,
          availability_days, time_available_from, time_available_to,
          certifications
          ''',
          )
          .eq('is_accepted', true)
          .eq('city', userCity);

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
        'familymember_id': familyMemberId,
        'mealplan_id': mealPlanId, // Include mealPlanId
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
            context, meals.length > 3 ? meals[3] : null, dayIndex, 5),
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

    bool isCompleted = meal['is_completed'] == true;
    String? mealPlanId = meal['mealplan_id']; // Extract `mealPlanId`

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
                    if (!isCompleted && mealPlanId != null) {
                      _showCookBookingDialog(
                          context, mealPlanId); // Pass `mealPlanId`
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
                Tooltip(
                  message: 'Meal Completed',
                  child: const Icon(Icons.check_circle,
                      color: Colors.white, size: 16),
                ),
            ],
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

  // Dialog Functions
  void _showCookBookingDialog(BuildContext context, String mealPlanId) async {
    String? userCity =
        await fetchUserCity(widget.userFirstName, widget.userLastName);

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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            height: 500,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Available cooks near you',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: cooks.length,
                    itemBuilder: (context, index) {
                      final cook = cooks[index];
                      return ListTile(
                        title:
                            Text('${cook['first_name']} ${cook['last_name']}'),
                        subtitle: Text('City: ${cook['city']}'),
                        onTap: () =>
                            _showCookDetailsDialog(context, cook, mealPlanId),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCookDetailsDialog(
      BuildContext context, Map<String, dynamic> cook, String mealPlanId) {
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${cook['first_name']} ${cook['last_name']}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Phone: ${cook['phone']}'),
                  Text('City: ${cook['city']}'),
                  Text('Available From: ${cook['time_available_from']}'),
                  Text('Available To: ${cook['time_available_to']}'),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () async {
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
                          setState(() {
                            selectedDateTime = combinedDateTime;
                          });
                        }
                      }
                    },
                    child: Text(
                      selectedDateTime == null
                          ? 'Select Delivery Date and Time'
                          : 'Selected: ${DateFormat('MM-dd-yyyy – HH:mm').format(selectedDateTime!)}',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (selectedDateTime != null) {
                      Navigator.pop(context); // Close dialog
                      bookCook(
                          cook['localcookid'], selectedDateTime!, mealPlanId);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Select a delivery time.')),
                      );
                    }
                  },
                  child: const Text('Book'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showMealDetailsDialog({
    required BuildContext context,
    required Map<String, dynamic> meal,
    required int familyMemberCount,
    required void Function(String mealPlanId)? onCompleteMeal,
  }) async {
    if (meal['recipe_id'] == null) return;

    try {
      final recipeId = meal['recipe_id'];

      // Fetch meal details
      final mealDetailsResponse = await Supabase.instance.client
          .from('meal')
          .select('description, image_url')
          .eq('recipe_id', recipeId)
          .maybeSingle();

      final imageUrl =
          constructImageUrl(mealDetailsResponse?['image_url'] ?? '');

      final ingredientsResponse = await Supabase.instance.client
          .from('ingredients')
          .select('name, quantity, unit')
          .eq('recipe_id', recipeId);

      final instructionsResponse = await Supabase.instance.client
          .from('instructions')
          .select('step_number, instruction')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);

      // Process fetched data and handle types
      final mealDescription =
          (mealDetailsResponse?['description'] ?? 'No description available')
              .toString();
      final ingredients = (ingredientsResponse as List<dynamic>)
          .map((ingredient) => ingredient as Map<String, dynamic>)
          .toList();
      final instructions = (instructionsResponse as List<dynamic>)
          .map((instruction) => instruction as Map<String, dynamic>)
          .toList();

      _showIngredientsDialog(
        context: context,
        mealName: meal['meal_name'].toString(),
        mealDescription: mealDescription,
        ingredients: ingredients,
        instructions: instructions,
        familyMemberCount: familyMemberCount,
        imageUrl: imageUrl,
        mealPlanId: meal['mealplan_id'].toString(), // Ensure it's a string
        onCompleteMeal: onCompleteMeal,
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
    required List<Map<String, dynamic>> instructions,
    required int familyMemberCount,
    required String imageUrl,
    required String mealPlanId,
    required void Function(String mealPlanId)? onCompleteMeal,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                      ingredient['quantity'],
                                      familyMemberCount);
                                  final unit = ingredient['unit'] ?? '';
                                  final name = ingredient['name'] ??
                                      'Unknown Ingredient';

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4.0),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          // Pass the mealPlanId to _showCookBookingDialog
                          _showCookBookingDialog(context, mealPlanId);
                        },
                        child: const Text('Book Cook'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showInstructionsDialog(
                            context: context,
                            mealName: mealName,
                            mealDescription: mealDescription,
                            instructions: instructions,
                            imageUrl: imageUrl,
                            mealPlanId: mealPlanId,
                            onCompleteMeal: onCompleteMeal,
                            familyMemberCount: familyMemberCount,
                            ingredients: ingredients, // Pass ingredients here
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

  void _showInstructionsDialog({
    required BuildContext context,
    required String mealName,
    required String mealDescription,
    required List<Map<String, dynamic>> instructions,
    required String imageUrl,
    required String mealPlanId,
    required void Function(String mealPlanId)? onCompleteMeal,
    required int familyMemberCount,
    required List<Map<String, dynamic>> ingredients, // Add this parameter
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 4.0,
                                    ),
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
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showIngredientsDialog(
                            context: context,
                            mealName: mealName,
                            mealDescription: mealDescription,
                            ingredients:
                                ingredients, // Pass the ingredients back
                            instructions: instructions,
                            imageUrl: imageUrl,
                            familyMemberCount: familyMemberCount,
                            mealPlanId: mealPlanId,
                            onCompleteMeal: onCompleteMeal,
                          );
                        },
                        child: const Text('Previous'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          if (onCompleteMeal != null) {
                            onCompleteMeal(mealPlanId);
                          }
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
