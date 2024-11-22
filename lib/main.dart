import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pamealya/dashboard/famhead/famhead_dashboard.dart'; // <-- Import FamHeadDashboard
import 'home_page.dart'; // Your login page
import 'dart:async'; // Import for StreamSubscription

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url:
        'https://mtwwfagurgkeggzicslj.supabase.co', // Replace with your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10d3dmYWd1cmdrZWdnemljc2xqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYxOTUxMDAsImV4cCI6MjA0MTc3MTEwMH0.czvacjIwvIcLYPmKD3NrFpg75H6DCkOrhg48Q0KwPXI', // Replace with your Supabase anon key
  );

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool isAuthenticated = false;
  late StreamSubscription<AuthState> _authStateSubscription;
  String? firstName;
  String? lastName;
  String? currentUserUsername;

  @override
  void initState() {
    super.initState();

    // Listen to authentication state changes
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;

      // Update the isAuthenticated flag based on the session
      setState(() {
        isAuthenticated = session != null;
      });

      // If user is authenticated, fetch user details from 'familymember' table
      if (session != null) {
        _fetchFamilyHeadDetails(session.user!.id);
      }
    });

    // Check if the user is already authenticated when the app starts
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        isAuthenticated = true;
      });
      _fetchFamilyHeadDetails(user.id); // Fetch the family details
    }
  }

  @override
  void dispose() {
    // Cancel the auth state change listener when the app is disposed
    _authStateSubscription.cancel();
    super.dispose();
  }

  // Fetch family details based on the current user's ID
  Future<void> _fetchFamilyHeadDetails(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select('first_name, last_name, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        // No matching user found, redirect to HomePage
        setState(() {
          isAuthenticated = false;
        });
        return;
      }

      setState(() {
        firstName = response['first_name'] ?? 'Unknown';
        lastName = response['last_name'] ?? 'User';
        currentUserUsername = response['user_id'];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching family head details: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // If not authenticated, show the HomePage (login page)
      home: !isAuthenticated
          ? const HomePage()
          : firstName == null || lastName == null || currentUserUsername == null
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                ) // Show loading if family details are not fetched yet
              : FamHeadDashboard(
                  firstName: firstName!, // Pass the first name
                  lastName: lastName!, // Pass the last name
                  currentUserUsername: currentUserUsername!, // Pass the user id
                ),
    );
  }
}

//mao ni sya and para sa admin login
// import 'package:flutter/material.dart';
// import 'package:pamealya/login/login_admin.dart';
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
//       home: const LoginAdmin(),
//     );
//   }
// }
