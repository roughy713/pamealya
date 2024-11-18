import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  final Function(Map<String, String>) onAdd;

  const AddFamilyMemberDialog({super.key, required this.onAdd});

  @override
  AddFamilyMemberDialogState createState() => AddFamilyMemberDialogState();
}

class AddFamilyMemberDialogState extends State<AddFamilyMemberDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  String? _selectedPosition;
  String? _selectedGender;
  String? _selectedDietaryRestriction;

  final List<String> _positions = ['Father', 'Mother', 'Son', 'Daughter'];
  final List<String> _dietaryRestrictions = [
    'None',
    'Halal',
    'Seafoods',
    'Nuts',
    'Milk'
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Family Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the first name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the last name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the age';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select the date of birth';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genders.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                items: _positions.map((position) {
                  return DropdownMenuItem(
                      value: position, child: Text(position));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPosition = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedDietaryRestriction,
                items: _dietaryRestrictions.map((restriction) {
                  return DropdownMenuItem(
                      value: restriction, child: Text(restriction));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDietaryRestriction = value;
                  });
                },
                decoration:
                    const InputDecoration(labelText: 'Dietary Restriction'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              widget.onAdd({
                'firstName': _firstNameController.text,
                'lastName': _lastNameController.text,
                'age': _ageController.text,
                'gender': _selectedGender ?? '',
                'dob': _dateOfBirthController.text,
                'position': _selectedPosition ?? '',
                'dietaryRestriction': _selectedDietaryRestriction ?? 'None',
              });
              Navigator.of(context).pop();
            }
          },
          child: const Text('Submit'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
