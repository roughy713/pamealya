import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cook_dashboard.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            constraints:
                const BoxConstraints(maxWidth: 600), // Restrict the width
            child: const SupportForm(),
          ),
        ),
      ),
    );
  }
}

class SupportForm extends StatefulWidget {
  const SupportForm({super.key});

  @override
  _SupportFormState createState() => _SupportFormState();
}

class _SupportFormState extends State<SupportForm> {
  final _formKey = GlobalKey<FormState>();
  String? issueType;
  String? message;
  String? email;
  bool isSubmitting = false;

  final supabase = Supabase.instance.client; // Initialize Supabase client

  Future<void> _submitSupportRequest() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      // Updated Supabase insert method without checking for response.error
      await supabase.from('support_requests').insert({
        'email': email,
        'issue_type': issueType,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'user_type': 'cook', // Set to 'cook' for cook support page
      });

      if (mounted) {
        // Show success dialog instead of immediately popping
        _showSuccessDialog();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $error')),
        );
        setState(() {
          isSubmitting = false;
        });
      }
    }
  }

  void _showSuccessDialog() {
    setState(() {
      isSubmitting = false;
    });

    showDialog(
      context: context,
      barrierDismissible: false, // User must tap button to close dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Success!'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your support request has been submitted successfully.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 12),
              Text(
                'Our support team will review your request and respond as soon as possible.',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              onPressed: () {
                // Close the dialog first
                Navigator.of(context).pop();

                // Get the current user
                final user = supabase.auth.currentUser;

                if (user != null) {
                  // Fetch cook data to pass to the dashboard
                  _navigateToCookDashboard();
                } else {
                  // If no user found, just pop to previous screen
                  Navigator.of(context).pop();
                }
              },
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _navigateToCookDashboard() async {
    try {
      final user = supabase.auth.currentUser;

      if (user != null) {
        // Fetch cook data
        final cookData = await supabase
            .from('Local_Cook')
            .select('first_name, last_name, user_id')
            .eq('user_id', user.id)
            .single();

        if (mounted) {
          // Replace entire navigation stack with the dashboard
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => CookDashboard(
                firstName: cookData['first_name'],
                lastName: cookData['last_name'],
                currentUserId: cookData['user_id'],
                currentUserUsername: '', // Add appropriate value if needed
              ),
            ),
            (route) => false, // This will remove all routes
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error navigating to dashboard: $e')),
        );
        Navigator.of(context).pop(); // Just pop if we can't navigate
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Need Help? Contact Support',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          // Email Field
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Your Email Address',
              prefixIcon: Icon(Icons.email),
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your email address';
              }
              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
            onSaved: (value) {
              email = value;
            },
          ),
          const SizedBox(height: 16),

          // Issue Type Dropdown
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(
              labelText: 'Select Issue Type',
              prefixIcon: Icon(Icons.help_outline),
              border: OutlineInputBorder(),
            ),
            items: [
              'Technical Issue',
              'Billing Query',
              'Feature Request',
              'Other',
            ].map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                issueType = value;
              });
            },
            validator: (value) =>
                value == null ? 'Please select an issue type' : null,
          ),
          const SizedBox(height: 16),

          // Message Field
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Message',
              prefixIcon: Icon(Icons.message),
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your message';
              }
              return null;
            },
            onSaved: (value) {
              message = value;
            },
          ),
          const SizedBox(height: 24),

          // Submit Button
          Center(
            child: ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        _submitSupportRequest();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              ),
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
