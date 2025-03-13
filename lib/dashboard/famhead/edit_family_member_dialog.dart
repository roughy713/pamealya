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
  String? _selectedCondition;

  bool seafoodAllergy = false;
  bool nutsAllergy = false;
  bool dairyAllergy = false;

  final List<String> genderOptions = ['Male', 'Female'];
  final List<String> positionOptions = [
    'Family Head',
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Grandmother',
    'Grandfather',
    'Uncle',
    'Aunt',
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

    // Fetch allergen and special condition data for the family member
    _fetchAllergens();
    _fetchSpecialCondition();
  }

  Future<void> _fetchAllergens() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('familymember_allergens')
          .select('is_seafood, is_nuts, is_dairy')
          .eq('familymember_id', widget.memberData['familymember_id'])
          .maybeSingle();

      setState(() {
        seafoodAllergy = response?['is_seafood'] ?? false;
        nutsAllergy = response?['is_nuts'] ?? false;
        dairyAllergy = response?['is_dairy'] ?? false;
      });
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to fetch allergens: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          });
    }
  }

  Future<void> _fetchSpecialCondition() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('familymember_specialconditions')
          .select('is_pregnant, is_lactating, is_none')
          .eq('familymember_id', widget.memberData['familymember_id'])
          .maybeSingle();

      if (response != null) {
        setState(() {
          if (response['is_pregnant'] == true) {
            _selectedCondition = 'Pregnant';
          } else if (response['is_lactating'] == true) {
            _selectedCondition = 'Lactating';
          } else {
            _selectedCondition = 'None';
          }
        });
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to fetch special condition: $e'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          });
    }
  }

  Future<void> saveAllergens(String familyMemberId) async {
    try {
      await Supabase.instance.client.from('familymember_allergens').upsert({
        'familymember_id': familyMemberId,
        'is_seafood': seafoodAllergy,
        'is_nuts': nutsAllergy,
        'is_dairy': dairyAllergy,
      });
    } catch (e) {
      throw Exception('Failed to update allergens: $e');
    }
  }

  Future<void> saveSpecialCondition(String familyMemberId) async {
    try {
      await Supabase.instance.client
          .from('familymember_specialconditions')
          .upsert({
        'familymember_id': familyMemberId,
        'is_pregnant': _selectedCondition == 'Pregnant',
        'is_lactating': _selectedCondition == 'Lactating',
        'is_none': _selectedCondition == 'None',
      });
    } catch (e) {
      throw Exception('Failed to update special condition: $e');
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
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16), // Rounded corners
      ),
      child: Container(
        width: 500,
        height: 500, // Set dialog to square dimensions
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Family Member',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: firstNameController,
                        decoration:
                            const InputDecoration(labelText: 'First Name'),
                      ),
                      TextField(
                        controller: lastNameController,
                        decoration:
                            const InputDecoration(labelText: 'Last Name'),
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
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(1900),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setState(() {
                              dobController.text =
                                  "${picked.month}/${picked.day}/${picked.year}";

                              // Calculate age
                              final today = DateTime.now();
                              int age = today.year - picked.year;
                              // Adjust age if birthday hasn't occurred this year
                              if (today.month < picked.month ||
                                  (today.month == picked.month &&
                                      today.day < picked.day)) {
                                age--;
                              }
                              // Update age controller
                              ageController.text = age.toString();
                            });
                          }
                        },
                      ),
                      DropdownButtonFormField<String>(
                        value: religionController.text.isNotEmpty
                            ? religionController.text
                            : null,
                        onChanged: (value) =>
                            setState(() => religionController.text = value!),
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
                              value: religion, child: Text(religion));
                        }).toList(),
                        decoration:
                            const InputDecoration(labelText: 'Religion'),
                      ),
                      DropdownButtonFormField<String>(
                        value: gender,
                        items: genderOptions.map((value) {
                          return DropdownMenuItem(
                              value: value, child: Text(value));
                        }).toList(),
                        onChanged: (value) => setState(() => gender = value),
                        decoration: const InputDecoration(labelText: 'Gender'),
                      ),
                      DropdownButtonFormField<String>(
                        value: position,
                        items: positionOptions.map((value) {
                          return DropdownMenuItem(
                              value: value, child: Text(value));
                        }).toList(),
                        onChanged: (position == 'Family Head')
                            ? null
                            : (value) => setState(() => position = value),
                        decoration:
                            const InputDecoration(labelText: 'Position'),
                      ),
                      DropdownButtonFormField<String>(
                        value: _selectedCondition,
                        onChanged: (value) =>
                            setState(() => _selectedCondition = value),
                        items:
                            ['None', 'Lactating', 'Pregnant'].map((condition) {
                          return DropdownMenuItem(
                              value: condition, child: Text(condition));
                        }).toList(),
                        decoration: const InputDecoration(
                            labelText: 'Special Condition'),
                      ),
                      const SizedBox(height: 10),
                      const Text('Allergens'),
                      CheckboxListTile(
                        title: const Text('Seafood'),
                        value: seafoodAllergy,
                        onChanged: (value) =>
                            setState(() => seafoodAllergy = value ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Nuts'),
                        value: nutsAllergy,
                        onChanged: (value) =>
                            setState(() => nutsAllergy = value ?? false),
                      ),
                      CheckboxListTile(
                        title: const Text('Dairy'),
                        value: dairyAllergy,
                        onChanged: (value) =>
                            setState(() => dairyAllergy = value ?? false),
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),
                TextButton(
                  onPressed: () async {
                    final updatedMember = {
                      'first_name': firstNameController.text.isNotEmpty
                          ? firstNameController.text
                          : null,
                      'last_name': lastNameController.text.isNotEmpty
                          ? lastNameController.text
                          : null,
                      'age': int.tryParse(ageController.text),
                      'dob': dobController.text.isNotEmpty
                          ? dobController.text
                          : null,
                      'religion': religionController.text.isNotEmpty
                          ? religionController.text
                          : null,
                      'gender': gender ?? 'N/A',
                      'position': position ?? 'N/A',
                    };

                    try {
                      await saveAllergens(widget.memberData['familymember_id']);
                      await saveSpecialCondition(
                          widget.memberData['familymember_id']);
                      widget.onEdit(updatedMember);
                      Navigator.pop(context);
                      await _showSuccessDialog(
                          'Family member updated successfully!');
                    } catch (e) {
                      print('Error: $e');
                    }
                  },
                  child: const Text("Save"),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
