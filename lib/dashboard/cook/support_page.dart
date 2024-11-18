import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
      final response = await supabase.from('support_requests').insert({
        'email': email,
        'issue_type': issueType,
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (response.error != null) {
        throw Exception(response.error!.message);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Support request sent to admin!')),
      );
      Navigator.of(context).pop();
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
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
