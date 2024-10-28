import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_family_member_dialog.dart';
import 'famhead_dashboard.dart';

class MyFamilyPage extends StatefulWidget {
  final String firstName;
  final String lastName;

  const MyFamilyPage(
      {Key? key, required this.firstName, required this.lastName})
      : super(key: key);

  @override
  _MyFamilyPageState createState() => _MyFamilyPageState();
}

class _MyFamilyPageState extends State<MyFamilyPage> {
  List<Map<String, String>> familyMembers = [];

  @override
  void initState() {
    super.initState();
    _addFamilyHead();
    fetchFamilyMembers();
  }

  Future<void> _addFamilyHead() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('first_name', widget.firstName)
          .eq('last_name', widget.lastName)
          .eq('position', 'Family Head')
          .maybeSingle();

      if (response == null) {
        await Supabase.instance.client.from('familymember').insert({
          'first_name': widget.firstName,
          'last_name': widget.lastName,
          'position': 'Family Head',
          'dietaryrestriction': 'None',
          'family_head': '${widget.firstName} ${widget.lastName}',
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding family head: $e')),
      );
    }
  }

  Future<void> fetchFamilyMembers() async {
    try {
      final response = await Supabase.instance.client
          .from('familymember')
          .select()
          .eq('family_head', '${widget.firstName} ${widget.lastName}');
      setState(() {
        familyMembers =
            (response as List<dynamic>).map<Map<String, String>>((member) {
          return {
            'firstName': member['first_name'] as String,
            'lastName': member['last_name'] as String,
            'position': member['position'] as String,
          };
        }).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching family members: $e')),
      );
    }
  }

  Future<void> _addFamilyMember(Map<String, String> data) async {
    try {
      await Supabase.instance.client.from('familymember').insert({
        'first_name': data['firstName'],
        'last_name': data['lastName'],
        'age': data['age'],
        'gender': data['gender'],
        'dob': data['dob'],
        'position': data['position'],
        'dietaryrestriction': data['dietaryRestriction'],
        'family_head': '${widget.firstName} ${widget.lastName}',
      });
      setState(() {
        familyMembers.add(data);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding family member: $e')),
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
                '${widget.firstName} ${widget.lastName} (Family Head)',
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
                    return AddFamilyMemberDialog(onAdd: _addFamilyMember);
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
                    title: Text('${member['firstName']} ${member['lastName']}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(member['position'] ?? ''),
                    leading: const CircleAvatar(
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {}, // Define the meal plan generation function if needed
        label: const Text('Generate Meal Plans'),
        backgroundColor: Colors.yellow,
      ),
    );
  }
}
