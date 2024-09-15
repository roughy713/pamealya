import 'package:flutter/material.dart';

class SignUpCookDialog extends StatefulWidget {
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
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  final TextEditingController barangayController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController provinceController = TextEditingController();
  final TextEditingController postalCodeController = TextEditingController();

  // Removed controllers for specialties, experience, and introduction

  String gender = 'Male';
  DateTime? dateOfBirth;
  List<String> availabilityDays = [];
  TimeOfDay? timeFrom;
  TimeOfDay? timeTo;
  bool agreeToTerms = false;

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

  void uploadFile() {
    // Implement file upload logic here
    // This can be a file picker dialog or any other file upload functionality
    print('Upload Certification and Licenses button pressed');
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
        width: MediaQuery.of(context).size.width * 0.5, // 50% of screen width
        height:
            MediaQuery.of(context).size.height * 0.9, // 90% of screen height
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                ),
              ),
              Center(
                child: Column(
                  children: [
                    // Logo
                    Image.asset(
                      'assets/logo-dark.png',
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
                        // Handle profile picture upload
                      },
                      child: const Text('Upload Profile Picture'),
                    ),
                    const SizedBox(height: 20),

                    // Form
                    Form(
                      key: formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // First Name and Last Name
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

                          // Email and Username
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
                            controller: usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your username';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Password and Confirm Password
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
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Age, Gender, and Date of Birth
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
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
                                  value: gender,
                                  decoration: const InputDecoration(
                                    labelText: 'Gender',
                                    border: OutlineInputBorder(),
                                  ),
                                  items: ['Male', 'Female', 'Other']
                                      .map((gender) => DropdownMenuItem<String>(
                                            value: gender,
                                            child: Text(gender),
                                          ))
                                      .toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      gender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Date of Birth
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Date of Birth',
                              border: OutlineInputBorder(),
                            ),
                            readOnly: true,
                            onTap: () => selectDate(context),
                            validator: (value) {
                              if (dateOfBirth == null) {
                                return 'Please select your date of birth';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Phone Number
                          TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),

                          // Address Fields
                          TextFormField(
                            controller: locationController,
                            decoration: const InputDecoration(
                                labelText: 'Address Line 1'),
                          ),
                          TextFormField(
                            controller: barangayController,
                            decoration:
                                const InputDecoration(labelText: 'Barangay'),
                          ),
                          TextFormField(
                            controller: cityController,
                            decoration:
                                const InputDecoration(labelText: 'City'),
                          ),
                          TextFormField(
                            controller: provinceController,
                            decoration:
                                const InputDecoration(labelText: 'Province'),
                          ),
                          TextFormField(
                            controller: postalCodeController,
                            decoration:
                                const InputDecoration(labelText: 'Postal Code'),
                          ),
                          const SizedBox(height: 10),

                          // Availability Days
                          const Text('Availability Days:',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          ...daysOfWeek.map((day) {
                            return CheckboxListTile(
                              title: Text(day),
                              value: daySelection[day],
                              onChanged: (bool? value) {
                                setState(() {
                                  daySelection[day] = value!;
                                  availabilityDays = daysOfWeek
                                      .where((d) => daySelection[d] == true)
                                      .toList();
                                });
                              },
                            );
                          }).toList(),
                          const SizedBox(height: 10),

                          // Available From and Available To
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
                                        ? '${timeFrom!.format(context)}'
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
                                        ? '${timeTo!.format(context)}'
                                        : '',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Upload Certification and Licenses
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Upload Certification and Licenses',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: uploadFile,
                                child: const Text('Upload File'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // Terms and Conditions Checkbox
                          Row(
                            children: [
                              Checkbox(
                                value: agreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    agreeToTerms = value!;
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
                          const SizedBox(height: 10),

                          // Sign Up Button
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                if (formKey.currentState?.validate() == true) {
                                  // Handle form submission
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.yellow[700],
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 15),
                              ),
                              child: const Text('Sign Up'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Footer Text
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 10),
                      child: Text(
                        'All Rights Reserved\nFOOTER',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
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
