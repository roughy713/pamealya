//mao ni sya and para sa homepage
// import 'package:flutter/material.dart';
// import 'home_page.dart';

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home: HomePage(),
//     );
//   }
// }

//mao ni sya ang sa family head dashboard
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

//mao ni sya ang sa admin dashboard
// import 'package:flutter/material.dart';
// import 'admin_dashboard.dart'; // Import the admin_dashboard file

// void main() {
//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return const MaterialApp(
//       home:
//           AdminDashboard(), // Run the AdminDashboard widget as the home screen
//     );
//   }
// }

// mao ni sya ang sa cook dashboard
import 'package:flutter/material.dart';
import 'cook_dashboard.dart'; // Import the cook_dashboard file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: CookDashboard(), // Run the Cook widget as the home screen
    );
  }
}
