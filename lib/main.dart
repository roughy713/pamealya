import 'package:flutter/material.dart';
import 'home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomePage(),
    );
  }
}

//mao ni sya ang sa dashboard
// import 'package:flutter/material.dart';
// import 'famhead_dashboard.dart'; // Import the famhead_dashboard file

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home:
//           FamHeadDashboard(), // Run the FamHeadDashboard widget as the home screen
//     );
//   }
// }
