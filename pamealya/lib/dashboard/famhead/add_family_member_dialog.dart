import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  final Function(Map<String, String>) onAdd;

  const AddFamilyMemberDialog({Key? key, required this.onAdd})
      : super(key: key);

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
    'Vegetarian',
    'Gluten-Free',
    'Dairy-Free',
    'Nut-Free',
  ];

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
              // TextFormField controllers and DropdownButtonFormFields
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
