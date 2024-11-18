import 'package:flutter/material.dart';

class MealPlanDashboard extends StatelessWidget {
  final List<List<Map<String, dynamic>>> mealPlanData;
  final List<Map<String, dynamic>> familyMembers;

  const MealPlanDashboard({
    Key? key,
    required this.mealPlanData,
    required this.familyMembers,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (mealPlanData.isEmpty || familyMembers.isEmpty) {
      return Center(
        child: Text(
          'No meal plan generated',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      );
    }

    final ScrollController scrollController = ScrollController();

    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Scrollbar(
        controller: scrollController, // Attach the ScrollController
        thumbVisibility: true, // Ensure the scrollbar is visible
        child: SingleChildScrollView(
          controller: scrollController, // Pass the controller here
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical, // Allow vertical scrolling
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth:
                    MediaQuery.of(context).size.width, // Full-screen width
              ),
              child: Table(
                columnWidths: {
                  0: FixedColumnWidth(70), // Day column
                  1: FlexColumnWidth(2), // Breakfast column
                  for (int i = 2; i < familyMembers.length + 2; i++)
                    i: FlexColumnWidth(1), // Portion columns
                },
                border: TableBorder.all(
                  color: Colors.grey.withOpacity(0.5),
                  width: 1,
                ),
                children: [
                  // Header Row
                  TableRow(
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                    ),
                    children: [
                      _buildHeader('Day'),
                      _buildHeader('Breakfast'),
                      for (var member in familyMembers)
                        _buildHeader(
                            '${member['first_name']} ${member['last_name']}'),
                      _buildHeader('Lunch'),
                      for (var member in familyMembers)
                        _buildHeader(
                            '${member['first_name']} ${member['last_name']}'),
                      _buildHeader('Dinner'),
                      for (var member in familyMembers)
                        _buildHeader(
                            '${member['first_name']} ${member['last_name']}'),
                    ],
                  ),
                  // Rows for each day
                  for (int i = 0; i < mealPlanData.length; i++)
                    _buildTableRow(context, i, mealPlanData[i]),
                ],
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
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildMealCell(BuildContext context, Map<String, dynamic>? meal) {
    if (meal == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8.0),
        child: Text('N/A', textAlign: TextAlign.center),
      );
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          _showMealDetailsDialog(context, meal);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            meal['meal_name'] ?? 'N/A',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPortionCell(String portion) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Center(
        child: Text(
          portion,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
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
        _buildMealCell(context, {'meal_name': 'Day ${dayIndex + 1}'}),
        _buildMealCell(context, meals.isNotEmpty ? meals[0] : null),
        for (var member in familyMembers)
          _buildPortionCell(determinePortionForAge(member['age'] ?? 0)),
        _buildMealCell(context, meals.length > 1 ? meals[1] : null),
        for (var member in familyMembers)
          _buildPortionCell(determinePortionForAge(member['age'] ?? 0)),
        _buildMealCell(context, meals.length > 2 ? meals[2] : null),
        for (var member in familyMembers)
          _buildPortionCell(determinePortionForAge(member['age'] ?? 0)),
      ],
    );
  }

  String determinePortionForAge(int age) {
    if (age <= 3) return '1/2';
    if (age <= 6) return '1';
    if (age <= 9) return '1 1/2';
    if (age <= 12) return '2';
    return '2 1/2';
  }

  void _showMealDetailsDialog(BuildContext context, Map<String, dynamic> meal) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(meal['meal_name'] ?? 'Meal Details'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Meal Type: ${meal['meal_type'] ?? 'N/A'}'),
              Text('Meal ID: ${meal['meal_id'] ?? 'N/A'}'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
