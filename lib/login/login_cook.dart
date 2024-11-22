import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/cook/cook_dashboard.dart';
import 'package:pamealya/signup/signup_cook_dialog.dart';

class CookLoginDialog extends StatefulWidget {
  const CookLoginDialog({super.key});

  @override
  _CookLoginDialogState createState() => _CookLoginDialogState();
}

class _CookLoginDialogState extends State<CookLoginDialog> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _checkSessionOnStartup(); // Check session when the app initializes
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.session != null) {
        _redirectToDashboard(event.session!.user);
      }
    });
  }

  Future<void> _checkSessionOnStartup() async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session != null) {
      _redirectToDashboard(session.user!); // Redirect if session is valid
    }
  }

  Future<void> _redirectToDashboard(User user) async {
    try {
      // Check if the cook is approved (is_accepted == true)
      final cookResponse = await Supabase.instance.client
          .from('Local_Cook')
          .select('first_name, last_name, is_accepted')
          .eq('user_id', user.id)
          .single();

      if (cookResponse == null || cookResponse['is_accepted'] != true) {
        _showWarning('Your account is not yet approved by the admin.');
        return;
      }

      final firstName = cookResponse['first_name'];
      final lastName = cookResponse['last_name'];

      // Redirect to the Cook Dashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => CookDashboard(
            firstName: firstName,
            lastName: lastName,
            currentUserId: user.id,
            currentUserUsername: user.email ?? '',
          ),
        ),
      );
    } catch (e) {
      _showWarning('Error loading user data: $e');
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text;
    final password = _passwordController.text;

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        _showWarning(
            'Error: Authentication failed. Please check your credentials.');
        return;
      }

      _redirectToDashboard(response.user!);
    } catch (e) {
      _showWarning('Error during login: $e');
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      _showWarning('Error: $e');
    }
  }

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
                  labelText: 'Username (Email)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter username (email)';
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
                onPressed: () => _showForgotPasswordDialog(context),
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
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

// Function to show the login dialog
void showCookLoginDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return const CookLoginDialog();
    },
  );
}
