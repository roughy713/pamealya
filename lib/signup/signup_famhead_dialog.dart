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
    showDialog<void>(
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

  Future<void> _showTermsDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(8)), // Slightly rounded corners
          child: Container(
            width: 520, // Fixed width
            height: 500, // Fixed height
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Spread content evenly
              children: [
                Text(
                  'Terms and Conditions',
                  style: Theme.of(context).textTheme.titleLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Intellectual Property
                        Text(
                          'Intellectual Property',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'All content within the paMEALya application, including but not limited to text, graphics, logos, and software, is the property of the paMEALya team and is protected by copyright, trademark, and other intellectual property laws. Unauthorized reproduction, distribution, or modification of any part of this application is strictly prohibited without prior written permission from the paMEALya team.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // License to Use
                        Text(
                          'License to Use',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'paMEALya grants users a limited, non-exclusive, non-transferable license to use the application for personal, non-commercial purposes. You may not modify, copy, distribute, transmit, display, perform, reproduce, publish, license, or create derivative works from the app or any part of it without express permission from the paMEALya team.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // User Obligations
                        Text(
                          'User Obligations',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'By using paMEALya, you agree to:\n'
                          '- Provide Accurate Information: Users must provide accurate and complete health, dietary, and personal information to enable the app to generate appropriate meal plans.\n'
                          '- Use the App Responsibly: The app must be used only for its intended purpose. Any misuse, including falsifying information, unauthorized access, or attempting to hack or modify the app, is strictly prohibited.\n'
                          '- Assume Responsibility for Booking Services: When booking a cook through the app, users are responsible for verifying the safety and suitability of the chosen cook. paMEALya does not guarantee or assume liability for the services provided by individual cooks.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Limitation of Liability
                        Text(
                          'Limitation of Liability',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'paMEALya is provided on an "as is" basis without any warranties, either express or implied. paMEALya disclaims all liability for any damages, direct or indirect, arising from the use of the app, including but not limited to dietary health outcomes, issues with booking cooks, or technical issues within the app. Users agree to use the app at their own risk.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Privacy Policy
                        Text(
                          'Privacy Policy',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'At paMEALya, we respect your privacy and are committed to protecting your personal information. This Privacy Policy outlines what information we collect, how we use it, and your rights regarding your data.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Information We Collect
                        Text(
                          'Information We Collect',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We collect and process various types of personal information to provide personalized meal planning and connect users with local cooks. This includes:\n'
                          '- Profile Information: Personal details such as name, age, gender, health data, and dietary preferences to create tailored meal plans.\n'
                          '- Booking Data: Information related to cook bookings, including your location (for finding nearby cooks) and contact details.\n'
                          '- Device Information: Technical information about the device you use to access paMEALya, such as IP address, operating system, and device type, to improve app performance and troubleshoot technical issues.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // How We Use Your Information
                        Text(
                          'How We Use Your Information',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'The information we collect is used for the following purposes:\n'
                          '- Personalized Meal Planning: Health and dietary data allow us to generate meal plans suited to your needs, including ingredients, recipes, and portion sizes.\n'
                          '- Facilitating Cook Bookings: Personal details are shared with cooks when you book their services through the app to confirm availability and coordinate details.\n'
                          '- Improving the App: Device and usage data help us enhance app functionality, optimize performance, and provide a seamless user experience.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Data Sharing and Disclosure
                        Text(
                          'Data Sharing and Disclosure',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '- Service Providers: We may share your data with third-party service providers who support our app, such as hosting services or payment processors, solely for the purpose of providing our services.\n'
                          '- Cooks: When you book a cook, relevant booking details are shared with them to ensure a smooth transaction and proper meal preparation.\n'
                          '- Legal Compliance: We may disclose your information if required by law or to protect the rights, property, or safety of paMEALya, its users, or the public.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Data Security
                        Text(
                          'Data Security',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We take your privacy seriously and use various security measures, including encryption, secure servers, and access controls, to protect your personal information. However, please note that no method of electronic transmission or storage is 100% secure, and we cannot guarantee absolute security.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Your Rights
                        Text(
                          'Your Rights',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You have the following rights regarding your personal data:\n'
                          '- Access and Update: You can view and update your profile information within the app.\n'
                          '- Data Portability: You can request a copy of your data in a portable format.\n'
                          '- Request Deletion: You may request deletion of your personal data, subject to any legal obligations to retain certain information.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Cookies and Tracking Technologies
                        Text(
                          'Cookies and Tracking Technologies',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'paMEALya uses cookies and similar tracking technologies to improve your user experience, analyze usage patterns, and personalize content. You can control cookie settings through your browser, although disabling cookies may impact certain app features.',
                          textAlign: TextAlign.justify,
                        ),
                        const SizedBox(height: 16),

                        // Changes to the Privacy Policy
                        Text(
                          'Changes to the Privacy Policy',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'We may update this Privacy Policy periodically. Changes will be posted on this page, and users are encouraged to review the policy regularly. Continued use of paMEALya after changes have been posted constitutes acceptance of the updated policy.',
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
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

                          // Terms and Conditions Checkbox with clickable text
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
                                GestureDetector(
                                  onTap: () => _showTermsDialog(context),
                                  child: const Text(
                                    'I agree to the Terms and Conditions and Privacy Policy',
                                    style: TextStyle(
                                      color: Colors
                                          .blue, // Make it look like a link
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

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
