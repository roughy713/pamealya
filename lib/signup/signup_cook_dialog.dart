import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import '../home_page.dart';
import 'address_fields.dart';

class SignUpCookDialog extends StatefulWidget {
  const SignUpCookDialog({super.key});

  @override
  SignUpCookDialogState createState() => SignUpCookDialogState();
}

class SignUpCookDialogState extends State<SignUpCookDialog> {
  final formKey = GlobalKey<FormState>();

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

  // Form Controllers
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  // Dropdown and State Values
  String? _selectedGender;
  DateTime? dateOfBirth;
  String? _selectedProvince;
  String? _selectedCity;
  String? _selectedBarangay;
  String? _postalCode;
  List<String> availabilityDays = [];
  TimeOfDay? timeFrom;
  TimeOfDay? timeTo;
  String? certificationUrl;
  String? uploadedFileName;
  bool _isChecked = false;

  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final Map<String, bool> daySelection = {
    'Monday': false,
    'Tuesday': false,
    'Wednesday': false,
    'Thursday': false,
    'Friday': false,
    'Saturday': false,
    'Sunday': false,
  };

  @override
  void dispose() {
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    ageController.dispose();
    phoneController.dispose();
    locationController.dispose();
    dateOfBirthController.dispose();
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
        dateOfBirth = picked;
        dateOfBirthController.text = DateFormat('dd-MM-yyyy').format(picked);

        // Calculate age
        final today = DateTime.now();
        int age = today.year - picked.year;
        if (today.month < picked.month ||
            (today.month == picked.month && today.day < picked.day)) {
          age--;
        }
        ageController.text = age.toString();
      });
    }
  }

  Future<void> selectTime(BuildContext context, bool isFrom) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          timeFrom = picked;
        } else {
          timeTo = picked;
        }
      });
    }
  }

  Future<void> uploadFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      withData: true,
    );

    if (result != null) {
      Uint8List? fileBytes = result.files.first.bytes;
      String fileName = result.files.first.name;

      setState(() {
        uploadedFileName = fileName;
      });

      if (fileBytes != null) {
        try {
          final filePath = 'cooks certifications/$fileName';
          final response = await Supabase.instance.client.storage
              .from('certifications')
              .uploadBinary(filePath, fileBytes);

          if (response.isNotEmpty) {
            final urlResponse = Supabase.instance.client.storage
                .from('certifications')
                .getPublicUrl(filePath);

            setState(() {
              certificationUrl = urlResponse;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('File uploaded successfully!')),
            );
          }
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('File upload failed: $e')),
          );
        }
      }
    }
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (!RegExp(_passwordPattern).hasMatch(value)) {
      return 'Password must meet all requirements';
    }
    return null;
  }

  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Sign Up Successful'),
          content: const Text(
            'Your account has been created successfully. Please wait for the admin to confirm your account.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const HomePage(),
                  ),
                );
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTermsDialog(BuildContext context) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.privacy_tip, color: Colors.green[700]),
              const SizedBox(width: 10),
              const Text('paMEALya Terms and Conditions'),
            ],
          ),
          content: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.height * 0.7,
            child: SingleChildScrollView(
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
                        '• Nutritionists for dietary assessments\n'
                        '• Cooks for meal preparation services\n'
                        '• Research institutions for improving food security and nutrition insights',
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'By accepting these terms, you acknowledge that you have read, understood, and agree to the collection and processing of your personal information as outlined above.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
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
        ),
      ],
    );
  }

  Future<void> handleFormSubmission() async {
    if (formKey.currentState?.validate() == true && _isChecked) {
      try {
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: emailController.text,
          password: passwordController.text,
          data: {'user_type': 'cook'},
        );

        if (authResponse.user != null) {
          final userId = authResponse.user!.id;

          final insertData = {
            'user_id': userId,
            'first_name': firstNameController.text,
            'last_name': lastNameController.text,
            'age': int.tryParse(ageController.text),
            'gender': _selectedGender,
            'dateofbirth': dateOfBirth != null
                ? DateFormat('yyyy-MM-dd').format(dateOfBirth!)
                : null,
            'phone': phoneController.text,
            'address_line1': locationController.text,
            'province': _selectedProvince,
            'city': _selectedCity,
            'barangay': _selectedBarangay,
            'postal_code': _postalCode,
            'availability_days': availabilityDays.join(','),
            'time_available_from': timeFrom?.format(context),
            'time_available_to': timeTo?.format(context),
            'certifications': certificationUrl ?? '',
            'is_accepted': false,
          };

          await Supabase.instance.client.from('Local_Cook').insert(insertData);
          await _showSuccessDialog();
        } else {
          throw Exception('User registration failed in Supabase Auth.');
        }
      } catch (e) {
        debugPrint('Error during sign-up: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error during sign-up: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please agree to the Terms and Conditions'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.5,
        height: MediaQuery.of(context).size.height * 0.9,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              Center(
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
                      style:
                          TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 20),
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      child:
                          Icon(Icons.person, size: 50, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 20),
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: firstNameController,
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
                                  controller: lastNameController,
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
                          TextFormField(
                            controller: emailController,
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
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: _validatePasswordRealTime,
                            validator: _validatePassword,
                          ),
                          ValueListenableBuilder<Map<String, bool>>(
                            valueListenable: _passwordRequirements,
                            builder: (context, value, child) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildRequirementRow('At least 8 characters',
                                      value['length']!),
                                  _buildRequirementRow('One uppercase letter',
                                      value['uppercase']!),
                                  _buildRequirementRow('One lowercase letter',
                                      value['lowercase']!),
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
                            controller: confirmPasswordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) {
                                return 'Please confirm your password';
                              }
                              if (value != passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: ageController,
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
                                  items:
                                      ['Male', 'Female'].map((String gender) {
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
                            controller: dateOfBirthController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                              suffixIcon: Icon(Icons.calendar_today),
                            ),
                            onTap: () => _selectDate(context),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: phoneController,
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
                            onAddressChange: (address, province, city, barangay,
                                postalCode) {
                              setState(() {
                                locationController.text = address;
                                _selectedProvince = province;
                                _selectedCity = city;
                                _selectedBarangay = barangay;
                                _postalCode = postalCode;
                              });
                            },
                            required: true,
                          ),
                          const SizedBox(height: 20),

                          const Text(
                            'Availability Days:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Wrap(
                            spacing: 8.0,
                            children: daysOfWeek.map((day) {
                              return ChoiceChip(
                                label: Text(day),
                                selected: daySelection[day] ?? false,
                                onSelected: (selected) {
                                  setState(() {
                                    daySelection[day] = selected;
                                    if (selected) {
                                      availabilityDays.add(day);
                                    } else {
                                      availabilityDays.remove(day);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Available From',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () => selectTime(context, true),
                                  controller: TextEditingController(
                                    text: timeFrom != null
                                        ? timeFrom!.format(context)
                                        : '',
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  decoration: const InputDecoration(
                                    labelText: 'Available To',
                                    border: OutlineInputBorder(),
                                  ),
                                  readOnly: true,
                                  onTap: () => selectTime(context, false),
                                  controller: TextEditingController(
                                    text: timeTo != null
                                        ? timeTo!.format(context)
                                        : '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload Certification and Licenses',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: uploadFile,
                                    child: const Text('Upload File'),
                                  ),
                                  const SizedBox(width: 20),
                                  if (uploadedFileName != null)
                                    Text(
                                      uploadedFileName!,
                                      style: const TextStyle(
                                          color: Colors.black87),
                                    ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Checkbox(
                                value: _isChecked,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _isChecked = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _showTermsDialog(context),
                                  child: const Text(
                                    'I agree to the Terms and Conditions and Privacy Policy',
                                    style: TextStyle(
                                      color: Colors.blue,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton(
                              onPressed: handleFormSubmission,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16.0,
                                  horizontal: 32.0,
                                ),
                              ),
                              child: const Text('Submit'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
