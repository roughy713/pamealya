import 'package:flutter/material.dart';
import 'family_head_login.dart';
import 'cook_login.dart';

void showLoginDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        content: Container(
          width: 500, // Adjust the width to make the dialog smaller
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  'Hi Welcome Back To',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              Image.asset(
                'assets/logo-dark.png', // Replace with your logo image path
                height: 60, // Reduced height
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Login As Family Head Button
                  Column(
                    children: [
                      Image.asset(
                        'assets/logo-dark.png', // Replace with your logo image path
                        height: 30, // Reduced height
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          showFamilyHeadLoginDialog(
                              context); // Show family head login modal
                        },
                        icon: const Icon(Icons.family_restroom),
                        label: const Text('Family Head'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Login As Cook Button
                  Column(
                    children: [
                      Image.asset(
                        'assets/logo-dark.png', // Replace with your logo image path
                        height: 30, // Reduced height
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close the dialog
                          showCookLoginDialog(context); // Show cook login modal
                        },
                        icon: const Icon(Icons.medical_services),
                        label: const Text('Cook'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
