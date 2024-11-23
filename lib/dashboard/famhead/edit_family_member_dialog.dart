import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditFamilyMemberDialog extends StatefulWidget {
  final Map<String, dynamic> memberData;
  final Function(Map<String, dynamic>) onEdit;

  const EditFamilyMemberDialog({
    super.key,
    required this.memberData,
    required this.onEdit,
  });

  @override
  _EditFamilyMemberDialogState createState() => _EditFamilyMemberDialogState();
}

class _EditFamilyMemberDialogState extends State<EditFamilyMemberDialog> {
  late TextEditingController firstNameController;
  late TextEditingController lastNameController;
  late TextEditingController ageController;
  late TextEditingController dobController;
  late TextEditingController religionController;
  String? gender;
  String? position;

  bool seafoodAllergy = false;
  bool nutsAllergy = false;
  bool dairyAllergy = false;

  final List<String> genderOptions = ['Male', 'Female'];
  final List<String> positionOptions = [
    'Family Head',
    'Father',
    'Mother',
    'Son',
    'Daughter'
  ];

  @override
  void initState() {
    super.initState();

    // Initialize text controllers with existing data
    firstNameController =
        TextEditingController(text: widget.memberData['first_name'] ?? '');
    lastNameController =
        TextEditingController(text: widget.memberData['last_name'] ?? '');
    ageController =
        TextEditingController(text: widget.memberData['age']?.toString() ?? '');
    dobController = TextEditingController(text: widget.memberData['dob'] ?? '');
    religionController =
        TextEditingController(text: widget.memberData['religion'] ?? '');
    gender = widget.memberData['gender'];
    position = widget.memberData['position'];

    // Fetch allergen data for the family member
    _fetchAllergens();
  }

  Future<void> _fetchAllergens() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('familymember_allergens')
          .select('is_seafood, is_nuts, is_dairy')
          .eq('familymember_id', widget.memberData['familymember_id'])
          .single();

      setState(() {
        seafoodAllergy = response['is_seafood'] ?? false;
        nutsAllergy = response['is_nuts'] ?? false;
        dairyAllergy = response['is_dairy'] ?? false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching allergens: $e')),
      );
    }
  }

  Future<void> saveAllergens(String familyMemberId) async {
    final supabase = Supabase.instance.client;

    try {
      await supabase.from('familymember_allergens').upsert({
        'familymember_id': familyMemberId,
        'is_seafood': seafoodAllergy,
        'is_nuts': nutsAllergy,
        'is_dairy': dairyAllergy,
      });
    } catch (e) {
      print('Error updating allergens: $e');
      throw Exception('Failed to update allergens');
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

  @override
  Widget build(BuildContext context) {
    final bool isFamilyHead = widget.memberData['position'] == 'Family Head';

    return AlertDialog(
      title: Text(
        isFamilyHead ? "Edit Family Head" : "Edit Family Member",
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Form(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: firstNameController,
                decoration: const InputDecoration(labelText: 'First Name'),
              ),
              TextField(
                controller: lastNameController,
                decoration: const InputDecoration(labelText: 'Last Name'),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: 'Age'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: dobController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(1900),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setState(() {
                      dobController.text =
                          "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
                    });
                  }
                },
              ),
              TextField(
                controller: religionController,
                decoration: const InputDecoration(labelText: 'Religion'),
              ),
              DropdownButtonFormField<String>(
                value: gender,
                items: genderOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    gender = value;
                  });
                },
                decoration: const InputDecoration(labelText: 'Gender'),
              ),
              DropdownButtonFormField<String>(
                value: position,
                items: positionOptions.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: isFamilyHead
                    ? null
                    : (value) {
                        setState(() {
                          position = value;
                        });
                      },
                decoration: InputDecoration(
                  labelText: 'Position',
                  helperText:
                      isFamilyHead ? 'Position cannot be changed.' : null,
                ),
              ),
              const SizedBox(height: 10),
              const Text('Allergens'),
              CheckboxListTile(
                title: const Text('Seafood'),
                value: seafoodAllergy,
                onChanged: (value) {
                  setState(() {
                    seafoodAllergy = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Nuts'),
                value: nutsAllergy,
                onChanged: (value) {
                  setState(() {
                    nutsAllergy = value ?? false;
                  });
                },
              ),
              CheckboxListTile(
                title: const Text('Dairy'),
                value: dairyAllergy,
                onChanged: (value) {
                  setState(() {
                    dairyAllergy = value ?? false;
                  });
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("Cancel"),
        ),
        TextButton(
          onPressed: () async {
            final updatedMember = {
              'first_name': firstNameController.text,
              'last_name': lastNameController.text,
              'age': int.tryParse(ageController.text) ?? 0,
              'dob': dobController.text,
              'religion': religionController.text,
              'gender': gender,
            };

            try {
              await saveAllergens(widget.memberData['familymember_id']);
              widget.onEdit(updatedMember);
              Navigator.pop(context);
              _showSuccessDialog('Family member updated successfully!');
            } catch (e) {
              print('Error: $e');
            }
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
