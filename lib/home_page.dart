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
      body: SafeArea(
        child: SingleChildScrollView(
          // Added to enable scrolling
          child: Column(
            children: [
              Center(
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
              const SizedBox(height: 20), // Add some space between sections
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFF1CBB80),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: const [
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
                      '''At paMEALya, we are dedicated to enhancing the dietary diversity and overall health of Filipino families through innovative solutions. Our platform is designed to offer personalized meal plans featuring locally sourced foods, tailored to meet the unique nutritional needs of each family member. Our mission is to simplify healthy eating by allowing family heads to create detailed profiles for every member of their household. By inputting essential health information and dietary preferences, users receive customized meal plans that ensure balanced nutrition. Our service provides automated weekly meal plans complete with easy-to-follow recipes, promoting variety and nutritional balance in every meal. Understanding that busy lifestyles can make cooking a challenge, paMEALya offers the added convenience of booking local cooks. These skilled professionals can prepare and deliver meals directly to your home, ensuring that nutritious and delicious food is always within reach. The prevalence of malnutrition highlights the urgent need for a solution that addresses diverse dietary needs among Filipino families. paMEALya aims to bridge this gap by leveraging technology to deliver personalized meal plans and local cook services. By doing so, we promote better dietary practices and make healthy eating more accessible and convenient for everyone. Join us on our journey to transform family nutrition and health with paMEALya—where technology meets tradition for a healthier future.''',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
