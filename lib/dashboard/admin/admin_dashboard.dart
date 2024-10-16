import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../login/login_admin.dart'; // Import the Login page

class AdminDashboard extends StatefulWidget {
  final String firstName;

  const AdminDashboard({super.key, required this.firstName});

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isDrawerOpen = false;

  final List<Widget> _pages = const [
    DashboardPage(),
    AddAdminPage(),
    ViewCooksPage(),
    ViewFamilyHeadsPage(),
    ApprovalPage(),
    MyProfilePage(),
  ];

  final List<String> _titles = const [
    'Dashboard',
    'Add Admin',
    'View Cooks',
    'View Family Heads',
    'Cooks Approval',
    'My Profile',
  ];

  void _onSelectItem(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pop(context);
  }

  void _onDrawerStateChanged(bool isOpen) {
    setState(() {
      _isDrawerOpen = isOpen;
    });
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
            title: Text(
              _titles[_selectedIndex],
              style: const TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: Colors.black),
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
        child: NavigationDrawer(
          selectedIndex: _selectedIndex,
          onSelectItem: _onSelectItem,
          firstName: widget.firstName,
        ),
      ),
      onDrawerChanged: _onDrawerStateChanged,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: EdgeInsets.only(left: _isDrawerOpen ? 200 : 0),
        child: _pages[_selectedIndex],
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectItem;
  final String firstName;

  const NavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectItem,
    required this.firstName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1CBB80),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Image(
              image: AssetImage('assets/logo-white.png'),
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () => onSelectItem(5),
            child: Padding(
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
                    firstName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white),
          SidebarMenuItem(
            title: 'Dashboard',
            isSelected: selectedIndex == 0,
            onTap: () => onSelectItem(0),
          ),
          SidebarMenuItem(
            title: 'Add Admin',
            isSelected: selectedIndex == 1,
            onTap: () => onSelectItem(1),
          ),
          SidebarMenuItem(
            title: 'View Cooks',
            isSelected: selectedIndex == 2,
            onTap: () => onSelectItem(2),
          ),
          SidebarMenuItem(
            title: 'View Family Heads',
            isSelected: selectedIndex == 3,
            onTap: () => onSelectItem(3),
          ),
          SidebarMenuItem(
            title: 'Cooks Approval',
            isSelected: selectedIndex == 4,
            onTap: () => onSelectItem(4),
          ),
          SidebarMenuItem(
            title: 'My Profile',
            isSelected: selectedIndex == 5,
            onTap: () => onSelectItem(5),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Center(
                  child: Column(
                    children: [
                      TextButton(
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
                                    Image.asset(
                                      'assets/logo-dark.png',
                                      height: 50,
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Are you sure you want to log out?',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
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
                                            Navigator.of(context)
                                                .pushAndRemoveUntil(
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      LoginAdmin()),
                                              (route) => false,
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          child: const Text('Logout'),
                                        ),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.of(context).pop();
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.orange,
                                          ),
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
                        child: const Text(
                          'Logout',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.title,
    required this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Container(
        decoration: isSelected
            ? BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              )
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

class AddAdminPage extends StatefulWidget {
  const AddAdminPage({super.key});

  @override
  _AddAdminPageState createState() => _AddAdminPageState();
}

class _AddAdminPageState extends State<AddAdminPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  Future<void> _handleAddAdmin() async {
    if (_formKey.currentState?.validate() == true) {
      if (passwordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwords do not match')),
        );
        return;
      }

      var uuid = const Uuid();
      String adminId = uuid.v4();

      try {
        final response = await Supabase.instance.client.from('admin').insert({
          'admin_id': adminId,
          'name': nameController.text,
          'email': emailController.text,
          'username': usernameController.text,
          'password': passwordController.text,
        });

        if (response != null) {
          nameController.clear();
          emailController.clear();
          usernameController.clear();
          passwordController.clear();
          confirmPasswordController.clear();

          _showSuccessDialog();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('An error occurred while adding admin')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An unexpected error occurred: $error')),
        );
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Text('Admin Created'),
          content:
              const Text('The admin account has been created successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Admin'),
        backgroundColor: const Color(0xFF1CBB80),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Admin',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                        .hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters long';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleAddAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1CBB80),
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                    child:
                        const Text('Add Admin', style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Icon(Icons.person, size: 40),
              Icon(Icons.group, size: 40),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Text('10 Cooks', style: TextStyle(fontSize: 18)),
              Text('10 Family Heads', style: TextStyle(fontSize: 18)),
            ],
          ),
        ],
      ),
    );
  }
}

class ViewCooksPage extends StatelessWidget {
  const ViewCooksPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('View all Cooks'));
  }
}

// View Family Heads Page with table display
class ViewFamilyHeadsPage extends StatefulWidget {
  const ViewFamilyHeadsPage({super.key});

  @override
  _ViewFamilyHeadsPageState createState() => _ViewFamilyHeadsPageState();
}

class _ViewFamilyHeadsPageState extends State<ViewFamilyHeadsPage> {
  List<dynamic> familyHeads = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchFamilyHeads();
  }

  Future<void> _fetchFamilyHeads() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response =
          await Supabase.instance.client.from('Family_Head').select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          familyHeads = response;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No family heads found')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Family Heads'),
        backgroundColor: const Color(0xFF1CBB80),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading data'))
              : familyHeads.isEmpty
                  ? const Center(child: Text('No family heads found'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('First Name')),
                          DataColumn(label: Text('Last Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Address')),
                        ],
                        rows: familyHeads
                            .map(
                              (head) => DataRow(cells: [
                                DataCell(Text(head['first_name'] ?? '')),
                                DataCell(Text(head['last_name'] ?? '')),
                                DataCell(Text(head['email'] ?? '')),
                                DataCell(Text(head['phone'] ?? '')),
                                DataCell(Text(head['address_line1'] ?? '')),
                              ]),
                            )
                            .toList(),
                      ),
                    ),
    );
  }
}

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({super.key});

  @override
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  List<dynamic> cooks = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchCooks();
  }

  Future<void> _fetchCooks() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response =
          await Supabase.instance.client.from('Local_Cook').select();

      if (response != null && response.isNotEmpty) {
        setState(() {
          cooks = response;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          hasError = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No pending cooks found')),
        );
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An error occurred: $e')),
      );
    }
  }

  Future<void> _approveCook(Map<String, dynamic> cook) async {
    final cookId = cook['localcookid'];
    try {
      await Supabase.instance.client.from('Local_Cook_Approved').insert({
        'localcookid': cookId,
        'first_name': cook['first_name'],
        'last_name': cook['last_name'],
        'email': cook['email'],
        'username': cook['username'],
        'dateofbirth': cook['dateofbirth'],
        'phone': cook['phone'],
        'address_line1': cook['address_line1'],
        'barangay': cook['barangay'],
        'city': cook['city'],
        'province': cook['province'],
        'postal_code': cook['postal_code'],
        'availability_days': cook['availability_days'],
        'time_available_from': cook['time_available_from'],
        'time_available_to': cook['time_available_to'],
        'certifications': cook['certifications'],
      });

      await Supabase.instance.client
          .from('Local_Cook')
          .delete()
          .eq('localcookid', cookId);

      _showApprovalSuccessDialog();
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving cook: $e')),
      );
    }
  }

  Future<void> _rejectCook(Map<String, dynamic> cook) async {
    final cookId = cook['localcookid'];
    try {
      await Supabase.instance.client
          .from('Local_Cook')
          .delete()
          .eq('localcookid', cookId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cook rejected successfully!')),
      );

      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting cook: $e')),
      );
    }
  }

  void _showApprovalSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Cook Approved'),
          content: const Text('The cook has been approved successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading data'))
              : cooks.isEmpty
                  ? const Center(child: Text('No pending cook approvals'))
                  : ListView.builder(
                      itemCount: cooks.length,
                      itemBuilder: (context, index) {
                        final cook = cooks[index];
                        return ListTile(
                          title: Text(
                              '${cook['first_name']} ${cook['last_name']}'),
                          subtitle: Text('Email: ${cook['email']}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => _approveCook(cook),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.clear, color: Colors.red),
                                onPressed: () => _rejectCook(cook),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

class MyProfilePage extends StatelessWidget {
  const MyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('My Profile Page'),
    );
  }
}
