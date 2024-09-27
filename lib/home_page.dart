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
      body: SingleChildScrollView(
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            Column(
              children: [
                // White section
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 80)
                      .copyWith(bottom: 150), // Added bottom padding
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
                    ],
                  ),
                ),
                // Green section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF1CBB80),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 30, vertical: 70),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(height: 100), // Leave space for the bowl image
                        Text(
                          'About Us',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Inter', // Added Inter font
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 30),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20), // Add padding on the sides
                          child: Text(
                            'At paMEALya, we are dedicated to enhancing the dietary diversity and overall health of Filipino families through innovative solutions. Our platform is designed to offer personalized meal plans featuring locally sourced foods, tailored to meet the unique nutritional needs of each family member.\n\n'
                            'Our mission is to simplify healthy eating by allowing family heads to create detailed profiles for every member of their household. By inputting essential health information and dietary preferences, users receive customized meal plans that ensure balanced nutrition. Our service provides automated weekly meal plans complete with easy-to-follow recipes, promoting variety and nutritional balance in every meal.\n\n'
                            'Understanding that busy lifestyles can make cooking a challenge, paMEALya offers the added convenience of booking local cooks. These skilled professionals can prepare and deliver meals directly to your home, ensuring that nutritious and delicious food is always within reach.\n\n'
                            'The prevalence of malnutrition highlights the urgent need for a solution that addresses diverse dietary needs among Filipino families. paMEALya aims to bridge this gap by leveraging technology to deliver personalized meal plans and local cook services. By doing so, we promote better dietary practices and make healthy eating more accessible and convenient for everyone.\n\n'
                            'Join us on our journey to transform family nutrition and health with paMEALya—where technology meets tradition for a healthier future.',
                            textAlign: TextAlign
                                .center, // Align text properly for readability
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily:
                                  'Inter', // Use Inter font for body text
                              fontSize: 16, // Adjusted font size
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Footer section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  color: const Color(0xFF0B6D4D),
                  child: const Text(
                    '© 2024 paMEALya. All Rights Reserved.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            // Positioned bowl image to overlap white and green sections
            Positioned(
              top: 280, // Adjusted position for the bowl image
              child: Image.asset(
                'assets/bowl.png',
                height: 350,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.error);
                },
              ),
            ),
          ],
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
