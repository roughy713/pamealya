import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../dashboard/famhead/famhead_dashboard.dart'; // Import FamHeadDashboard

class SignUpFormDialog extends StatefulWidget {
  const SignUpFormDialog({super.key});

  @override
  SignUpFormDialogState createState() => SignUpFormDialogState();
}

class SignUpFormDialogState extends State<SignUpFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final String _passwordPattern =
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$';
  final ValueNotifier<bool> _isPasswordMatch = ValueNotifier<bool>(true);

  final ValueNotifier<Map<String, bool>> _passwordRequirements = ValueNotifier({
    'length': false,
    'uppercase': false,
    'lowercase': false,
    'number': false,
    'specialChar': false,
  });

  Widget _buildRequirementRow(String text, bool isValid) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: isValid ? Colors.green : Colors.red,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  // Controllers to handle form input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
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

  String? _selectedReligion; // Dropdown for religion
  String? _selectedGender;
  bool _isChecked = false;

  // Allergens
  bool seafoodAllergy = false;
  bool nutsAllergy = false;
  bool dairyAllergy = false;

  // Special conditions
  String? _selectedCondition; // None, Lactating, Pregnant

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    try {
      // Step 1: Create user in Supabase Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {'user_type': 'family_head'},
      );

      if (authResponse.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign-up failed.')),
        );
        return;
      }

      final user = authResponse.user;

      if (user != null) {
        final familyHeadName =
            '${_firstNameController.text} ${_lastNameController.text}';

        // Get existing family heads with the same name
        final existingFamilyHeads = await Supabase.instance.client
            .from('familymember')
            .select('family_head')
            .eq('family_head', familyHeadName);

        // Create a unique family head identifier by appending a number if necessary
        String uniqueFamilyHeadName = familyHeadName;
        if (existingFamilyHeads.length > 0) {
          uniqueFamilyHeadName =
              '$familyHeadName (${existingFamilyHeads.length + 1})';
        }

        final data = {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'age': int.tryParse(_ageController.text),
          'gender': _selectedGender,
          'dob': _dobController.text,
          'position': 'Family Head',
          'family_head':
              uniqueFamilyHeadName, // Use the unique family head name
          'religion': _selectedReligion ?? 'N/A',
          'user_id': user.id,
          'address_line1': _addressLine1Controller.text,
          'barangay': _barangayController.text,
          'city': _cityController.text,
          'province': _provinceController.text,
          'postal_code': int.tryParse(_postalCodeController.text),
          'phone': int.tryParse(_phoneController.text),
          'is_family_head': true,
          'is_halal': false,
        };

        // Insert into the familymember table
        final insertResponse = await Supabase.instance.client
            .from('familymember')
            .insert(data)
            .select();

        if (insertResponse != null && insertResponse.isNotEmpty) {
          final familyMemberId = insertResponse[0]['familymember_id'];

          // Save allergens
          await Supabase.instance.client.from('familymember_allergens').upsert({
            'familymember_id': familyMemberId,
            'is_seafood': seafoodAllergy,
            'is_nuts': nutsAllergy,
            'is_dairy': dairyAllergy,
          });

          // Save special conditions
          await Supabase.instance.client
              .from('familymember_specialconditions')
              .upsert({
            'familymember_id': familyMemberId,
            'is_pregnant': _selectedCondition == 'Pregnant',
            'is_lactating': _selectedCondition == 'Lactating',
            'is_none': _selectedCondition == 'None',
          });

          // Show success dialog
          await _showSuccessDialog(
            onSuccess: () {
              _autoLogin(
                  user.id, _emailController.text, _passwordController.text);
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Insert Error: No data returned')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _validatePasswordRealTime(String value) {
    _passwordRequirements.value = {
      'length': value.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(value),
      'lowercase': RegExp(r'[a-z]').hasMatch(value),
      'number': RegExp(r'\d').hasMatch(value),
      'specialChar': RegExp(r'[@$!%*?&]').hasMatch(value),
    };
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!RegExp(_passwordPattern).hasMatch(value)) {
      return 'Password must include:\n'
          '- At least 8 characters\n'
          '- One uppercase letter\n'
          '- One lowercase letter\n'
          '- One number\n'
          '- One special character';
    }
    return null;
  }

  Future<void> _showSuccessDialog({required VoidCallback onSuccess}) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Account Created'),
          content: const Text(
            'Your account has been created successfully! Click OK to proceed to your dashboard.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.pop(context); // Close the dialog
                onSuccess(); // Trigger the success callback to login
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _autoLogin(String userId, String email, String password) async {
    try {
      final loginResponse =
          await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (loginResponse.user == null) {
        throw Exception('Auto-login failed.');
      }

      final user = loginResponse.user;

      // Fetch the user's details from the familymember table using user_id
      final familyHeadResponse = await Supabase.instance.client
          .from('familymember')
          .select('first_name, last_name')
          .eq('user_id', user!.id) // Use user_id instead of family_head name
          .single();

      final firstName = familyHeadResponse['first_name'];
      final lastName = familyHeadResponse['last_name'];

      // Redirect to the FamHeadDashboard
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => FamHeadDashboard(
            firstName: firstName,
            lastName: lastName,
            currentUserUsername: email,
            currentUserId: user.id, // Pass the user_id to the dashboard
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during auto-login: $e')),
      );
    }
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
                        // Data Privacy Act - Expanded content
                        Text(
                          'Data Privacy Act',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium!
                              .copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'In compliance with the Data Privacy Act of 2012 (Republic Act No. 10173), paMEALya is committed to ensuring that your personal data is handled with the utmost care and security. This law mandates the protection of personal information collected from users to ensure that it is used fairly, lawfully, and transparently. The Data Privacy Act of 2012 outlines the rights of individuals in relation to their personal data, such as the right to access, correct, and request the deletion of data, as well as the requirement for data controllers to implement appropriate security measures to safeguard against unauthorized access, alteration, or destruction of personal information.',
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
                        const SizedBox(height: 16),

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
        // Format date for display
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);

        // Calculate age
        final today = DateTime.now();
        int age = today.year - picked.year;
        // Adjust age if birthday hasn't occurred this year
        if (today.month < picked.month ||
            (today.month == picked.month && today.day < picked.day)) {
          age--;
        }
        // Update age controller
        _ageController.text = age.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(16.0),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                AppBar(elevation: 0),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Image.asset(
                        'assets/logo-dark.png',
                        height: 80,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error);
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
                        onPressed: () {},
                        child: const Text('Upload Profile Picture'),
                      ),
                      const SizedBox(height: 20),
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
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                        ),
                        onChanged:
                            _validatePasswordRealTime, // Real-time validation
                        validator:
                            _validatePassword, // Validation for form submission
                      ),
// Add this after the password TextFormField
                      ValueListenableBuilder<Map<String, bool>>(
                        valueListenable: _passwordRequirements,
                        builder: (context, value, child) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRequirementRow(
                                  'At least 8 characters', value['length']!),
                              _buildRequirementRow(
                                  'One uppercase letter', value['uppercase']!),
                              _buildRequirementRow(
                                  'One lowercase letter', value['lowercase']!),
                              _buildRequirementRow(
                                  'One number', value['number']!),
                              _buildRequirementRow(
                                  'One special character (@\$!%*?&)',
                                  value['specialChar']!),
                            ],
                          );
                        },
                      ),

                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirm Password',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          _isPasswordMatch.value =
                              value == _passwordController.text;
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Confirm Password is required';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      ValueListenableBuilder<bool>(
                        valueListenable: _isPasswordMatch,
                        builder: (context, isMatch, child) {
                          return Row(
                            children: [
                              Icon(
                                isMatch ? Icons.check_circle : Icons.cancel,
                                color: isMatch ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isMatch
                                    ? 'Passwords match'
                                    : 'Passwords do not match',
                                style: TextStyle(
                                  color: isMatch ? Colors.green : Colors.red,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              items: ['Male', 'Female']
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
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Religion',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Roman Catholic',
                          'Islam',
                          'Christian',
                          'Saksi ni Jehova',
                          '7th Day Adventist',
                          'Iglesia Ni Cristo',
                          'Mormons'
                        ].map((religion) {
                          return DropdownMenuItem(
                            value: religion,
                            child: Text(religion),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedReligion = value;
                          });
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a religion';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
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
                      Row(
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
                                color: Colors.blue,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: () {
                          if (_isChecked) {
                            _handleSignUp();
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
