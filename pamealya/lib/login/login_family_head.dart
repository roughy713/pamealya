import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/famhead/famhead_dashboard.dart'; // Redirect to this page after successful login
import 'package:pamealya/signup/signup_famhead_dialog.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

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
      return; // If form is not valid, return early
    }

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      // Query the Family_Head table to get the user by username and password
      final response = await Supabase.instance.client
          .from('Family_Head')
          .select('first_name, last_name, username')
          .eq('username', username)
          .eq('password', password)
          .single();

      final firstName = response['first_name'];
      final lastName = response['last_name'];
      final userUsername = response['username'];

      // Login successful, redirect to the Family Head Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FamHeadDashboard(
            firstName: firstName,
            lastName: lastName,
            currentUserUsername: userUsername, // Pass username here
          ),
        ),
      );
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

  // Function to send password reset email
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  // Function to show the Forgot Password dialog
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter your email to receive a password reset link.'),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text;
                await _sendPasswordResetEmail(email);
                Navigator.of(context).pop();
              },
              child: const Text('Send Link'),
            ),
          ],
        );
      },
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
        width: 500,
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
                height: 60,
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
                    return 'Please enter username';
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
                    return 'Please enter password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _handleLogin(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
                ),
                child: const Text('Login'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Open the Forgot Password dialog
                  _showForgotPasswordDialog(context);
                },
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Redirect to the Family Head Sign-Up dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const SignUpFormDialog(); // Use the correct class name for the dialog
                    },
                  );
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
      return const LoginDialog();
    },
  );
}
