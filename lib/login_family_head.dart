import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'famhead_dashboard.dart'; // Redirect to this page after successful login

class LoginDialog extends StatefulWidget {
  @override
  _LoginDialogState createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Function to handle the login logic
  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      // If form is not valid, return early
      return;
    }

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      // Query the Family_Head table to get the user by username and password
      final response = await Supabase.instance.client
          .from('Family_Head')
          .select('first_name, last_name')
          .eq('username', username)
          .eq('password', password)
          .single(); // 'single' will return a single row instead of a list

      // Check if a user was found
      if (response != null) {
        // Extract first name and last name from the response
        final firstName = response['first_name'];
        final lastName = response['last_name'];

        // Login successful, redirect to the Family Head Dashboard with the user's name
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FamHeadDashboard(
              firstName: firstName,
              lastName: lastName,
            ),
          ),
        );
      } else {
        _showWarning('Invalid username or password');
      }
    } catch (e) {
      _showWarning('Error occurred while logging in: $e');
    }
  }

  // Function to show warning messages
  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      content: SizedBox(
        width: 500, // Adjust the width to make the dialog smaller
        child: Form(
          key: _formKey,
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
                height: 60, // Reduced height
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username'; // Show this message if field is empty
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter password'; // Show this message if field is empty
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _handleLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor:
                      Colors.black, // Corrected text color parameter
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                ),
                child: const Text('Login'),
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
      ),
    );
  }
}

// Function to show the login dialog
void showFamilyHeadLoginDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return LoginDialog();
    },
  );
}
