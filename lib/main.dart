import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pamealya/dashboard/famhead/famhead_dashboard.dart'; // Import FamHeadDashboard
import 'package:pamealya/dashboard/cook/cook_dashboard.dart'; // Import CookDashboard
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
  bool isLoading = true;

  // Family Head details
  String? famFirstName;
  String? famLastName;
  String? famUserId;

  // Cook details
  String? cookFirstName;
  String? cookLastName;
  String? cookUserId;

  late StreamSubscription<AuthState> _authStateSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to authentication state changes
    _authStateSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;

      if (session == null) {
        // Handle logout
        setState(() {
          isAuthenticated = false;
          isLoading = false;
        });
        return;
      }

      // If session exists, fetch user details
      _fetchUserDetails(session.user!.id);
    });

    // Check if the user is already authenticated when the app starts
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _fetchUserDetails(user.id);
    } else {
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _authStateSubscription.cancel();
    super.dispose();
  }

  // Fetch user details based on the current user's ID
  Future<void> _fetchUserDetails(String userId) async {
    try {
      setState(() {
        isLoading = true;
      });

      // Check if the user is a Family Head
      final famResponse = await Supabase.instance.client
          .from('familymember')
          .select('first_name, last_name, user_id')
          .eq('user_id', userId)
          .maybeSingle();

      if (famResponse != null) {
        // Family Head found
        setState(() {
          famFirstName = famResponse['first_name'];
          famLastName = famResponse['last_name'];
          famUserId = famResponse['user_id'];
          isAuthenticated = true;
          isLoading = false;
        });
        return;
      }

      // Check if the user is a Cook
      final cookResponse = await Supabase.instance.client
          .from('Local_Cook')
          .select('first_name, last_name, user_id, is_accepted')
          .eq('user_id', userId)
          .maybeSingle();

      if (cookResponse != null && cookResponse['is_accepted'] == true) {
        // Cook found and approved
        setState(() {
          cookFirstName = cookResponse['first_name'];
          cookLastName = cookResponse['last_name'];
          cookUserId = cookResponse['user_id'];
          isAuthenticated = true;
          isLoading = false;
        });
        return;
      }

      // If no matching user is found, treat as not authenticated
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
    } catch (e) {
      // Handle errors
      setState(() {
        isAuthenticated = false;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Home',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: isLoading
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            )
          : !isAuthenticated
              ? const HomePage()
              : _buildDashboard(),
    );
  }

  Widget _buildDashboard() {
    if (famFirstName != null && famLastName != null && famUserId != null) {
      return FamHeadDashboard(
        firstName: famFirstName!,
        lastName: famLastName!,
        currentUserUsername: famUserId!, // Pass the user's username
        currentUserId: famUserId!, // Pass the current user's ID
      );
    } else if (cookFirstName != null &&
        cookLastName != null &&
        cookUserId != null) {
      return CookDashboard(
        firstName: cookFirstName!,
        lastName: cookLastName!,
        currentUserId: cookUserId!, // Pass the current user's ID
        currentUserUsername: '', // Provide a default or relevant value
      );
    }
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
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
