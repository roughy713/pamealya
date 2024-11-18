// lib/my_family_page.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_family_member_dialog.dart';
import 'edit_family_member_dialog.dart';
import 'meal_plan_generator.dart';

class MyFamilyPage extends StatefulWidget {
  final String initialFirstName;
  final String initialLastName;

  const MyFamilyPage({
    super.key,
    required this.initialFirstName,
    required this.initialLastName,
  });

  @override
  _MyFamilyPageState createState() => _MyFamilyPageState();
}

class _MyFamilyPageState extends State<MyFamilyPage> {
  List<Map<String, dynamic>> familyMembers = [];
  late String firstName;
  late String lastName;

  @override
  void initState() {
    super.initState();
    firstName = widget.initialFirstName;
    lastName = widget.initialLastName;
    _addFamilyHead();
    fetchFamilyMembers();
  }

  Future<void> _addFamilyHead() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('first_name', firstName)
          .eq('last_name', lastName)
          .eq('position', 'Family Head')
          .maybeSingle();

      if (response == null) {
        await Supabase.instance.client.from('familymember').insert({
          'first_name': firstName,
          'last_name': lastName,
          'position': 'Family Head',
          'dietaryrestriction': 'None',
          'family_head': '$firstName $lastName',
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding family head: ${e.toString()}')),
      );
    }
  }

  Future<void> fetchFamilyMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('family_head', '$firstName $lastName');

      setState(() {
        familyMembers =
            (response as List<dynamic>).cast<Map<String, dynamic>>();

        // Sort the list to keep "Family Head" at the top
        familyMembers.sort((a, b) {
          if (a['position'] == 'Family Head') return -1;
          if (b['position'] == 'Family Head') return 1;
          return 0;
        });
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error fetching family members: ${e.toString()}')),
      );
    }
  }

  Future<void> _editFamilyMember(Map<String, dynamic> memberData) async {
    print("Editing member data: $memberData"); // Add this line to debug
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditFamilyMemberDialog(
          memberData: {
            'firstName': memberData['first_name'] ?? '',
            'lastName': memberData['last_name'] ?? '',
            'age': memberData['age'] ?? '',
            'gender': memberData['gender'] ?? '',
            'dob': memberData['dob'] ?? '',
            'position': memberData['position'] ?? 'Member',
            'dietaryRestriction': memberData['dietaryrestriction'] ?? 'None',
          },
          onEdit: (updatedData) async {
            try {
              await Supabase.instance.client
                  .from('familymember')
                  .update(updatedData)
                  .eq('familymember_id', memberData['familymember_id']);
              fetchFamilyMembers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Family member updated.')),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content:
                        Text('Error updating family member: ${e.toString()}')),
              );
            }
          },
        );
      },
    );
  }

  Future<void> _deleteFamilyMember(Map<String, dynamic> memberData) async {
    try {
      await Supabase.instance.client
          .from('familymember')
          .delete()
          .eq('familymember_id', memberData['familymember_id']);
      fetchFamilyMembers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Family member deleted.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting family member: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.person, size: 50),
              title: Text(
                '$firstName $lastName (Family Head)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddFamilyMemberDialog(onAdd: (data) async {
                      await Supabase.instance.client
                          .from('familymember')
                          .insert({
                        'first_name': data['firstName'] ?? '',
                        'last_name': data['lastName'] ?? '',
                        'age': data['age'] ?? '',
                        'gender': data['gender'] ?? '',
                        'dob': data['dob'] ?? '',
                        'position': data['position'] ?? 'Member',
                        'dietaryrestriction':
                            data['dietaryRestriction'] ?? 'None',
                        'family_head': '$firstName $lastName',
                      });
                      fetchFamilyMembers();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Family member added successfully.')),
                      );
                    });
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Family Member'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: familyMembers.length,
                itemBuilder: (context, index) {
                  final member = familyMembers[index];
                  bool isFamilyHead = member['position'] == 'Family Head';
                  return ListTile(
                    title: Text(
                      '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(member['position'] ?? ''),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person),
                    ),
                    onTap: isFamilyHead
                        ? () => _editFamilyMember(member)
                        : () => _showEditDeleteDialog(member),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => generateMealPlan(
            context, '$firstName $lastName'), // Call meal plan generator
        backgroundColor: Colors.yellow,
        label: const Text(
          'Generate Meal Plan',
          style: TextStyle(color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showEditDeleteDialog(Map<String, dynamic> member) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit or Delete Member"),
        content: const Text("Do you want to edit or delete this member?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editFamilyMember(member);
            },
            child: const Text("Edit"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteFamilyMember(member);
            },
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }
}
