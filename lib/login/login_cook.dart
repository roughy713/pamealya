import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/cook/cook_dashboard.dart'; // Redirect to this page after successful login
import '../signup/signup_cook_dialog.dart'; // Ensure this import exists

class CookLoginDialog extends StatefulWidget {
  const CookLoginDialog({super.key});

  @override
  _CookLoginDialogState createState() => _CookLoginDialogState();
}

class _CookLoginDialogState extends State<CookLoginDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Function to show styled error dialog
  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFFF5F5F5),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.amber[700],
                size: 28,
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          actions: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return; // Form validation failed
    }

    setState(() {
      _isLoading = true; // Show loading indicator
    });

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      // Authenticate the user
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        // Use error dialog instead of warning snackbar
        _showErrorDialog(
          'Error',
          'Something went wrong while trying to log you in. Please try again later.',
        );
        return;
      }

      // Query the `Local_Cook` table to verify the user is a cook
      final cookResponse = await Supabase.instance.client
          .from('Local_Cook')
          .select('first_name, last_name, is_accepted')
          .eq('user_id', response.user!.id)
          .maybeSingle(); // Returns `null` if no matching record is found

      if (cookResponse == null) {
        _showErrorDialog(
          'Account Error',
          'This account is not registered as a cook.',
        );
        return;
      }

      if (cookResponse['is_accepted'] != true) {
        _showErrorDialog(
          'Account Status',
          'Your account has not been approved by the admin.',
        );
        return;
      }

      // Redirect to the cook dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CookDashboard(
            firstName: cookResponse['first_name'],
            lastName: cookResponse['last_name'],
            currentUserId: response.user!.id,
            currentUserUsername: email,
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog(
        'Error',
        'Something went wrong while trying to log you in. Please try again later.',
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading indicator
      });
    }
  }

  Future<void> _redirectToDashboard(User user) async {
    try {
      final cookResponse = await Supabase.instance.client
          .from('Local_Cook')
          .select('first_name, last_name, is_accepted')
          .eq('user_id', user.id)
          .single();

      if (cookResponse['is_accepted'] != true) {
        _showErrorDialog(
          'Account Status',
          'Your account has not been approved by the admin.',
        );
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CookDashboard(
            firstName: cookResponse['first_name'],
            lastName: cookResponse['last_name'],
            currentUserId: user.id,
            currentUserUsername: user.email ?? '',
          ),
        ),
      );
    } catch (e) {
      _showErrorDialog(
        'Error',
        'Error loading cook details. Please try again later.',
      );
    }
  }

  // Function to send password reset email
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      _showErrorDialog(
        'Error',
        'Failed to send password reset email. Please check your email address and try again.',
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
    _emailController.dispose();
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
                'assets/logo-dark.png',
                height: 60,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _emailController,
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
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: () => _handleLogin(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[700],
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 40,
                          vertical: 10,
                        ),
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
                  // Redirect to cook signup dialog
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return const SignUpCookDialog();
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

void showCookLoginDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const CookLoginDialog();
    },
  );
}
