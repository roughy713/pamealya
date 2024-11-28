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
    fetchFamilyMembers(); // Fetch family members initially
  }

  /// Fetch family members from the database
  Future<void> fetchFamilyMembers() async {
    try {
      final response =
          await Supabase.instance.client.from('familymember').select(
        '''
          *, 
          familymember_allergens(is_seafood, is_nuts, is_dairy),
          familymember_specialconditions(is_pregnant, is_lactating, is_none)
        ''',
      ).eq('family_head', '$firstName $lastName');

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

  /// Add a new family member
  Future<void> _addFamilyMember(Map<String, dynamic> newMember) async {
    setState(() {
      familyMembers.add(newMember); // Add to local list
    });
    await fetchFamilyMembers(); // Refresh the list
  }

  /// Edit an existing family member
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
              await fetchFamilyMembers(); // Refresh the list after update
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

  /// Delete a family member
  Future<void> _deleteFamilyMember(String familyMemberId) async {
    try {
      // Delete allergens associated with the family member
      await Supabase.instance.client
          .from('familymember_allergens')
          .delete()
          .eq('familymember_id', familyMemberId);

      // Delete special conditions associated with the family member
      await Supabase.instance.client
          .from('familymember_specialconditions')
          .delete()
          .eq('familymember_id', familyMemberId);

      // Delete the family member record
      await Supabase.instance.client
          .from('familymember')
          .delete()
          .eq('familymember_id', familyMemberId);

      // Update the UI
      setState(() {
        familyMembers.removeWhere(
            (member) => member['familymember_id'] == familyMemberId);
      });

      _showSuccessDialog('Family member deleted successfully!');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting family member: $e')),
      );
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
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 50,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                Text(
                  "$firstName $lastName's Family",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AddFamilyMemberDialog(
                      onAdd: (data) => _addFamilyMember(data),
                      familyHeadName: '$firstName $lastName',
                    );
                  },
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Family Member'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.black,
                backgroundColor: Colors.yellow,
              ),
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () => _editFamilyMember(member),
                        ),
                        if (member['position'] != 'Family Head')
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () =>
                                _deleteFamilyMember(member['familymember_id']),
                          ),
                      ],
                    ),
                    onTap: () => _showFamilyMemberDetails(member),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => generateMealPlan(context, '$firstName $lastName'),
        backgroundColor: Colors.yellow,
        label: const Text(
          'Generate Meal Plan',
          style: TextStyle(color: Colors.black),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _showFamilyMemberDetails(Map<String, dynamic> member) {
    final allergens = member['familymember_allergens'];
    final conditions = member['familymember_specialconditions'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${member['first_name']} ${member['last_name']} Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('First Name: ${member['first_name'] ?? ''}'),
            Text('Last Name: ${member['last_name'] ?? ''}'),
            Text('Position: ${member['position'] ?? ''}'),
            Text('Age: ${member['age'] ?? 'N/A'}'),
            Text('Date of Birth: ${member['dob'] ?? 'N/A'}'),
            Text('Religion: ${member['religion'] ?? 'N/A'}'),
            Text('Gender: ${member['gender'] ?? 'N/A'}'),
            const SizedBox(height: 10),
            Text(
              'Special Condition: ${conditions != null ? (conditions['is_pregnant'] == true ? 'Pregnant' : conditions['is_lactating'] == true ? 'Lactating' : 'None') : 'N/A'}',
            ),
            const SizedBox(height: 10),
            Text(
              'Allergens:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (allergens != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (allergens['is_seafood'] == true) const Text('Seafood'),
                  if (allergens['is_nuts'] == true) const Text('Nuts'),
                  if (allergens['is_dairy'] == true) const Text('Dairy'),
                  if (allergens['is_seafood'] != true &&
                      allergens['is_nuts'] != true &&
                      allergens['is_dairy'] != true)
                    const Text('No Allergens'),
                ],
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
