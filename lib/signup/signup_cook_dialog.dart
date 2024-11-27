import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:typed_data';
import 'package:uuid/uuid.dart';
import '../home_page.dart'; // Import the HomePage for redirection after success

class SignUpCookDialog extends StatefulWidget {
  const SignUpCookDialog({super.key});

  @override
  SignUpCookDialogState createState() => SignUpCookDialogState();
}

class SignUpCookDialogState extends State<SignUpCookDialog> {
  final formKey = GlobalKey<FormState>();

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
  final TextEditingController barangayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();
  final TextEditingController dateOfBirthController = TextEditingController();

  String? _selectedGender;
  DateTime? dateOfBirth;
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

  // Select a date
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != dateOfBirth) {
      setState(() {
        dateOfBirth = picked;
        dateOfBirthController.text = DateFormat('MM-dd-yyyy').format(picked);
      });
    }
  }

  // Select a time
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

  // File upload function
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

  // Show success dialog
  Future<void> _showSuccessDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
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
                Navigator.of(context).pop(); // Close dialog
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

  // Show terms and conditions dialog
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

  // Handle form submission
  Future<void> handleFormSubmission() async {
    if (formKey.currentState?.validate() == true && _isChecked) {
      try {
        // Step 1: Create user in Supabase Auth
        final authResponse = await Supabase.instance.client.auth.signUp(
          email: emailController.text,
          password: passwordController.text,
          data: {'user_type': 'cook'}, // Metadata for the user
        );

        if (authResponse.user != null) {
          // Step 2: Insert details into the Local_Cook table
          final userId =
              authResponse.user!.id; // Retrieve the user's ID from Auth

          // Prepare data for the table
          final insertData = {
            'user_id': userId, // Link to Supabase Auth user ID
            'first_name': firstNameController.text,
            'last_name': lastNameController.text,
            'age': int.tryParse(ageController.text),
            'gender': _selectedGender,
            'dateofbirth': dateOfBirth != null
                ? DateFormat('yyyy-MM-dd').format(dateOfBirth!)
                : null,
            'phone': phoneController.text,
            'address_line1': locationController.text,
            'barangay': barangayController.text,
            'city': cityController.text,
            'province': provinceController.text,
            'postal_code': int.tryParse(postalCodeController.text),
            'availability_days': availabilityDays.join(','), // Join as a string
            'time_available_from': timeFrom?.format(context),
            'time_available_to': timeTo?.format(context),
            'certifications': certificationUrl ?? '',
            'is_accepted': false, // Default value
          };

          await Supabase.instance.client.from('Local_Cook').insert(insertData);

          // Show success dialog
          await _showSuccessDialog();
        } else {
          // Handle if auth signup failed
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
            content: Text('Please agree to the Terms and Conditions')),
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
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your first name';
                                    }
                                    return null;
                                  },
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your last name';
                                    }
                                    return null;
                                  },
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
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: passwordController,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
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
                              if (value == null || value.isEmpty) {
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
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please enter your age';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'Male',
                                      child: Text('Male'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Female',
                                      child: Text('Female'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'Other',
                                      child: Text('Other'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value;
                                    });
                                  },
                                  validator: (value) {
                                    if (value == null) {
                                      return 'Please select your gender';
                                    }
                                    return null;
                                  },
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
                            ),
                            onTap: () => selectDate(context),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: locationController,
                            decoration: const InputDecoration(
                              labelText: 'Address Line 1',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: barangayController,
                            decoration: const InputDecoration(
                              labelText: 'Barangay',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your barangay';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: cityController,
                            decoration: const InputDecoration(
                              labelText: 'City',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your city';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: provinceController,
                            decoration: const InputDecoration(
                              labelText: 'Province',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your province';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: postalCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Postal Code',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your postal code';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
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
                          // Submit Button
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
