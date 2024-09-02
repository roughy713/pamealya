import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () {
                // Navigate to About Us
              },
              child: const Text(
                'About Us',
                style: TextStyle(color: Colors.black),
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    // Navigate to Cooks
                  },
                  child: const Text(
                    'Become one of our Cooks',
                    style: TextStyle(color: Colors.black),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    print("Login button pressed"); // Debugging line
                    _showLoginDialog(context);
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
                    'assets/logo-dark.png', // Replace with your logo image path
                    height: 80, // Adjust the height as needed
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
                      // Sign up action
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
                    'assets/bowl.png', // Replace with your food image path
                    height: 250, // Increased the height of the bowl image
                  ),
                ],
              ),
            ),
          ),
          Container(
            width: double.infinity, // Make the container take up the full width
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1CBB80), // Updated to the new green color
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.center, // Center text horizontally
              children: const [
                Text(
                  'About Us',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center, // Center the text
                ),
                SizedBox(height: 10),
                Text(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit. '
                  'Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                  textAlign: TextAlign.center, // Center the text
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF0B6D4D), // Footer color updated to #0B6D4D
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: const Text(
            'All Rights Reserved\nFOOTER',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors
                  .white, // Text color changed to white for better contrast
            ),
          ),
        ),
      ),
    );
  }

  // Function to show the login dialog
  void _showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Hi Welcome Back To',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Image.asset(
                  'assets/logo-dark.png', // Replace with your logo image path
                  height: 100, // Adjust the height as needed
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Login As Family Head Button
                    Column(
                      children: [
                        Image.asset(
                          'assets/logo-dark.png', // Replace with your logo image path
                          height: 50, // Adjust the height as needed
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            _showFamilyHeadLoginDialog(
                                context); // Show family head login modal
                          },
                          icon: const Icon(Icons.family_restroom),
                          label: const Text('Login As Family Head'),
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
                          height: 50, // Adjust the height as needed
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pop(); // Close the dialog
                            _showCookLoginDialog(
                                context); // Show cook login modal
                          },
                          icon: const Icon(Icons.medical_services),
                          label: const Text('Login As Cook'),
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

  // Function to show the Family Head login dialog
  void _showFamilyHeadLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hi Welcome Back To',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'assets/logo-dark.png', // Replace with your logo image path
                  height: 100, // Adjust the height as needed
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Implement login logic here
                  },
                  child: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor:
                        Colors.black, // Corrected text color parameter
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Implement forgot password logic here
                  },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Implement sign-up logic here
                  },
                  child: const Text("Don't Have An Account?"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Function to show the Cook login dialog
  void _showCookLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Hi Welcome Back To',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.asset(
                  'assets/logo-dark.png', // Replace with your logo image path
                  height: 100, // Adjust the height as needed
                ),
                const SizedBox(height: 20),
                TextField(
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Implement login logic here
                  },
                  child: const Text('Login'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow[700],
                    foregroundColor:
                        Colors.black, // Corrected text color parameter
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Implement forgot password logic here
                  },
                  child: const Text('Forgot Password?'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () {
                    // Implement sign-up logic here
                  },
                  child: const Text("Don't Have An Account?"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
