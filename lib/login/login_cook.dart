import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/cook/cook_dashboard.dart'; // Redirect to this page after successful login

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
        _showWarning('Your account has not been approved by the admin.');
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
      _showWarning('Error loading cook details: $e');
    }
  }

  void _showWarning(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
                  // Forgot Password logic
                  _showWarning(
                      'Forgot Password functionality not implemented.');
                },
                child: const Text('Forgot Password?'),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  // Redirect to signup
                  _showWarning('Signup functionality not implemented.');
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
