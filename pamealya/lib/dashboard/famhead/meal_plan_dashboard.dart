import 'package:flutter/material.dart';

class MealPlanDashboard extends StatelessWidget {
  final List<Map<String, dynamic>> mealPlanData;

  const MealPlanDashboard({Key? key, required this.mealPlanData})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: mealPlanData.length,
      itemBuilder: (context, index) {
        final meal = mealPlanData[index];
        return Card(
          margin: const EdgeInsets.all(8.0),
          child: ListTile(
            title: Text(meal['name']),
            subtitle: Text(meal['type']),
            leading: const Icon(Icons.restaurant_menu),
          ),
        );
      },
    );
  }
}
