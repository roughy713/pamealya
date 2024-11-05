import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class EditFamilyMemberDialog extends StatefulWidget {
  final Map<String, String?> memberData;
  final Function(Map<String, String?>) onEdit;

  const EditFamilyMemberDialog({
    Key? key,
    required this.memberData,
    required this.onEdit,
  }) : super(key: key);

  @override
  _EditFamilyMemberDialogState createState() => _EditFamilyMemberDialogState();
}

class _EditFamilyMemberDialogState extends State<EditFamilyMemberDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dateOfBirthController;
  String? _selectedPosition;
  String? _selectedDietaryRestriction;
  String? _selectedGender;
  DateTime? _dob;

  final List<String> _positions = ['Family Head'];
  final List<String> _dietaryRestrictions = [
    'None',
    'Halal',
    'Seafoods',
    'Nuts',
    'Milk',
  ];
  final List<String> _genders = ['Male', 'Female', 'Other'];

  @override
  void initState() {
    super.initState();
    _firstNameController =
        TextEditingController(text: widget.memberData['firstName']);
    _lastNameController =
        TextEditingController(text: widget.memberData['lastName']);
    _dateOfBirthController =
        TextEditingController(text: widget.memberData['dob'] ?? '');
    _selectedPosition = widget.memberData['position'] ?? 'Family Head';
    _selectedDietaryRestriction = widget.memberData['dietaryRestriction'];
    _selectedGender = widget.memberData['gender'];
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
        _dob = picked;
        _dateOfBirthController.text = DateFormat('MM/dd/yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Family Head'),
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
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genders.map((gender) {
                  return DropdownMenuItem(
                    value: gender,
                    child: Text(gender),
                  );
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
                    value: position,
                    child: Text(position),
                  );
                }).toList(),
                onChanged: null, // Disable changing position for Family Head
                decoration: const InputDecoration(labelText: 'Position'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedDietaryRestriction,
                items: _dietaryRestrictions.map((restriction) {
                  return DropdownMenuItem(
                    value: restriction,
                    child: Text(restriction),
                  );
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
              widget.onEdit({
                'firstName': _firstNameController.text,
                'lastName': _lastNameController.text,
                'dob': _dateOfBirthController.text,
                'gender': _selectedGender,
                'position': _selectedPosition,
                'dietaryRestriction': _selectedDietaryRestriction,
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
