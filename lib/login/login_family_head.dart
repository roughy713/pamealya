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
      return;
    }

    final username = _usernameController.text;
    final password = _passwordController.text;

    try {
      // Step 1: Authenticate the user
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: username,
        password: password,
      );

      if (response.user == null) {
        _showWarning(
            'Error: Authentication failed. Please check your credentials.');
        return;
      }

      // Step 2: Query the familymember table with both user_id AND is_family_head condition
      final familyHeadResponse = await Supabase.instance.client
          .from('familymember')
          .select('first_name, last_name, user_id, family_head')
          .eq('user_id', response.user!.id)
          .eq('is_family_head', true) // Add this condition
          .maybeSingle();

      if (familyHeadResponse == null) {
        _showWarning('This account is not registered as a family head.');
        // Sign out the user since they're not authorized as a family head
        await Supabase.instance.client.auth.signOut();
        return;
      }

      // Step 3: Check if the user is already logged in somewhere else (optional)
      final currentSession = await Supabase.instance.client.auth.currentSession;
      if (currentSession?.user?.id != response.user!.id) {
        await Supabase.instance.client.auth.signOut();
        _showWarning('Session error. Please try logging in again.');
        return;
      }

      // Step 4: Redirect to the Family Head Dashboard with the correct data
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => FamHeadDashboard(
              firstName: familyHeadResponse['first_name'],
              lastName: familyHeadResponse['last_name'],
              currentUserUsername: username, // Use the email as username
              currentUserId:
                  response.user!.id, // Use the authenticated user's ID
            ),
          ),
        );
      }
    } catch (e) {
      _showWarning('Error occurred while logging in: $e');
      // Ensure user is signed out in case of error
      await Supabase.instance.client.auth.signOut();
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
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter email';
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
