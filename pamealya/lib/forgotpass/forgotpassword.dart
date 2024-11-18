import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordDialog extends StatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  _ForgotPasswordDialogState createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  final TextEditingController _emailController = TextEditingController();
  String? _errorMessage;

  // Function to send the password reset email with email existence check
  Future<void> _sendPasswordResetEmail(String email) async {
    try {
      // Step 1: Check if the email exists in the Family_Head table
      final response = await Supabase.instance.client
          .from('Family_Head')
          .select('email')
          .eq('email', email)
          .maybeSingle();

      // Check if the email does not exist
      if (response == null) {
        setState(() {
          _errorMessage = 'Email not found. Please try again.';
        });
        return;
      }

      // Step 2: If email is found, clear the error message and send the password reset email
      setState(() {
        _errorMessage = null;
      });
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset email sent!')),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'An error occurred. Please try again later.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reset Password'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Enter your email to receive a password reset link.'),
          const SizedBox(height: 10),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Email',
              border: const OutlineInputBorder(),
              errorText:
                  _errorMessage, // Display error message under the text box
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
            final email = _emailController.text;
            await _sendPasswordResetEmail(email);
          },
          child: const Text('Send Link'),
        ),
      ],
    );
  }
}

// Function to show the Forgot Password dialog
void showForgotPasswordDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return ForgotPasswordDialog();
    },
  );
}
