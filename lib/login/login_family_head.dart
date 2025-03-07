import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/famhead/famhead_dashboard.dart';
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

  //Password Visibility
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

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
        _showErrorDialog('Login Failed',
            'We couldn\'t find an account with those credentials. Please double-check and try again.');
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
        _showErrorDialog('Access Denied',
            'Your account isn\'t registered as a family head. Please use the appropriate login option for your account type.');
        // Sign out the user since they're not authorized as a family head
        await Supabase.instance.client.auth.signOut();
        return;
      }

      // Step 3: Check if the user is already logged in somewhere else (optional)
      final currentSession = Supabase.instance.client.auth.currentSession;
      if (currentSession?.user.id != response.user!.id) {
        await Supabase.instance.client.auth.signOut();
        _showErrorDialog('Session Error',
            'There seems to be a session issue. Please try logging in again.');
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
      _showErrorDialog('Error',
          'Something went wrong while trying to log you in. Please try again later.');
      // Ensure user is signed out in case of error
      await Supabase.instance.client.auth.signOut();
    }
  }

  // Function to send password reset email
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Password reset email sent! Please check your inbox.')),
      );
    } catch (e) {
      _showErrorDialog('Email Failed',
          'We couldn\'t send the reset email. Please check your email address and try again.');
    }
  }

  // Function to show the Forgot Password dialog
  void _showForgotPasswordDialog(BuildContext context) {
    final TextEditingController emailController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Forgot Your Password?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                  'No worries! Enter your email below and we\'ll send you a link to reset your password.'),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Your Email',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
            ElevatedButton(
              onPressed: () async {
                final email = emailController.text;
                await _sendPasswordResetEmail(email);
                Navigator.of(context).pop();
              },
              child: const Text('Send Reset Link'),
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
                'Welcome Back!',
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
                  labelText: 'Your Email',
                  hintText: 'Enter the email you signed up with',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'We need your email to log you in';
                  }
                  return null;
                },
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              // Password with visibility toggle
              TextFormField(
                controller: _passwordController,
                obscureText: !_passwordVisible,
                decoration: InputDecoration(
                  labelText: 'Your Password',
                  hintText: 'Enter your password',
                  border: OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _passwordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() {
                        _passwordVisible = !_passwordVisible;
                      });
                    },
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password to continue';
                  }
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _handleLogin(context),
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
                child: const Text('Forgot Your Password?'),
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
                child: const Text("New here? Create an account"),
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
