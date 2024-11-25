import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealPlanDashboard extends StatefulWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;
  final List<Map<String, dynamic>> familyMembers;

  const MealPlanDashboard({
    super.key,
    required this.mealPlanData,
    required this.familyMembers,
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

  Future<Map<String, String>> fetchServingDetails(
      int age, String gender) async {
    String ageGroup;
    if (age >= 3 && age <= 5) {
      ageGroup = 'Kids 3-5';
    } else if (age >= 6 && age <= 9) {
      ageGroup = 'Kids 6-9';
    } else if (age >= 10 && age <= 12) {
      ageGroup = 'Kids 10-12';
    } else if (age >= 13 && age <= 18) {
      ageGroup = 'Teens 13-18';
    } else if (age >= 19 && age <= 59) {
      ageGroup = 'Adults';
    } else {
      ageGroup = 'Elderly';
    }

    try {
      final response = await Supabase.instance.client
          .from('PortionSize')
          .select('Carbohydrates, Proteins, FruitsVegetables')
          .eq('AgeGroup', ageGroup)
          .eq('Gender', gender)
          .maybeSingle();

      if (response == null) {
        return {
          'Carbohydrates': 'N/A',
          'Proteins': 'N/A',
          'FruitsVegetables': 'N/A',
        };
      }

      return {
        'Carbohydrates': response['Carbohydrates']?.toString() ?? 'N/A',
        'Proteins': response['Proteins']?.toString() ?? 'N/A',
        'FruitsVegetables': response['FruitsVegetables']?.toString() ?? 'N/A',
      };
    } catch (error) {
      debugPrint('Error fetching serving details: $error');
      return {
        'Carbohydrates': 'N/A',
        'Proteins': 'N/A',
        'FruitsVegetables': 'N/A',
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if mealPlanData is empty or contains only empty meals
    bool isMealPlanEmpty = widget.mealPlanData.isEmpty ||
        widget.mealPlanData.every(
          (day) =>
              day.isEmpty || day.every((meal) => meal['meal_name'] == null),
        );

    // Check if familyMembers is empty
    bool areFamilyMembersEmpty = widget.familyMembers.isEmpty;

    // If no meal plan data or no family members, show a message
    if (isMealPlanEmpty || areFamilyMembersEmpty) {
      return Center(
        child: Text(
          'No meal plan generated yet.',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
      );
    }

    // Otherwise, show the meal plan table
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
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  children: [
                    TableRow(
                      decoration: const BoxDecoration(
                        color: Colors.greenAccent,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(16.0),
                          topRight: Radius.circular(16.0),
                        ),
                      ),
                      children: [
                        _buildHeader('Day'),
                        _buildHeader('Breakfast'),
                        for (var member in widget.familyMembers)
                          _buildHeader(
                              '${member['first_name'] ?? 'Unknown'} ${member['last_name'] ?? 'Unknown'}'),
                        _buildHeader('Lunch'),
                        for (var member in widget.familyMembers)
                          _buildHeader(
                              '${member['first_name'] ?? 'Unknown'} ${member['last_name'] ?? 'Unknown'}'),
                        _buildHeader('Dinner'),
                        for (var member in widget.familyMembers)
                          _buildHeader(
                              '${member['first_name'] ?? 'Unknown'} ${member['last_name'] ?? 'Unknown'}'),
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
    );
  }

  Widget _buildHeader(String? text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
      child: Text(
        text ?? 'Unknown',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMealCell(BuildContext context, Map<String, dynamic>? meal) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        meal?['meal_name'] ?? 'N/A',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }

  Widget _buildServingCell(Map<String, String> serving) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        'Carbs: ${serving['Carbohydrates']}\n'
        'Proteins: ${serving['Proteins']}\n'
        'Fruits/Vegetables: ${serving['FruitsVegetables']}',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12),
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
        _buildMealCell(context, {'meal_name': 'Day ${dayIndex + 1}'}),
        _buildMealCell(context, meals.isNotEmpty ? meals[0] : null),
        for (var member in widget.familyMembers)
          FutureBuilder<Map<String, String>>(
            future: fetchServingDetails(
              member['age'] ?? 0,
              member['gender'] ?? 'Unknown',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Loading...', textAlign: TextAlign.center),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Error', textAlign: TextAlign.center),
                );
              }
              return _buildServingCell(snapshot.data!);
            },
          ),
        _buildMealCell(context, meals.length > 1 ? meals[1] : null),
        for (var member in widget.familyMembers)
          FutureBuilder<Map<String, String>>(
            future: fetchServingDetails(
              member['age'] ?? 0,
              member['gender'] ?? 'Unknown',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Loading...', textAlign: TextAlign.center),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Error', textAlign: TextAlign.center),
                );
              }
              return _buildServingCell(snapshot.data!);
            },
          ),
        _buildMealCell(context, meals.length > 2 ? meals[2] : null),
        for (var member in widget.familyMembers)
          FutureBuilder<Map<String, String>>(
            future: fetchServingDetails(
              member['age'] ?? 0,
              member['gender'] ?? 'Unknown',
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Loading...', textAlign: TextAlign.center),
                );
              }
              if (snapshot.hasError) {
                return const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Text('Error', textAlign: TextAlign.center),
                );
              }
              return _buildServingCell(snapshot.data!);
            },
          ),
      ],
    );
  }
}
