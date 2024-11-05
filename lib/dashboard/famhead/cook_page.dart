import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://mtwwfagurgkeggzicslj.supabase.co', // Your Supabase URL
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im10d3dmYWd1cmdrZWdnemljc2xqIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjYxOTUxMDAsImV4cCI6MjA0MTc3MTEwMH0.czvacjIwvIcLYPmKD3NrFpg75H6DCkOrhg48Q0KwPXI', // Your Supabase anon key
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String loggedInUserFirstName = 'LoggedInUserFirstName';
    final String loggedInUserLastName = 'LoggedInUserLastName';

    return MaterialApp(
      title: 'Cook Booking',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: CookPage(
        userFirstName: loggedInUserFirstName,
        userLastName: loggedInUserLastName,
      ),
    );
  }
}

class CookPage extends StatefulWidget {
  final String userFirstName;
  final String userLastName;

  const CookPage(
      {Key? key, required this.userFirstName, required this.userLastName})
      : super(key: key);

  @override
  _CookPageState createState() => _CookPageState();
}

class _CookPageState extends State<CookPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cooks = [];

  @override
  void initState() {
    super.initState();
    fetchCooks();
  }

  Future<void> fetchCooks() async {
    try {
      final response = await supabase.from('Local_Cook_Approved').select(
          'localcookid, first_name, last_name, email, username, age, gender, dateofbirth, phone, address_line1, barangay, city, province, postal_code, availability_days, time_available_from, time_available_to, certifications');

      if (response != null && response.isNotEmpty) {
        setState(() {
          cooks = response as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      print('Error fetching cooks: $e');
    }
  }

  Future<void> bookCook(String cookId, DateTime desiredDeliveryTime) async {
    try {
      final uuid = Uuid().v4();
      final fullName = '${widget.userFirstName} ${widget.userLastName}';

      final response = await supabase.from('bookingrequest').insert({
        'bookingrequest_id': uuid,
        'localcook_id': cookId,
        'famhead_id': fullName,
        'is_cook_booking': true,
        'request_date': DateTime.now().toIso8601String(),
        'desired_delivery_time': desiredDeliveryTime.toIso8601String(),
        'meal_price': 0.0
      }).select();

      if (response != null && response.isNotEmpty) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success'),
            content: const Text(
                'Booking was successfully created, please wait for the approval of the cook.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to book: $e'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  void showCookDetails(Map<String, dynamic> cook) {
    DateTime? selectedDateTime;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('${cook['first_name']} ${cook['last_name']}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Email: ${cook['email']}'),
                    Text('Username: ${cook['username']}'),
                    Text('Age: ${cook['age']}'),
                    Text('Gender: ${cook['gender']}'),
                    Text('Date of Birth: ${cook['dateofbirth']}'),
                    Text('Phone: ${cook['phone']}'),
                    Text(
                        'Address: ${cook['address_line1']}, ${cook['barangay']}, ${cook['city']}, ${cook['province']}, ${cook['postal_code']}'),
                    Text('Availability Days: ${cook['availability_days']}'),
                    Text('Available From: ${cook['time_available_from']}'),
                    Text('Available To: ${cook['time_available_to']}'),
                    Text('Certifications: ${cook['certifications']}'),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) {
                            final combinedDateTime = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                            setState(() {
                              selectedDateTime = combinedDateTime;
                            });
                          }
                        }
                      },
                      child: Text(selectedDateTime == null
                          ? 'Select Delivery Date and Time'
                          : 'Delivery: ${DateFormat('yyyy-MM-dd – kk:mm').format(selectedDateTime!)}'),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
                TextButton(
                  onPressed: () {
                    if (selectedDateTime != null) {
                      Navigator.pop(context);
                      bookCook(cook['localcookid'], selectedDateTime!);
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Error'),
                          content: const Text(
                              'Please select a delivery date and time.'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: const Text('Book'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: cooks.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cooks.length,
              itemBuilder: (context, index) {
                final cook = cooks[index];
                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cook['first_name']} ${cook['last_name']}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('Location: ${cook['city']}, ${cook['province']}'),
                        Text('Available Days: ${cook['availability_days']}'),
                        Text('Available from: ${cook['time_available_from']}'),
                        Text('Available to: ${cook['time_available_to']}'),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: ElevatedButton(
                            onPressed: () => showCookDetails(cook),
                            child: const Text('Book Cook',
                                style: TextStyle(color: Colors.black)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
