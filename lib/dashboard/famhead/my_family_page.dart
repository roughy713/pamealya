import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_family_member_dialog.dart';
import 'edit_family_member_dialog.dart';
import 'meal_plan_generator.dart';
import 'famhead_dashboard.dart';

class MyFamilyPage extends StatefulWidget {
  final String initialFirstName;
  final String initialLastName;
  final String currentUserId;

  const MyFamilyPage({
    super.key,
    required this.initialFirstName,
    required this.initialLastName,
    required this.currentUserId,
  });

  @override
  _MyFamilyPageState createState() => _MyFamilyPageState();
}

class _MyFamilyPageState extends State<MyFamilyPage> {
  List<Map<String, dynamic>> familyMembers = [];
  late String firstName;
  late String lastName;
  String? familyHeadName;

  @override
  void initState() {
    super.initState();
    firstName = widget.initialFirstName;
    lastName = widget.initialLastName;
    fetchFamilyMembers();
  }

  Future<void> fetchFamilyMembers() async {
    try {
      // First, get the family head record to get the correct family_head identifier
      final familyHeadRecord = await Supabase.instance.client
          .from('familymember')
          .select('family_head')
          .eq('user_id', widget.currentUserId)
          .single();

      if (familyHeadRecord == null) return;

      final String familyHeadName = familyHeadRecord['family_head'] as String;

      // Then get all family members using that specific family_head value
      final response =
          await Supabase.instance.client.from('familymember').select('''
            *, 
            familymember_allergens(is_seafood, is_nuts, is_dairy),
            familymember_specialconditions(is_pregnant, is_lactating, is_none)
          ''').eq('family_head', familyHeadName);

      setState(() {
        familyMembers =
            (response as List<dynamic>).cast<Map<String, dynamic>>();
        familyMembers.sort((a, b) {
          if (a['position'] == 'Family Head') return -1;
          if (b['position'] == 'Family Head') return 1;
          return 0;
        });
      });
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Error', style: TextStyle(color: Colors.red)),
            content: Text('Error fetching family members: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showMealPlanConfirmation(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;

      final existingPlan = await supabase
          .from('mealplan')
          .select()
          .eq('user_id', widget.currentUserId);

      if (existingPlan != null && existingPlan.isNotEmpty && context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Row(
                children: [
                  Icon(Icons.info, color: Colors.green, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'Meal Plan Exists',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              content: const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'You already have an existing meal plan.',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.yellow,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Okay'),
                ),
              ],
              actionsPadding: const EdgeInsets.all(16),
            );
          },
        );
      } else {
        await _showGenerateMealPlanDialog(context);
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _showGenerateMealPlanDialog(BuildContext context) async {
    bool isChecked = false;
    bool isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: const Text(
                'Generate Meal Plan',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Do you want to Generate Meal Plan?',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Warning Container
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange[700],
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Warning: This action cannot be undone. Please ensure all family member information and allergen details are correct before proceeding.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.black87,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Checkbox with aligned text
                  InkWell(
                    onTap: () {
                      setState(() {
                        isChecked = !isChecked;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: isChecked,
                              activeColor: Colors.green,
                              onChanged: (bool? value) {
                                setState(() {
                                  isChecked = value ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'I have double-checked all family member information and confirm it is correct',
                              style: TextStyle(
                                fontSize: 14,
                                height: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.black)),
                ),
                if (isLoading)
                  const CircularProgressIndicator()
                else
                  ElevatedButton(
                    onPressed: isChecked
                        ? () async {
                            try {
                              setState(() {
                                isLoading = true;
                              });

                              await generateMealPlan(
                                  context, familyHeadName ?? '');

                              Navigator.of(dialogContext).pop();

                              if (context.mounted) {
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  barrierColor: Colors.black.withOpacity(0.5),
                                  builder: (BuildContext context) => Dialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                    child: Container(
                                      width: 400,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                            0xFFF8F9FE), // Light purple-grey background
                                        borderRadius: BorderRadius.circular(28),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.08),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Main content padding
                                          Padding(
                                            padding: const EdgeInsets.all(32),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Success icon and text
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                              2),
                                                      decoration: BoxDecoration(
                                                        color: Colors
                                                            .green.shade50,
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(8),
                                                      ),
                                                      child: Icon(
                                                        Icons.check,
                                                        color: Colors
                                                            .green.shade500,
                                                        size: 16,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Success!',
                                                      style: TextStyle(
                                                        color: Colors
                                                            .green.shade500,
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),

                                                // Success message
                                                const Text(
                                                  'Your 7-day meal plan has been successfully generated!',
                                                  style: TextStyle(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                    color: Color(0xFF2C3135),
                                                    height: 1.3,
                                                  ),
                                                ),
                                                const SizedBox(height: 24),

                                                // White card for meal plan content
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(24),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    boxShadow: [
                                                      BoxShadow(
                                                        color: Colors.black
                                                            .withOpacity(0.03),
                                                        blurRadius: 10,
                                                        offset:
                                                            const Offset(0, 4),
                                                      ),
                                                    ],
                                                  ),
                                                  child: Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      // Meal plan illustration
                                                      SizedBox(
                                                        width: 100,
                                                        height: 100,
                                                        child: Image.asset(
                                                          'assets/mealplan.png',
                                                          color: Colors
                                                              .green.shade400,
                                                        ),
                                                      ),
                                                      const SizedBox(width: 24),

                                                      // Meal plan details
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            const Text(
                                                              'The meal plan includes:',
                                                              style: TextStyle(
                                                                fontSize: 14,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                color: Color(
                                                                    0xFF2C3135),
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 12),
                                                            ...[
                                                              'Daily breakfast options',
                                                              'Lunch selections',
                                                              'Dinner choices',
                                                              'Snack recommendations'
                                                            ]
                                                                .map(
                                                                  (text) =>
                                                                      Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        bottom:
                                                                            8),
                                                                    child: Row(
                                                                      children: [
                                                                        Container(
                                                                          width:
                                                                              4,
                                                                          height:
                                                                              4,
                                                                          margin: const EdgeInsets
                                                                              .only(
                                                                              right: 8,
                                                                              top: 8),
                                                                          decoration:
                                                                              BoxDecoration(
                                                                            color:
                                                                                Colors.green.shade400,
                                                                            borderRadius:
                                                                                BorderRadius.circular(2),
                                                                          ),
                                                                        ),
                                                                        Expanded(
                                                                          child:
                                                                              Text(
                                                                            text,
                                                                            style:
                                                                                const TextStyle(
                                                                              fontSize: 14,
                                                                              color: Color(0xFF4A5056),
                                                                              height: 1.4,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  ),
                                                                )
                                                                .toList(),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Bottom action
                                          Container(
                                            padding: const EdgeInsets.fromLTRB(
                                                32, 0, 32, 32),
                                            child: Align(
                                              alignment: Alignment.centerRight,
                                              child: ElevatedButton(
                                                onPressed: () {
                                                  Navigator.pushReplacement(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          FamHeadDashboard(
                                                        firstName: firstName,
                                                        lastName: lastName,
                                                        currentUserUsername: '',
                                                        currentUserId: widget
                                                            .currentUserId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      Colors.green.shade400,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal: 24,
                                                    vertical: 12,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            12),
                                                  ),
                                                ),
                                                child: const Text(
                                                  'Got it!',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                Navigator.of(dialogContext).pop();
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Error'),
                                    content: Text(e.toString()),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(context).pop(),
                                        child: const Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            } finally {
                              setState(() {
                                isLoading = false;
                              });
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.yellow,
                      foregroundColor: Colors.black,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Confirm',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
              actionsPadding: const EdgeInsets.all(16),
            );
          },
        );
      },
    );
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
                  .eq('familymember_id', memberData['familymember_id'])
                  .eq('user_id', widget.currentUserId); // Add user_id check

              fetchFamilyMembers();
              if (context.mounted) {
                Navigator.of(context).pop();
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    title: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 30),
                        SizedBox(width: 10),
                        Text('Success', style: TextStyle(color: Colors.green)),
                      ],
                    ),
                    content: const Text('Family member updated successfully!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Error',
                        style: TextStyle(color: Colors.red)),
                    content:
                        Text('Error updating family member: ${e.toString()}'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              }
            }
          },
        );
      },
    );
  }

  Future<void> _confirmDeleteFamilyMember(String familyMemberId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content:
            const Text('Are you sure you want to delete this family member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _deleteFamilyMember(familyMemberId);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

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

      // Show success dialog
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.green, size: 30),
                SizedBox(width: 10),
                Text(
                  'Success',
                  style: TextStyle(color: Colors.green),
                ),
              ],
            ),
            content: const Text('Family member deleted successfully!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text(
              'Error',
              style: TextStyle(color: Colors.red),
            ),
            content: Text('Error deleting family member: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _showFamilyMemberDetails(Map<String, dynamic> member) {
    final allergens = member['familymember_allergens'];
    final conditions = member['familymember_specialconditions'];

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Container(
          width: 500,
          height: 500,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${member['first_name']} ${member['last_name']} Details',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              _buildDetailRow("First Name:", member['first_name'] ?? 'N/A'),
              _buildDetailRow("Last Name:", member['last_name'] ?? 'N/A'),
              _buildDetailRow("Position:", member['position'] ?? 'N/A'),
              _buildDetailRow("Age:", member['age']?.toString() ?? 'N/A'),
              _buildDetailRow("Date of Birth:", member['dob'] ?? 'N/A'),
              _buildDetailRow("Religion:", member['religion'] ?? 'N/A'),
              _buildDetailRow("Gender:", member['gender'] ?? 'N/A'),
              const SizedBox(height: 10),
              _buildDetailRow(
                "Special Condition:",
                conditions != null
                    ? (conditions['is_pregnant'] == true
                        ? 'Pregnant'
                        : conditions['is_lactating'] == true
                            ? 'Lactating'
                            : 'None')
                    : 'None',
              ),
              const SizedBox(height: 10),
              const Text(
                'Allergens:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 5),
              if (allergens != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (allergens['is_seafood'] == true)
                      const Text('- Seafood'),
                    if (allergens['is_nuts'] == true) const Text('- Nuts'),
                    if (allergens['is_dairy'] == true) const Text('- Dairy'),
                    if (allergens['is_seafood'] != true &&
                        allergens['is_nuts'] != true &&
                        allergens['is_dairy'] != true)
                      const Text('- None'),
                  ],
                )
              else
                const Text('None'),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'Close',
                    style: TextStyle(color: Colors.purple),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$title ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(
                  Icons.family_restroom,
                  size: 50,
                  color: Colors.black,
                ),
                const SizedBox(width: 10),
                Text(
                  "$firstName $lastName's Family",
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const Divider(),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: ElevatedButton.icon(
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
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black,
                    backgroundColor: Colors.yellow,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: familyMembers.length,
                padding: const EdgeInsets.only(bottom: 70),
                itemBuilder: (context, index) {
                  final member = familyMembers[index];
                  bool isHovered = false;

                  return StatefulBuilder(
                    builder: (context, setState) {
                      return MouseRegion(
                        onEnter: (_) {
                          setState(() {
                            isHovered = true;
                          });
                        },
                        onExit: (_) {
                          setState(() {
                            isHovered = false;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isHovered
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              title: Text(
                                '${member['first_name'] ?? ''} ${member['last_name'] ?? ''}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                member['position'] ?? '',
                                style: const TextStyle(fontSize: 14),
                              ),
                              leading: const CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey,
                                child: Icon(Icons.person, size: 20),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: Colors.blue),
                                    onPressed: () => _editFamilyMember(member),
                                  ),
                                  if (member['position'] != 'Family Head')
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () =>
                                          _confirmDeleteFamilyMember(
                                              member['familymember_id']),
                                    ),
                                ],
                              ),
                              onTap: () => _showFamilyMemberDetails(member),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showMealPlanConfirmation(context),
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
