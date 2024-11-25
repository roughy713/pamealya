import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealPlanDashboard extends StatefulWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;
  final List<Map<String, dynamic>> familyMembers;
  final Map<String, dynamic> portionSizeData;

  const MealPlanDashboard({
    super.key,
    required this.mealPlanData,
    required this.familyMembers,
    required this.portionSizeData,
  });

  @override
  _MealPlanDashboardState createState() => _MealPlanDashboardState();
}

class _MealPlanDashboardState extends State<MealPlanDashboard> {
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void dispose() {
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
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
          .select('description, image_url, link')
          .eq('recipe_id', recipeId)
          .maybeSingle();

      if (response == null) {
        return {
          'description': 'No description available.',
          'image_url': null,
          'link': 'No link available.',
        };
      }

      return {
        'description': response['description'] ?? 'No description available.',
        'image_url': response['image_url'],
        'link': response['link'] ?? 'No link available.',
      };
    } catch (error) {
      return {
        'description': 'Error fetching description.',
        'image_url': null,
        'link': 'Error fetching link.',
      };
    }
  }

  void _showMealDetailsDialog(
      BuildContext context, Map<String, dynamic> meal) async {
    if (meal['recipe_id'] == null) return;

    final mealDetails = await fetchMealDetails(meal['recipe_id']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(meal['meal_name'] ?? 'Meal Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (mealDetails['image_url'] != null)
                  Image.network(mealDetails['image_url'], fit: BoxFit.cover),
                const SizedBox(height: 10),
                const Text(
                  'Description:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(mealDetails['description']),
                const SizedBox(height: 10),
                const Text(
                  'More Information:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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

  @override
  Widget build(BuildContext context) {
    bool isMealPlanEmpty = widget.mealPlanData.isEmpty ||
        widget.mealPlanData.every(
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
                borderRadius: BorderRadius.circular(16.0), // Circular edges
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Table(
                    defaultColumnWidth: const FixedColumnWidth(150),
                    border: TableBorder.all(
                      color: Colors.grey.withOpacity(0.5),
                      width: 1,
                    ),
                    children: [
                      TableRow(
                        decoration: const BoxDecoration(
                          color: Colors.greenAccent,
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
                      for (int i = 0; i < widget.mealPlanData.length; i++)
                        _buildTableRow(context, i, widget.mealPlanData[i]),
                    ],
                  ),
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

  Widget _buildMealCell(BuildContext context, Map<String, dynamic>? meal) {
    if (meal == null || meal['meal_name'] == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text(
          'N/A',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12),
        ),
      );
    }

    return GestureDetector(
      onTap: meal['recipe_id'] != null
          ? () => _showMealDetailsDialog(context, meal)
          : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meal['meal_name'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  TableRow _buildTableRow(
      BuildContext context, int dayIndex, List<Map<String, dynamic>> meals) {
    return TableRow(
      decoration: BoxDecoration(
        color: dayIndex % 2 == 0 ? Colors.white : Colors.grey.withOpacity(0.1),
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
        _buildMealCell(context, meals.isNotEmpty ? meals[0] : null),
        for (var member in widget.familyMembers) _buildServingCell(member),
        _buildMealCell(context, meals.length > 1 ? meals[1] : null),
        for (var member in widget.familyMembers) _buildServingCell(member),
        _buildMealCell(context, meals.length > 2 ? meals[2] : null),
        for (var member in widget.familyMembers) _buildServingCell(member),
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
      child: Text(
        'Rice: ${portion['Rice_breakfast']}, '
        'Protein: ${portion['Proteins_per_meal']}, '
        'Fruits and Vegetables: ${portion['FruitsVegetables_per_meal']}, '
        'Water: ${portion['Water_per_meal']}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}
