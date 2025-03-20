import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'famhead_notification_service.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;
  final String familyHeadName;

  const AddFamilyMemberDialog({
    super.key,
    required this.onAdd,
    required this.familyHeadName,
  });

  @override
  AddFamilyMemberDialogState createState() => AddFamilyMemberDialogState();
}

class AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _religionController = TextEditingController();
  String? _selectedGender;
  String? _selectedPosition;
  String? _selectedCondition;

  bool _seafoodAllergy = false;
  bool _nutsAllergy = false;
  bool _dairyAllergy = false;

  bool _isSaving = false;

  Future<void> _saveFamilyMember() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
    });

    final supabase = Supabase.instance.client;

    try {
      final newMember = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'dob': _dateOfBirthController.text.trim(),
        'religion': _religionController.text.trim(),
        'gender': _selectedGender,
        'position': _selectedPosition,
        'is_family_head': false,
        'family_head': widget.familyHeadName,
      };

      final response = await supabase
          .from('familymember')
          .insert(newMember)
          .select('familymember_id')
          .single();

      final familyMemberId = response['familymember_id'];

      await supabase.from('familymember_allergens').upsert({
        'familymember_id': familyMemberId,
        'is_seafood': _seafoodAllergy,
        'is_nuts': _nutsAllergy,
        'is_dairy': _dairyAllergy,
      });

      await supabase.from('familymember_specialconditions').upsert({
        'familymember_id': familyMemberId,
        'is_pregnant': _selectedCondition == 'Pregnant',
        'is_lactating': _selectedCondition == 'Lactating',
        'is_none': _selectedCondition == 'None',
      });

      // Send notification to admins
      final userId = supabase.auth.currentUser?.id;
      if (userId != null) {
        final notificationService =
            FamilyHeadNotificationService(supabase: supabase);
        final memberName =
            '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}';
        await notificationService.notifyFamilyMemberAdded(
            userId, widget.familyHeadName, memberName);
      }

      widget.onAdd(newMember);
      Navigator.of(context).pop();
      _showSuccessDialog('Family member added successfully!');
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) => AlertDialog(
            title: const Text('Error'),
            content: Text('An error occurred: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ]),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _showSuccessDialog(String message) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
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
        _dateOfBirthController.text =
            "${picked.month}/${picked.day}/${picked.year}";

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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 500,
        height: 500,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Family Member',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration:
                            const InputDecoration(labelText: 'First Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter first name'
                            : null,
                      ),
                      TextFormField(
                        controller: _lastNameController,
                        decoration:
                            const InputDecoration(labelText: 'Last Name'),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter last name'
                            : null,
                      ),
                      TextFormField(
                        controller: _dateOfBirthController,
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          suffixIcon: Icon(Icons.calendar_today),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Enter date of birth'
                            : null,
                        onTap: () => _selectDate(context),
                        readOnly: true,
                      ),
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(labelText: 'Age'),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value == null || value.isEmpty ? 'Enter age' : null,
                      ),
                      DropdownButtonFormField<String>(
                        value: _religionController.text.isNotEmpty
                            ? _religionController.text
                            : null,
                        onChanged: (value) {
                          setState(() {
                            _religionController.text = value!;
                          });
                        },
                        validator: (value) => value == null || value.isEmpty
                            ? 'Select religion'
                            : null,
                        items: [
                          'Roman Catholic',
                          'Islam',
                          'Christian',
                          'Saksi ni Jehova',
                          '7th Day Adventist',
                          'Iglesia Ni Cristo',
                          'Mormons',
                        ].map((religion) {
                          return DropdownMenuItem(
                            value: religion,
                            child: Text(religion),
                          );
                        }).toList(),
                        decoration:
                            const InputDecoration(labelText: 'Religion'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedGender,
                        onChanged: (value) => setState(() {
                          _selectedGender = value;
                          // Reset special condition when switching to male
                          if (value == 'Male') {
                            _selectedCondition = 'None';
                          }
                        }),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Select gender'
                            : null,
                        items: ['Male', 'Female']
                            .map((gender) => DropdownMenuItem(
                                  value: gender,
                                  child: Text(gender),
                                ))
                            .toList(),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedPosition,
                        onChanged: (value) => setState(() {
                          _selectedPosition = value;
                        }),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Select position'
                            : null,
                        items: [
                          'Father',
                          'Mother',
                          'Son',
                          'Daughter',
                          'Grandmother',
                          'Grandfather',
                          'Uncle',
                          'Aunt'
                        ].map((position) {
                          return DropdownMenuItem(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        decoration:
                            const InputDecoration(labelText: 'Position'),
                      ),
                      if (_selectedGender == 'Female') // Only show for Female
                        DropdownButtonFormField<String>(
                          value: _selectedCondition,
                          onChanged: (value) {
                            setState(() {
                              _selectedCondition = value;
                            });
                          },
                          items: [
                            'None',
                            'Lactating',
                            'Pregnant',
                          ].map((condition) {
                            return DropdownMenuItem(
                              value: condition,
                              child: Text(condition),
                            );
                          }).toList(),
                          decoration: const InputDecoration(
                              labelText: 'Special Condition'),
                        ),
                      const SizedBox(height: 10),
                      const Text('Allergens'),
                      CheckboxListTile(
                        title: const Text('Seafood'),
                        value: _seafoodAllergy,
                        onChanged: (value) {
                          setState(() {
                            _seafoodAllergy = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Nuts'),
                        value: _nutsAllergy,
                        onChanged: (value) {
                          setState(() {
                            _nutsAllergy = value ?? false;
                          });
                        },
                      ),
                      CheckboxListTile(
                        title: const Text('Dairy'),
                        value: _dairyAllergy,
                        onChanged: (value) {
                          setState(() {
                            _dairyAllergy = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _saveFamilyMember();
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
