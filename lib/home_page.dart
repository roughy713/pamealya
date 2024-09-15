import 'package:flutter/material.dart';
import 'signup_cook_dialog.dart'; // Import the SignUp Cook dialog
import 'signup_famhead_dialog.dart'; // Import the Family Head Sign Up dialog
import 'login_dialog.dart'; // Import the Login dialog

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment:
              MainAxisAlignment.end, // Align buttons to the right
          children: [
            TextButton(
              onPressed: () {
                // Show the sign-up cook dialog
                showSignUpCookDialog(context);
              },
              child: const Text(
                'Become one of our Cooks',
                style: TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                // Show the login dialog
                showLoginDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.yellow[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Login'),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/logo-dark.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Connecting Filipino Families to a Nutritious Future!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showFamilyHeadSignUpDialog(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Sign up Now!'),
                  ),
                  const SizedBox(height: 20),
                  Image.asset(
                    'assets/bowl.png',
                    height: 250,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(Icons.error);
                    },
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1CBB80),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'About Us',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 10),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomAppBar(
        color: Color(0xFF0B6D4D),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'All Rights Reserved\nFOOTER',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  // Function to show the family head sign-up dialog
  void showFamilyHeadSignUpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SignUpFormDialog();
      },
    );
  }

  // Function to show the cook sign-up dialog
  void showSignUpCookDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SignUpCookDialog();
      },
    );
  }
}
