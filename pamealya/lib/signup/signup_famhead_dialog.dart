import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart'; // Import the uuid package
import '../home_page.dart'; // Import the home page

class SignUpFormDialog extends StatefulWidget {
  const SignUpFormDialog({super.key});

  @override
  SignUpFormDialogState createState() => SignUpFormDialogState();
}

class SignUpFormDialogState extends State<SignUpFormDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers to handle form input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressLine1Controller = TextEditingController();
  final TextEditingController _barangayController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _provinceController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();

  String? _selectedGender;
  bool _isChecked = false;

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return; // Form is not valid
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      const uuid = Uuid(); // Create an instance of the Uuid class
      final famheadId = uuid.v4(); // Generate a unique UUID for famheadid

      // Attempt to insert data into Supabase
      final response =
          await Supabase.instance.client.from('Family_Head').insert({
        'famheadid': famheadId, // Use the generated UUID here
        'first_name': _firstNameController.text,
        'last_name': _lastNameController.text,
        'username': _usernameController.text,
        'password': _passwordController.text,
        'email': _emailController.text,
        'age': int.tryParse(_ageController.text),
        'gender': _selectedGender,
        'phone': _phoneController.text,
        'address_line1': _addressLine1Controller.text,
        'barangay': _barangayController.text,
        'city': _cityController.text,
        'province': _provinceController.text,
        'postal_code': _postalCodeController.text,
        'dob': _dobController.text,
      }).select();

      // Check if data was inserted successfully
      if (response.isNotEmpty) {
        // Show success dialog and redirect
        await _showSuccessDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insert Error: No data returned')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible:
          false, // Prevent dismissing the dialog by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Created'),
          content: const Text('Your account has been created successfully!'),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text =
            DateFormat('dd-MM-yyyy').format(picked); // Format the date
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
        height:
            MediaQuery.of(context).size.height * 0.9, // 90% of screen height
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppBar(
                  elevation: 0,
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Logo and App Name
                      Image.asset(
                        'assets/logo-dark.png', // Your logo path
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                              Icons.error); // Placeholder for missing image
                        },
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Connecting Filipino families to a Nutritious Future!',
                        style: TextStyle(
                          fontSize: 16,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Picture and Upload button
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[300],
                        child: Icon(
                          Icons.person,
                          size: 50,
                          color: Colors.grey[600],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // Upload profile picture logic
                        },
                        child: const Text('Upload Profile Picture'),
                      ),
                      const SizedBox(height: 20),

                      // Sign Up Form
                      Column(
                        children: [
                          // First Name and Last Name
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _firstNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'First Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _lastNameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Last Name',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Email and Username
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Password and Confirm Password
                          TextFormField(
                            controller: _passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Age, Gender, and Date of Birth
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _ageController,
                                  decoration: const InputDecoration(
                                    labelText: 'Age',
                                    border: OutlineInputBorder(),
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['Male', 'Female', 'Other']
                                      .map((label) => DropdownMenuItem(
                                            value: label,
                                            child: Text(label),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    _selectedGender = value;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _dobController,
                            readOnly: true,
                            onTap: () => _selectDate(context),
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon:
                                  Icon(Icons.calendar_today), // Calendar icon
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Phone Number and Address
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 10),

                          // Address Fields: Line 1, Barangay, City, Province, Postal Code
                          TextFormField(
                            controller: _addressLine1Controller,
                            decoration: const InputDecoration(
                              labelText: 'Address Line 1',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _barangayController,
                            decoration: const InputDecoration(
                              labelText: 'Barangay',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _provinceController,
                            decoration: const InputDecoration(
                              labelText: 'Province',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: _postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Terms and Conditions Checkbox
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16.0, vertical: 8.0),
                            child: Row(
                              children: [
                                Checkbox(
                                  value: _isChecked,
                                  onChanged: (bool? value) {
                                    setState(() {
                                      _isChecked = value!;
                                    });
                                  },
                                ),
                                const Expanded(
                                  child: Text(
                                    'I agree to the Terms and Conditions and Privacy Policy',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Sign Up Button
                          ElevatedButton(
                            onPressed: () {
                              if (_isChecked) {
                                _handleSignUp(); // Call the signup function that interacts with Supabase
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Please agree to the Terms and Conditions')),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow[700],
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 60, vertical: 15),
                            ),
                            child: const Text('Sign Up'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
