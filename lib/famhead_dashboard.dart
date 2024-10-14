import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';

class FamHeadDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;

  const FamHeadDashboard({
    Key? key,
    required this.firstName,
    required this.lastName,
  }) : super(key: key);

  @override
  FamHeadDashboardState createState() => FamHeadDashboardState();
}

class FamHeadDashboardState extends State<FamHeadDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<String> _titles = [
    'Dashboard',
    'My Family',
    'Chat',
    'Cook',
    'Notifications',
    'BMI Calculator',
    'Transactions',
  ];

  List<Widget> get _pageDetails => [
        Center(child: Text('Dashboard Content')),
        MyFamilyPage(firstName: widget.firstName, lastName: widget.lastName),
        const Center(child: Text('Chat with family members.')),
        const Center(child: Text('Consult with a cook here.')),
        const Center(child: Text('Your notifications will appear here.')),
        const BMICalculatorPage(),
        const Center(child: Text('View your transactions here.')),
      ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
      _scaffoldKey.currentState?.closeDrawer();
    });
  }

  void _onDrawerStateChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
  }

  Future<void> _handleLogout(BuildContext context) async {
    try {
      await Supabase.instance.client.auth.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error during logout: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          transform:
              Matrix4.translationValues(_isDrawerOpen ? 300.0 : 0.0, 0.0, 0.0),
          child: AppBar(
            backgroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Color(0xFF1CBB80)),
            elevation: 0,
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFF1CBB80),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/logo-white.png',
                  height: 50,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.person, color: Color(0xFF1CBB80)),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      '${widget.firstName} ${widget.lastName}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white),
              _SidebarMenuItem(
                title: 'Dashboard',
                isSelected: _selectedIndex == 0,
                onTap: () => _onSelectItem(0),
              ),
              _SidebarMenuItem(
                title: 'My Family',
                isSelected: _selectedIndex == 1,
                onTap: () => _onSelectItem(1),
              ),
              _SidebarMenuItem(
                title: 'Chat',
                isSelected: _selectedIndex == 2,
                onTap: () => _onSelectItem(2),
              ),
              _SidebarMenuItem(
                title: 'Cook',
                isSelected: _selectedIndex == 3,
                onTap: () => _onSelectItem(3),
              ),
              _SidebarMenuItem(
                title: 'Notifications',
                isSelected: _selectedIndex == 4,
                onTap: () => _onSelectItem(4),
              ),
              _SidebarMenuItem(
                title: 'BMI Calculator',
                isSelected: _selectedIndex == 5,
                onTap: () => _onSelectItem(5),
              ),
              _SidebarMenuItem(
                title: 'Transactions',
                isSelected: _selectedIndex == 6,
                onTap: () => _onSelectItem(6),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Image.asset('assets/logo-dark.png', height: 50),
                              const SizedBox(height: 20),
                              const Text(
                                'Are you sure you want to log out?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                      _handleLogout(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red),
                                    child: const Text('Logout'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.orange),
                                    child: const Text('Cancel'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                  child:
                      const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ),
            ],
          ),
        ),
      ),
      onDrawerChanged: _onDrawerStateChanged,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(left: _isDrawerOpen ? 200 : 0),
        child: _pageDetails[_selectedIndex],
      ),
    );
  }
}

class _SidebarMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarMenuItem(
      {required this.title, required this.onTap, this.isSelected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16))
            : null,
        child: ListTile(
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF1CBB80) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          onTap: onTap,
        ),
      ),
    );
  }
}

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
          'age': '',
          'gender': '',
          'dob': '',
          'position': 'Family Head',
          'dietaryrestriction': 'None',
          'family_head': '${widget.firstName} ${widget.lastName}',
        });

        setState(() {
          familyMembers.insert(0, {
            'firstName': widget.firstName,
            'lastName': widget.lastName,
            'position': 'Family Head',
          });
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

      // Check if there's data
      if (response == null || response.isEmpty) {
        throw Exception('No family members found.');
      }

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
                    return AddFamilyMemberDialog(onAdd: (data) {
                      _addFamilyMember(data);
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
                  return ListTile(
                    title: Text(
                      '${member['firstName']} ${member['lastName']}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
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
        onPressed: () {
          // Your meal plan generation logic here
        },
        label: const Text('Generate Meal Plans'),
        backgroundColor: Colors.yellow,
      ),
    );
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
}

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
  DateTime? _selectedDate;

  final List<String> _positions = ['Father', 'Mother', 'Son', 'Daughter'];
  final List<String> _dietaryRestrictions = [
    'None',
    'Vegan',
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
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
              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(
                  labelText: 'First Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter first name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _lastNameController,
                decoration: const InputDecoration(
                  labelText: 'Last Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter last name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(
                  labelText: 'Date of Birth',
                  border: OutlineInputBorder(),
                ),
                readOnly: true,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: const InputDecoration(
                        labelText: 'Age',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter age';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Gender',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Please select gender';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Position in the Family',
                  border: OutlineInputBorder(),
                ),
                items: _positions
                    .map((position) => DropdownMenuItem(
                          value: position,
                          child: Text(position),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPosition = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a position';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Dietary Restriction',
                  border: OutlineInputBorder(),
                ),
                items: _dietaryRestrictions
                    .map((dietaryRestriction) => DropdownMenuItem(
                          value: dietaryRestriction,
                          child: Text(dietaryRestriction),
                        ))
                    .toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDietaryRestriction = value;
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a dietary restriction';
                  }
                  return null;
                },
              ),
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
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class BMICalculatorPage extends StatefulWidget {
  const BMICalculatorPage({super.key});

  @override
  BMICalculatorPageState createState() => BMICalculatorPageState();
}

class BMICalculatorPageState extends State<BMICalculatorPage> {
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  double _bmi = 0.0;
  String _bmiCategory = '';

  @override
  void dispose() {
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _calculateBMI() {
    final double weight = double.parse(_weightController.text);
    final double height = double.parse(_heightController.text) / 100;

    setState(() {
      _bmi = weight / (height * height);
      _bmiCategory = _getBMICategory(_bmi);
    });
  }

  String _getBMICategory(double bmi) {
    if (bmi < 18.5) {
      return 'Underweight';
    } else if (bmi < 24.9) {
      return 'Normal weight';
    } else if (bmi < 29.9) {
      return 'Overweight';
    } else {
      return 'Obesity';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Weight (kg)',
              ),
            ),
            TextField(
              controller: _heightController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Height (cm)',
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _calculateBMI,
              child: const Text('Calculate BMI'),
            ),
            const SizedBox(height: 20),
            Text('Your BMI is: ${_bmi.toStringAsFixed(2)} ($_bmiCategory)'),
          ],
        ),
      ),
    );
  }
}
