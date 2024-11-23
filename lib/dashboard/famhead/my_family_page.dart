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
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return EditFamilyMemberDialog(
          memberData: memberData,
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

  Future<void> _deleteFamilyMember(String familyMemberId) async {
    try {
      // Delete related allergens first
      await Supabase.instance.client
          .from('familymember_allergens')
          .delete()
          .eq('familymember_id', familyMemberId);

      // Delete the family member
      await Supabase.instance.client
          .from('familymember')
          .delete()
          .eq('familymember_id', familyMemberId);

      fetchFamilyMembers();
      _showSuccessDialog('Family member deleted successfully!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error deleting family member: ${e.toString()}')),
      );
    }
  }

  void _showEditDeleteDialog(Map<String, dynamic> member) {
    final bool isFamilyHead = member['position'] == 'Family Head';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isFamilyHead ? "Edit Family Head" : "Edit or Delete Family Member"),
        content: isFamilyHead
            ? const Text("You can edit the family head but cannot delete it.")
            : const Text("Do you want to edit or delete this member?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _editFamilyMember(member);
            },
            child: const Text("Edit"),
          ),
          if (!isFamilyHead)
            TextButton(
              onPressed: () async {
                try {
                  Navigator.pop(context);

                  final supabase = Supabase.instance.client;

                  // Delete allergens associated with the member first
                  await supabase
                      .from('familymember_allergens')
                      .delete()
                      .eq('familymember_id', member['familymember_id']);

                  // Then delete the family member
                  await supabase
                      .from('familymember')
                      .delete()
                      .eq('familymember_id', member['familymember_id']);

                  setState(() {
                    familyMembers.removeWhere((m) =>
                        m['familymember_id'] == member['familymember_id']);
                  });

                  // Show success dialog
                  _showSuccessDialog('Family member deleted successfully!');
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting family member: $e')),
                  );
                }
              },
              child: const Text("Delete"),
            ),
        ],
      ),
    );
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.family_restroom, size: 50),
              title: Text(
                "$firstName $lastName's Family",
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
                    return AddFamilyMemberDialog(
                      onAdd: (data) {
                        setState(() {
                          familyMembers.add(data);
                        });
                      },
                      familyHeadName: '$firstName $lastName',
                    );
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
                    onTap: () => _showEditDeleteDialog(member),
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
}
