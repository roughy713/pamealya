import 'package:flutter/material.dart';
import 'package:pamealya/login/login_admin.dart';
import 'package:pamealya/shared/sidebar_menu_item.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'add_admin_page.dart';
import 'dashboard_page.dart';
import 'view_cooks_page.dart';
import 'view_family_heads_page.dart';
import 'approval_page.dart';
import 'my_profile_page.dart';
import 'add_meals_page.dart';
import 'view_meals_page.dart';
import 'admin_notifications_page.dart';
import 'view_support_page.dart';

class AdminDashboard extends StatefulWidget {
  final String firstName;
  final String lastName;
  final String email;

  const AdminDashboard({
    super.key,
    required this.firstName,
    required this.lastName,
    required this.email,
  });

  @override
  AdminDashboardState createState() => AdminDashboardState();
}

class AdminDashboardState extends State<AdminDashboard> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  int _previousIndex = 0;

  Widget _getPage(int index) {
    switch (index) {
      case 0:
        return const DashboardPage();
      case 1:
        return const AddAdminPage();
      case 2:
        return const AddMealsPage();
      case 3:
        return const ViewMealsPage();
      case 4:
        return const ViewCooksPage();
      case 5:
        return const ViewFamilyHeadsPage();
      case 6:
        return const ViewSupportPage(); // Add the support page
      case 7:
        return const ApprovalPage();
      case 8:
        return const AdminNotificationsPage();
      case 9:
        return MyProfilePage(
          firstName: widget.firstName,
          lastName: widget.lastName,
          email: widget.email,
        );
      default:
        return const DashboardPage();
    }
  }

  final List<String> _titles = const [
    'Dashboard',
    'Add Admin',
    'Add Meals',
    'View Meals',
    'View Cooks',
    'View Family Heads',
    'Support',
    'Cooks Approval',
    'Notifications',
    'My Profile',
  ];

  void onSelectItem(int index) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = index;
    });
    Navigator.pop(context); // Close the drawer after selection
  }

  // Go back to previous page
  void goBack() {
    setState(() {
      int temp = _selectedIndex;
      _selectedIndex = _previousIndex;
      _previousIndex = temp;
    });
  }

  // Handle page change notification from DashboardPage
  bool _handlePageChangeNotification(
      DashboardPageChangeNotification notification) {
    setState(() {
      _previousIndex = _selectedIndex;
      _selectedIndex = notification.pageIndex;
    });
    return true; // Return true to stop the notification from propagating further
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginAdmin()),
          (route) => false,
        );
      }
    } catch (e) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Error'),
              content: Text(e.toString()),
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

  @override
  Widget build(BuildContext context) {
    return NotificationListener<DashboardPageChangeNotification>(
      onNotification: _handlePageChangeNotification,
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
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
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          actions: [
            if (_selectedIndex !=
                0) // Only show back button if not on Dashboard
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: goBack,
                tooltip: 'Back to previous page',
              ),
          ],
        ),
        drawer: Drawer(
          child: NavigationDrawer(
            selectedIndex: _selectedIndex,
            onSelectItem: onSelectItem,
            firstName: widget.firstName,
            lastName: widget.lastName,
            email: widget.email,
            onSignOut: _signOut,
          ),
        ),
        body: _getPage(_selectedIndex),
      ),
    );
  }
}

class NavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final Function(int) onSelectItem;
  final String firstName;
  final String lastName;
  final String email;
  final VoidCallback onSignOut;

  const NavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onSelectItem,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF1CBB80),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Image(
              image: AssetImage('assets/logo-white.png'),
              height: 50,
            ),
          ),
          GestureDetector(
            onTap: () => onSelectItem(9), // Updated index for profile
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$firstName $lastName',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Divider(color: Colors.white),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
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
                    title: 'Add Meal',
                    isSelected: selectedIndex == 2,
                    onTap: () => onSelectItem(2),
                  ),
                  SidebarMenuItem(
                    title: 'View Meals',
                    isSelected: selectedIndex == 3,
                    onTap: () => onSelectItem(3),
                  ),
                  SidebarMenuItem(
                    title: 'View Cooks',
                    isSelected: selectedIndex == 4,
                    onTap: () => onSelectItem(4),
                  ),
                  SidebarMenuItem(
                    title: 'View Family Heads',
                    isSelected: selectedIndex == 5,
                    onTap: () => onSelectItem(5),
                  ),
                  SidebarMenuItem(
                    title: 'Support', // Add Support menu item here
                    isSelected: selectedIndex == 6,
                    onTap: () => onSelectItem(6),
                  ),
                  SidebarMenuItem(
                    title: 'Cooks Approval',
                    isSelected: selectedIndex == 7,
                    onTap: () => onSelectItem(7),
                  ),
                  SidebarMenuItem(
                    title: 'Notifications',
                    isSelected: selectedIndex == 8,
                    onTap: () => onSelectItem(8),
                  ),
                  SidebarMenuItem(
                    title: 'My Profile',
                    isSelected: selectedIndex == 9,
                    onTap: () => onSelectItem(9),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextButton(
              onPressed: onSignOut,
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ),
        ],
      ),
    );
  }
}

// Notification class for page changes
class DashboardPageChangeNotification extends Notification {
  final int pageIndex;

  DashboardPageChangeNotification(this.pageIndex);
}

// Enhanced animated card widget with improved hover animations
class AnimatedDashboardCard extends StatefulWidget {
  final String title;
  final String value;
  final Widget icon;
  final VoidCallback? onTap;

  const AnimatedDashboardCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.onTap,
  });

  @override
  _AnimatedDashboardCardState createState() => _AnimatedDashboardCardState();
}

class _AnimatedDashboardCardState extends State<AnimatedDashboardCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _controller;
  late Animation<double> _elevationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _translateAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _elevationAnimation = Tween<double>(begin: 2, end: 8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _translateAnimation = Tween<double>(begin: 0, end: -8).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _translateAnimation.value),
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  height: 240,
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color:
                            Colors.black.withOpacity(_isHovered ? 0.15 : 0.05),
                        blurRadius: _elevationAnimation.value * 2,
                        spreadRadius: _elevationAnimation.value / 4,
                        offset: Offset(0, _isHovered ? -2 : 0),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.grey.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      widget.icon,
                      const SizedBox(height: 25),
                      Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 15),
                      Text(
                        widget.value,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Custom SVG icons
class CustomIcons {
  static Widget cooksRequestIcon(
      {double size = 48, Color color = const Color(0xFF1CBB80)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CooksRequestIconPainter(color: color),
      ),
    );
  }

  static Widget approvedCooksIcon(
      {double size = 48, Color color = const Color(0xFF1CBB80)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: CheckmarkIconPainter(color: color),
      ),
    );
  }

  static Widget familyHeadsIcon(
      {double size = 48, Color color = const Color(0xFF1CBB80)}) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: PeopleIconPainter(color: color),
      ),
    );
  }
}

// Custom painters for each icon
class CooksRequestIconPainter extends CustomPainter {
  final Color color;

  CooksRequestIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;

    // Document outline
    final documentPath = Path()
      ..moveTo(size.width * 0.2, size.width * 0.1)
      ..lineTo(size.width * 0.2, size.width * 0.8)
      ..lineTo(size.width * 0.8, size.width * 0.8)
      ..lineTo(size.width * 0.8, size.width * 0.1);

    // Top part of document (folder tab)
    documentPath.moveTo(size.width * 0.2, size.width * 0.1);
    documentPath.lineTo(size.width * 0.4, size.width * 0.1);
    documentPath.lineTo(size.width * 0.4, size.width * 0.2);
    documentPath.lineTo(size.width * 0.6, size.width * 0.2);
    documentPath.lineTo(size.width * 0.6, size.width * 0.1);
    documentPath.lineTo(size.width * 0.8, size.width * 0.1);

    canvas.drawPath(documentPath, paint);

    // Clock inside document
    final clockRadius = size.width * 0.15;
    final clockCenter = Offset(size.width * 0.5, size.width * 0.5);

    paint.style = PaintingStyle.fill;
    canvas.drawCircle(clockCenter, clockRadius, paint);

    paint.color = Colors.white;
    paint.strokeWidth = size.width * 0.03;
    canvas.drawLine(clockCenter,
        Offset(clockCenter.dx + clockRadius * 0.5, clockCenter.dy), paint);
    canvas.drawLine(clockCenter,
        Offset(clockCenter.dx, clockCenter.dy - clockRadius * 0.4), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class CheckmarkIconPainter extends CustomPainter {
  final Color color;

  CheckmarkIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Circle background
    canvas.drawCircle(
        Offset(size.width / 2, size.height / 2), size.width / 2, paint);

    // Checkmark
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = size.width * 0.12;
    paint.strokeCap = StrokeCap.round;

    final Path checkPath = Path()
      ..moveTo(size.width * 0.3, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.65)
      ..lineTo(size.width * 0.7, size.height * 0.35);

    canvas.drawPath(checkPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class PeopleIconPainter extends CustomPainter {
  final Color color;

  PeopleIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // First person (head)
    canvas.drawCircle(
        Offset(size.width * 0.3, size.height * 0.35), size.width * 0.15, paint);

    // Second person (head)
    canvas.drawCircle(
        Offset(size.width * 0.7, size.height * 0.35), size.width * 0.15, paint);

    // Body shapes (simplified)
    final bodyPath = Path()
      ..addOval(Rect.fromCircle(
          center: Offset(size.width * 0.3, size.height * 0.7),
          radius: size.width * 0.2))
      ..addOval(Rect.fromCircle(
          center: Offset(size.width * 0.7, size.height * 0.7),
          radius: size.width * 0.2));

    canvas.drawPath(bodyPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Updated Dashboard Page with custom SVG icons
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FB),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overview',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              shrinkWrap: true,
              childAspectRatio: 1.1, // Makes cards taller
              physics: const NeverScrollableScrollPhysics(),
              children: [
                AnimatedDashboardCard(
                  title: 'Cooks Request',
                  value: '7',
                  icon: CustomIcons.cooksRequestIcon(),
                  onTap: () {
                    // Navigate to Cooks Approval page
                    DashboardPageChangeNotification(7).dispatch(context);
                  },
                ),
                AnimatedDashboardCard(
                  title: 'Approved Cooks',
                  value: '8',
                  icon: CustomIcons.approvedCooksIcon(),
                  onTap: () {
                    // Navigate to View Cooks page
                    DashboardPageChangeNotification(4).dispatch(context);
                  },
                ),
                AnimatedDashboardCard(
                  title: 'Family Heads',
                  value: '70',
                  icon: CustomIcons.familyHeadsIcon(),
                  onTap: () {
                    // Navigate to View Family Heads page
                    DashboardPageChangeNotification(5).dispatch(context);
                  },
                ),
              ],
            ),
            // Additional dashboard content would go here
          ],
        ),
      ),
    );
  }
}
