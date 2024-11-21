import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFamilyMemberDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onAdd;

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
  final TextEditingController _religionController = TextEditingController();
  String? _selectedGender;
  String? _selectedPosition;

  bool _seafoodAllergy = false;
  bool _nutsAllergy = false;
  bool _dairyAllergy = false;

  final List<String> _genders = ['Male', 'Female'];
  final List<String> _positions = ['Father', 'Mother', 'Son', 'Daughter'];

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  Future<int> saveToSupabase(Map<String, dynamic> memberData) async {
    final supabase = Supabase.instance.client;

    try {
      final response = await supabase
          .from('familymember')
          .insert({
            'first_name': memberData['first_name'],
            'last_name': memberData['last_name'],
            'age': memberData['age'],
            'dob': memberData['dob'],
            'religion': memberData['religion'],
            'gender': memberData['gender'],
            'position': memberData['position'],
          })
          .select('id')
          .single();
      return response['id']; // Returns the ID of the new family member
    } catch (e) {
      print('Error saving family member: $e');
      throw Exception('Failed to save family member');
    }
  }

  Future<void> saveAllergens(int familyMemberId) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('familymember_allergens').upsert({
        'familymember_id': familyMemberId,
        'is_seafood': _seafoodAllergy,
        'is_nuts': _nutsAllergy,
        'is_dairy': _dairyAllergy,
      });
      print('Allergens saved successfully.');
    } catch (e) {
      print('Error saving allergens: $e');
      throw Exception('Failed to save allergens');
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
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter first name' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter last name' : null,
              ),
              TextFormField(
                controller: _ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter age' : null,
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
              TextFormField(
                controller: _religionController,
                decoration: const InputDecoration(labelText: 'Religion'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: _genders.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) => setState(() {
                  _selectedGender = value;
                }),
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: _selectedPosition,
                items: _positions.map((position) {
                  return DropdownMenuItem(
                      value: position, child: Text(position));
                }).toList(),
                onChanged: (value) => setState(() {
                  _selectedPosition = value;
                }),
                decoration: const InputDecoration(labelText: 'Position'),
              ),
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
      actions: [
        ElevatedButton(
          onPressed: () async {
            if (_formKey.currentState?.validate() ?? false) {
              final newMember = {
                'first_name': _firstNameController.text,
                'last_name': _lastNameController.text,
                'age': int.tryParse(_ageController.text) ?? 0,
                'dob': _dateOfBirthController.text,
                'religion': _religionController.text,
                'gender': _selectedGender,
                'position': _selectedPosition,
              };

              try {
                final familyMemberId = await saveToSupabase(newMember);
                await saveAllergens(familyMemberId);
                widget.onAdd(newMember);
                Navigator.of(context).pop();
              } catch (e) {
                print('Error: $e');
              }
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
