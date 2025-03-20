import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pamealya/dashboard/admin/admin_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../dashboard/famhead/famhead_dashboard.dart';
import 'address_fields.dart';

class SignUpFormDialog extends StatefulWidget {
  const SignUpFormDialog({super.key});

  @override
  SignUpFormDialogState createState() => SignUpFormDialogState();
}

class SignUpFormDialogState extends State<SignUpFormDialog> {
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers for form fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // Dropdown values
  String? _selectedGender;
  String? _selectedReligion;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  String? _postalCode;
  bool _isChecked = false;

  // Password validation
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

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _ageController.dispose();
    _dobController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

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

  void _validatePasswordRealTime(String value) {
    _passwordRequirements.value = {
      'length': value.length >= 8,
      'uppercase': RegExp(r'[A-Z]').hasMatch(value),
      'lowercase': RegExp(r'[a-z]').hasMatch(value),
      'number': RegExp(r'\d').hasMatch(value),
      'specialChar': RegExp(r'[@$!%*?&]').hasMatch(value),
    };
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
        _dobController.text = DateFormat('dd-MM-yyyy').format(picked);

        // Calculate age
        final today = DateTime.now();
        int age = today.year - picked.year;
        if (today.month < picked.month ||
            (today.month == picked.month && today.day < picked.day)) {
          age--;
        }
        _ageController.text = age.toString();
      });
    }
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.all(16.0),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: MediaQuery.of(context).size.height * 0.9,
            child: Column(
              children: [
                AppBar(
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  automaticallyImplyLeading: false,
                  title: Row(
                    children: [
                      Icon(Icons.privacy_tip, color: Colors.green[700]),
                      const SizedBox(width: 10),
                      const Text(
                        'paMEALya Terms and Conditions',
                        style: TextStyle(color: Colors.black),
                      ),
                    ],
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: const Icon(Icons.close,
                            color: Colors.black, size: 20),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Data Privacy and Security',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'paMEALya is committed to protecting your personal information in compliance with Republic Act 10173, also known as the Data Privacy Act of 2012. By using our platform, you agree to the following policies:',
                            style: TextStyle(fontSize: 14),
                            textAlign: TextAlign.justify,
                          ),
                          const SizedBox(height: 20),
                          _buildTermsSection(
                            'Collection of Personal Information',
                            'We collect and process your personal data to enhance your experience, including:\n'
                                '• Name and contact details\n'
                                '• Age, dietary preferences, and restrictions\n'
                                '• Family member details for personalized meal planning\n'
                                '• Location data for cook booking services',
                          ),
                          _buildTermsSection(
                            'Purpose of Data Collection',
                            'Your information will be used to:\n'
                                '• Generate personalized meal plans based on nutritional needs\n'
                                '• Facilitate cook bookings and meal transactions\n'
                                '• Improve user experience through tailored recommendations\n'
                                '• Ensure compliance with dietary and health standards',
                          ),
                          _buildTermsSection(
                            'Data Protection Measures',
                            'paMEALya employs strict security protocols to prevent:\n'
                                '• Unauthorized access to personal data\n'
                                '• Data breaches or leaks\n'
                                '• Misuse of sensitive information',
                          ),
                          _buildTermsSection(
                            'User Rights',
                            'Under the Data Privacy Act, you have the right to:\n'
                                '• Access and update your personal data\n'
                                '• Request deletion or restriction of your information\n'
                                '• Withdraw consent for data processing\n'
                                '• Report concerns about data handling practices',
                          ),
                          _buildTermsSection(
                            'Data Retention Policy',
                            'Your data will be retained only for as long as necessary to:\n'
                                '• Provide personalized meal planning services\n'
                                '• Maintain legal and financial records\n'
                                '• Improve system functionality based on anonymized usage data',
                          ),
                          _buildTermsSection(
                              'Third-Party Sharing',
                              'We may share anonymized data with:\n'
                                  '• Cooks for meal preparation services\n'),
                          const SizedBox(height: 20),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green.shade100),
                            ),
                            child: const Text(
                              'By accepting these terms, you acknowledge that you have read, understood, and agree to the collection and processing of your personal information as outlined above.',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.justify,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTermsSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          content,
          style: const TextStyle(fontSize: 14),
          textAlign: TextAlign.justify,
        ),
      ],
    );
  }

// Add this method to show validation errors
  Future<void> _showValidationDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.yellow[700]),
              const SizedBox(width: 8),
              const Text('Signup Failed'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

// Add this method to show error messages
  Future<void> _showErrorDialog(String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              SizedBox(width: 8),
              Text('Error'),
            ],
          ),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleSignUp() async {
    if (!_formKey.currentState!.validate() || !_isChecked) {
      await _showValidationDialog(
        'Please check all fields and agree to Terms and Conditions',
      );
      return;
    }

    try {
      // Create user in Supabase Auth
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text,
        password: _passwordController.text,
        data: {'user_type': 'family_head'},
      );

      if (authResponse.user != null) {
        final userId = authResponse.user!.id;
        final familyHeadName =
            '${_firstNameController.text} ${_lastNameController.text}';

        // Check for existing family heads with same name
        final existingFamilyHeads = await Supabase.instance.client
            .from('familymember')
            .select('family_head')
            .eq('family_head', familyHeadName);

        String uniqueFamilyHeadName = familyHeadName;
        if (existingFamilyHeads.isNotEmpty) {
          uniqueFamilyHeadName =
              '$familyHeadName (${existingFamilyHeads.length + 1})';
        }

        // Prepare data for insertion
        final data = {
          'first_name': _firstNameController.text,
          'last_name': _lastNameController.text,
          'age': int.tryParse(_ageController.text),
          'gender': _selectedGender,
          'dob': _dobController.text,
          'position': 'Family Head',
          'family_head': uniqueFamilyHeadName,
          'religion': _selectedReligion ?? 'N/A',
          'user_id': userId,
          'address_line1': _addressController.text,
          'province': _selectedProvince,
          'city': _selectedCity,
          'barangay': _selectedBarangay,
          'postal_code': _postalCode,
          'phone': int.tryParse(_phoneController.text),
          'is_family_head': true,
          'is_halal': false,
        };

        // Insert into familymember table
        final insertResponse = await Supabase.instance.client
            .from('familymember')
            .insert(data)
            .select();

        if (insertResponse.isNotEmpty) {
          // Notify admins about family head registration
          try {
            final adminNotificationService = AdminNotificationService(
              supabase: Supabase.instance.client,
            );

            await adminNotificationService.notifyFamilyHeadRegistration(
                userId, uniqueFamilyHeadName);
          } catch (notificationError) {}

          // Show success and proceed to dashboard
          await _showSuccessDialog();
          if (mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => FamHeadDashboard(
                  firstName: _firstNameController.text,
                  lastName: _lastNameController.text,
                  currentUserUsername: _emailController.text,
                  currentUserId: userId,
                ),
              ),
            );
          }
        }
      }
    } catch (e) {
      await _showErrorDialog('Error during sign-up: $e');
    }
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
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
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.black),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
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
                            fontSize: 16, fontStyle: FontStyle.italic),
                      ),
                      const SizedBox(height: 20),

                      // Personal Information Section
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'First Name',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter your first name'
                                  : null,
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
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter your last name'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Contact Information
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter your email'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: const OutlineInputBorder(),
                          helperText:
                              'Must contain: 8+ characters, uppercase, lowercase, number, special character (@\$!%*?&)',
                          helperMaxLines: 2,
                          helperStyle: const TextStyle(fontSize: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                        onChanged: _validatePasswordRealTime,
                        validator: (value) {
                          if (value?.isEmpty ?? true) {
                            return 'Please enter your password';
                          } else if (!_passwordRequirements.value
                              .containsValue(true)) {
                            return 'Password does not meet requirements';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),

                      // Confirm Password - FIXED with proper spacing and padding
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_confirmPasswordVisible,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          border: const OutlineInputBorder(),
                          // Set explicit content padding to match other fields
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 16, horizontal: 12),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _confirmPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: Colors.grey,
                            ),
                            onPressed: () {
                              setState(() {
                                _confirmPasswordVisible =
                                    !_confirmPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value?.isEmpty ?? true) return 'Required';
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(
                          height:
                              10), // Ensure proper spacing after confirm password field

                      // Personal Details
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _ageController,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                                border: OutlineInputBorder(),
                              ),
                              readOnly: true,
                              validator: (value) => value?.isEmpty ?? true
                                  ? 'Please enter your age'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedGender,
                              items: ['Male', 'Female'].map((String gender) {
                                return DropdownMenuItem<String>(
                                  value: gender,
                                  child: Text(gender),
                                );
                              }).toList(),
                              onChanged: (String? value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                              validator: (value) =>
                                  value == null ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        onTap: () => _selectDate(context),
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please select your date of birth'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // Phone Number
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty ?? true
                            ? 'Please enter your phone number'
                            : null,
                      ),
                      const SizedBox(height: 10),

                      // Address Fields Section
                      AddressFields(
                        onAddressChange:
                            (address, province, city, barangay, postalCode) {
                          setState(() {
                            _addressController.text = address;
                            _selectedProvince = province;
                            _selectedCity = city;
                            _selectedBarangay = barangay;
                            _postalCode = postalCode;
                          });
                        },
                        required: true,
                      ),
                      const SizedBox(height: 20),

                      // Terms and Conditions Checkbox
                      Row(
                        children: [
                          Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: Colors.grey[600],
                              // This ensures checkbox hover matches terms text hover
                              hoverColor: Colors.green[50],
                            ),
                            child: Checkbox(
                              value: _isChecked,
                              onChanged: (bool? value) {
                                setState(() {
                                  _isChecked = value ?? false;
                                });
                              },
                            ),
                          ),
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _showTermsDialog(context),
                                child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 4.0),
                                  decoration: const BoxDecoration(
                                    // This creates hover effect area
                                    color: Colors.transparent,
                                  ),
                                  child: const Text(
                                    'I agree to the Terms and Conditions and Privacy Policy',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _handleSignUp,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.yellow[700],
                          padding: const EdgeInsets.symmetric(
                            horizontal: 60,
                            vertical: 15,
                          ),
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
