import 'package:flutter/material.dart';

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
  String? gender;
  String? position;
  String? dietaryRestriction;

  final List<String> genderOptions = ['Male', 'Female', 'Other'];
  final List<String> positionOptions = [
    'Father',
    'Mother',
    'Son',
    'Daughter',
    'Family Head'
  ];
  final List<String> dietaryOptions = [
    'None',
    'Halal',
    'Seafoods',
    'Nuts',
    'Milk'
  ];

  @override
  void initState() {
    super.initState();

    // Debugging to check if dob is being passed correctly
    print("Received memberData: ${widget.memberData}");

    firstNameController =
        TextEditingController(text: widget.memberData['firstName'] ?? '');
    lastNameController =
        TextEditingController(text: widget.memberData['lastName'] ?? '');
    ageController =
        TextEditingController(text: widget.memberData['age']?.toString() ?? '');

    // Parse dob and format it if it exists
    dobController = TextEditingController(
      text: widget.memberData['dob'] != null
          ? formatDate(widget.memberData['dob'])
          : '',
    );

    gender = genderOptions.contains(widget.memberData['gender'])
        ? widget.memberData['gender']
        : null;
    position = positionOptions.contains(widget.memberData['position'])
        ? widget.memberData['position']
        : positionOptions.first;
    dietaryRestriction =
        dietaryOptions.contains(widget.memberData['dietaryRestriction'])
            ? widget.memberData['dietaryRestriction']
            : dietaryOptions.first;
  }

  String formatDate(String date) {
    try {
      // Check if the date is in MM/DD/YYYY format
      final dateParts = date.split('/');
      if (dateParts.length == 3) {
        final month = int.parse(dateParts[0]);
        final day = int.parse(dateParts[1]);
        final year = int.parse(dateParts[2]);
        final parsedDate = DateTime(year, month, day);
        return '${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.year}';
      } else {
        // If not in MM/DD/YYYY, try parsing directly (for YYYY-MM-DD formats)
        final parsedDate = DateTime.parse(date);
        return '${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.year}';
      }
    } catch (e) {
      print("Error formatting date: $e");
      return '';
    }
  }

  Future<void> pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        dobController.text =
            "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFamilyHead = widget.memberData['position'] == 'Family Head';

    return AlertDialog(
      title: const Text("Edit Family Member"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            TextField(
              controller: firstNameController,
              decoration: const InputDecoration(labelText: "First Name"),
            ),
            TextField(
              controller: lastNameController,
              decoration: const InputDecoration(labelText: "Last Name"),
            ),
            TextField(
              controller: ageController,
              decoration: const InputDecoration(labelText: "Age"),
              keyboardType: TextInputType.number,
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
              decoration: const InputDecoration(labelText: "Gender"),
            ),
            TextField(
              controller: dobController,
              decoration: const InputDecoration(
                labelText: "Date of Birth",
                suffixIcon: Icon(Icons.calendar_today),
              ),
              readOnly: true,
              onTap: pickDate,
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
              decoration: const InputDecoration(labelText: "Position"),
            ),
            DropdownButtonFormField<String>(
              value: dietaryRestriction,
              items: dietaryOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  dietaryRestriction = value;
                });
              },
              decoration:
                  const InputDecoration(labelText: "Dietary Restriction"),
            ),
          ],
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
          onPressed: () {
            widget.onEdit({
              'first_name': firstNameController.text,
              'last_name': lastNameController.text,
              'age': ageController.text,
              'gender': gender,
              'dob': dobController.text,
              'position': position,
              'dietaryrestriction': dietaryRestriction,
            });
            Navigator.pop(context);
          },
          child: const Text("Save"),
        ),
      ],
    );
  }
}
