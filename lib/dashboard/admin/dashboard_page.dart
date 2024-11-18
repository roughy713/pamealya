import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.person, size: 40),
              Icon(Icons.group, size: 40),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('10 Cooks', style: TextStyle(fontSize: 18)),
              Text('10 Family Heads', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}
