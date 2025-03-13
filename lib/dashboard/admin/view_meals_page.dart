import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewMealsPage extends StatefulWidget {
  const ViewMealsPage({super.key});

  @override
  _ViewMealsPageState createState() => _ViewMealsPageState();
}

class _ViewMealsPageState extends State<ViewMealsPage> {
  List<dynamic> meals = [];
  bool isLoading = true;
  bool hasError = false;
  String searchQuery = '';
  String? filterCategory;
  List<Map<String, dynamic>> categories = [];

  // Controllers for edit dialog
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  bool isNuts = false;
  bool isHalal = false;
  bool isDairy = false;
  bool isSeafood = false;
  String? selectedCategoryId;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    _fetchMeals();
    _loadCategories();
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final response = await Supabase.instance.client
          .from('meal_category')
          .select('meal_category_id, category_name');

      setState(() {
        categories = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
  }

  Future<void> _fetchMeals() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final query = Supabase.instance.client.from('meal').select('''
        *,
        meal_category:meal_category_id (category_name)
      ''');

      // Execute the query without filters
      final response = await query;

      // Filter the results in memory instead of in the query
      List<dynamic> filteredMeals = response;

      // Apply search filter if not empty
      if (searchQuery.isNotEmpty) {
        filteredMeals = filteredMeals
            .where((meal) =>
                meal['name'] != null &&
                meal['name']
                    .toString()
                    .toLowerCase()
                    .contains(searchQuery.toLowerCase()))
            .toList();
      }

      // Apply category filter if selected
      if (filterCategory != null) {
        filteredMeals = filteredMeals
            .where((meal) =>
                meal['meal_category_id'] != null &&
                meal['meal_category_id'].toString() == filterCategory)
            .toList();
      }

      setState(() {
        meals = filteredMeals;
        isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching meals: $e');
      setState(() {
        isLoading = false;
        hasError = true;
      });
      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error loading meals. Please try again. $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  Future<List<dynamic>> _fetchIngredients(int recipeId) async {
    try {
      final response = await Supabase.instance.client
          .from('ingredients')
          .select('*')
          .eq('recipe_id', recipeId);
      return response;
    } catch (e) {
      debugPrint('Error fetching ingredients: $e');
      return [];
    }
  }

  Future<List<dynamic>> _fetchInstructions(int recipeId) async {
    try {
      final response = await Supabase.instance.client
          .from('instructions')
          .select('*')
          .eq('recipe_id', recipeId)
          .order('step_number', ascending: true);
      return response;
    } catch (e) {
      debugPrint('Error fetching instructions: $e');
      return [];
    }
  }

  void _showMealDetailsDialog(dynamic meal) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(child: CircularProgressIndicator());
      },
    );

    try {
      final ingredients = await _fetchIngredients(meal['recipe_id']);
      final instructions = await _fetchInstructions(meal['recipe_id']);

      if (!context.mounted) return;
      Navigator.of(context).pop(); // Dismiss loading dialog

      if (!context.mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800, maxHeight: 800),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          meal['name'] ?? 'Meal Details',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Image
                          if (meal['image_url'] != null)
                            Center(
                              child: Container(
                                height: 250,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  image: DecorationImage(
                                    image: NetworkImage(meal['image_url']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            )
                          else
                            Container(
                              height: 200,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 64,
                                color: Colors.grey,
                              ),
                            ),
                          const SizedBox(height: 20),

                          // Basic Details
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Left Column - Meal Details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildSection(
                                      'Description',
                                      meal['description'] ??
                                          'No description available',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildSection(
                                      'Category',
                                      meal['meal_category'] != null
                                          ? meal['meal_category']
                                              ['category_name']
                                          : 'Uncategorized',
                                    ),
                                    const SizedBox(height: 10),
                                    _buildSection(
                                      'Dietary Information',
                                      _buildDietaryInfo(meal),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),

                              // Right Column - Ingredients
                              Expanded(
                                child: _buildSection(
                                  'Ingredients',
                                  ingredients.isEmpty
                                      ? 'No ingredients available'
                                      : Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: ingredients
                                              .map<Widget>((ingredient) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 8.0),
                                              child: Text(
                                                '• ${ingredient['quantity']} ${ingredient['unit']} ${ingredient['name']}',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            );
                                          }).toList(),
                                        ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Instructions
                          _buildSection(
                            'Instructions',
                            instructions.isEmpty
                                ? 'No instructions available'
                                : Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children:
                                        instructions.map<Widget>((instruction) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 12.0),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Container(
                                              width: 25,
                                              height: 25,
                                              decoration: BoxDecoration(
                                                color: Colors.green,
                                                borderRadius:
                                                    BorderRadius.circular(12.5),
                                              ),
                                              child: Center(
                                                child: Text(
                                                  '${instruction['step_number']}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Expanded(
                                              child: Text(
                                                instruction['instruction'] ??
                                                    '',
                                                style: const TextStyle(
                                                    fontSize: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context)
                                .pop(); // Close the details dialog
                            _showEditMealDialog(meal); // Open the edit dialog
                          },
                          icon: const Icon(Icons.edit),
                          label: const Text('Edit'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed: () {
                            _confirmDeleteMeal(meal);
                          },
                          icon: const Icon(Icons.delete),
                          label: const Text('Delete'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint('Error showing meal details: $e');
      if (context.mounted) {
        Navigator.of(context).pop(); // Dismiss loading dialog
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error showing meal details. Please try again. $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
    }
  }

  void _showEditMealDialog(dynamic meal) {
    // Set initial values from the meal data
    nameController.text = meal['name'] ?? '';
    descriptionController.text = meal['description'] ?? '';

    // Create local variables for the checkboxes that will be used in the StatefulBuilder
    bool localIsNuts = meal['is_nuts'] ?? false;
    bool localIsHalal = meal['is_halal'] ?? false;
    bool localIsDairy = meal['is_dairy'] ?? false;
    bool localIsSeafood = meal['is_seafood'] ?? false;
    String? localSelectedCategoryId = meal['meal_category_id']?.toString();

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
            // Use StatefulBuilder to manage state within the dialog
            builder: (context, setState) {
          return Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
              child: Form(
                key: formKey,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Edit Meal',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Image (Display only, not editable in this dialog)
                            if (meal['image_url'] != null)
                              Container(
                                height: 150,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  image: DecorationImage(
                                    image: NetworkImage(meal['image_url']),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              )
                            else
                              Container(
                                height: 150,
                                width: double.infinity,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        size: 40, color: Colors.grey),
                                    SizedBox(height: 8),
                                    Text('No Image Available'),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 16),

                            // Editable Fields
                            TextFormField(
                              controller: nameController,
                              decoration: const InputDecoration(
                                labelText: 'Meal Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter a meal name'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            TextFormField(
                              controller: descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Description',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),

                            DropdownButtonFormField<String>(
                              value: localSelectedCategoryId,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                                border: OutlineInputBorder(),
                              ),
                              items: categories.map((category) {
                                return DropdownMenuItem(
                                  value:
                                      category['meal_category_id'].toString(),
                                  child: Text(category['category_name']),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  localSelectedCategoryId = value;
                                });
                              },
                              validator: (value) => value == null
                                  ? 'Please select a category'
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            const Text(
                              'Dietary Information',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),

                            CheckboxListTile(
                              title: const Text('Contains Nuts'),
                              value: localIsNuts,
                              onChanged: (value) {
                                setState(() {
                                  localIsNuts = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),

                            CheckboxListTile(
                              title: const Text('Halal'),
                              value: localIsHalal,
                              onChanged: (value) {
                                setState(() {
                                  localIsHalal = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),

                            CheckboxListTile(
                              title: const Text('Contains Dairy'),
                              value: localIsDairy,
                              onChanged: (value) {
                                setState(() {
                                  localIsDairy = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),

                            CheckboxListTile(
                              title: const Text('Contains Seafood'),
                              value: localIsSeafood,
                              onChanged: (value) {
                                setState(() {
                                  localIsSeafood = value ?? false;
                                });
                              },
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),

                            const SizedBox(height: 16),
                            const Text(
                              'Note: To edit ingredients and instructions, please use the full meal editor.',
                              style:
                                  TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton(
                            onPressed: () {
                              if (formKey.currentState?.validate() ?? false) {
                                // Now pass the local state variables to _updateMeal
                                _updateMeal(
                                    meal,
                                    localIsNuts,
                                    localIsHalal,
                                    localIsDairy,
                                    localIsSeafood,
                                    localSelectedCategoryId);
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        });
      },
    );
  }

// Update this method to accept the checkbox values
  Future<void> _updateMeal(dynamic meal, bool isNuts, bool isHalal,
      bool isDairy, bool isSeafood, String? selectedCategoryId) async {
    try {
      final recipeId = meal['recipe_id'];

      await Supabase.instance.client.from('meal').update({
        'name': nameController.text,
        'description': descriptionController.text,
        'meal_category_id': selectedCategoryId,
        'is_nuts': isNuts,
        'is_halal': isHalal,
        'is_dairy': isDairy,
        'is_seafood': isSeafood,
      }).eq('recipe_id', recipeId);

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Success'),
            content: const Text('Meal updated successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      // Refresh the meals list
      _fetchMeals();
    } catch (e) {
      debugPrint('Error updating meal: $e');
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error updating meal, please try again. $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildSection(String title, dynamic content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        content is Widget
            ? content
            : Text(
                content.toString(),
                style: const TextStyle(fontSize: 14),
              ),
      ],
    );
  }

  String _buildDietaryInfo(dynamic meal) {
    List<String> dietaryInfo = [];

    if (meal['is_nuts'] == true) dietaryInfo.add('Contains Nuts');
    if (meal['is_halal'] == true) dietaryInfo.add('Halal');
    if (meal['is_dairy'] == true) dietaryInfo.add('Contains Dairy');
    if (meal['is_seafood'] == true) dietaryInfo.add('Contains Seafood');

    return dietaryInfo.isEmpty
        ? 'No dietary information available'
        : dietaryInfo.join(', ');
  }

  void _confirmDeleteMeal(dynamic meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete "${meal['name']}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteMeal(meal);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteMeal(dynamic meal) async {
    try {
      final recipeId = meal['recipe_id'];

      // First delete related records (ingredients and instructions)
      await Supabase.instance.client
          .from('ingredients')
          .delete()
          .eq('recipe_id', recipeId);

      await Supabase.instance.client
          .from('instructions')
          .delete()
          .eq('recipe_id', recipeId);

      // Then delete the meal itself
      await Supabase.instance.client
          .from('meal')
          .delete()
          .eq('recipe_id', recipeId);

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Success'),
              content: const Text('Meal deleted successfully!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          });

      // Refresh the meals list
      _fetchMeals();
    } catch (e) {
      debugPrint('Error deleting meal: $e');
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Error deleting meal, please try again. $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and filter bar
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search meals...',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          searchQuery = value;
                        },
                        onSubmitted: (value) {
                          _fetchMeals();
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Filter by Category',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        value: filterCategory,
                        onChanged: (String? newValue) {
                          setState(() {
                            filterCategory = newValue;
                          });
                          _fetchMeals();
                        },
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('All Categories'),
                          ),
                          ...categories.map((category) {
                            return DropdownMenuItem<String>(
                              value: category['meal_category_id'].toString(),
                              child: Text(category['category_name']),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: _fetchMeals,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 16, horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Meals grid/list
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : hasError
                      ? const Center(
                          child: Text(
                            'Error loading meals. Please try again.',
                            style: TextStyle(fontSize: 16, color: Colors.red),
                          ),
                        )
                      : meals.isEmpty
                          ? const Center(
                              child: Text(
                                'No meals found.',
                                style:
                                    TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                childAspectRatio: 0.8,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: meals.length,
                              itemBuilder: (context, index) {
                                final meal = meals[index];
                                return _buildMealCard(meal);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(dynamic meal) {
    return GestureDetector(
      onTap: () => _showMealDetailsDialog(meal),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  image: meal['image_url'] != null
                      ? DecorationImage(
                          image: NetworkImage(meal['image_url']),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey[300],
                ),
                child: meal['image_url'] == null
                    ? const Center(
                        child: Icon(
                          Icons.fastfood,
                          size: 48,
                          color: Colors.grey,
                        ),
                      )
                    : null,
              ),
            ),
            // Details
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal['name'] ?? 'Unnamed Meal',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      meal['meal_category'] != null
                          ? meal['meal_category']['category_name']
                          : 'Uncategorized',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (meal['is_nuts'] == true) _buildDietaryTag('Nuts'),
                        if (meal['is_halal'] == true) _buildDietaryTag('Halal'),
                        if (meal['is_dairy'] == true) _buildDietaryTag('Dairy'),
                        if (meal['is_seafood'] == true)
                          _buildDietaryTag('Seafood'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDietaryTag(String label) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.green[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.green[400]!),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: Colors.green[800],
        ),
      ),
    );
  }
}
