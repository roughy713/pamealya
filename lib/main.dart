//mao ni sya and para sa homepage
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mtwwfagurgkeggzicslj.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10d3dmYWd1cmdrZWdnemljc2xqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYxOTUxMDAsImV4cCI6MjA0MTc3MTEwMH0.czvacjIwvIcLYPmKD3NrFpg75H6DCkOrhg48Q0KwPXI',
  );

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

//mao ni sya and para sa admin login
// import 'package:flutter/material.dart';
// import 'login_admin.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();

//   try {
//     await Supabase.initialize(
//       url: 'https://mtwwfagurgkeggzicslj.supabase.co',
//       anonKey:
//           'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10d3dmYWd1cmdrZWdnemljc2xqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYxOTUxMDAsImV4cCI6MjA0MTc3MTEwMH0.czvacjIwvIcLYPmKD3NrFpg75H6DCkOrhg48Q0KwPXI',
//     );
//     print('Supabase initialized successfully.');
//   } catch (e) {
//     print('Error initializing Supabase: $e');
//   }

//   runApp(const MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       debugShowCheckedModeBanner:
//           false, // Disables the debug banner in release mode
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//       ),
//       home: LoginAdmin(),
//     );
//   }
// }
