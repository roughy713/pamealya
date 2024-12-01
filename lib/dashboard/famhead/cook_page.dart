import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class CookPage extends StatefulWidget {
  final String userFirstName;
  final String userLastName;

  const CookPage({
    super.key,
    required this.userFirstName,
    required this.userLastName,
  });

  @override
  _CookPageState createState() => _CookPageState();
}

class _CookPageState extends State<CookPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> cooks = [];
  String? userCity; // To store the user's city

  @override
  void initState() {
    super.initState();
    fetchUserCity(widget.userFirstName, widget.userLastName).then((city) {
      if (city != null) {
        setState(() {
          userCity = city;
        });
        fetchCooks(city);
      } else {
        print('User city not found.');
      }
    });
  }

  Future<String?> fetchUserCity(String firstName, String lastName) async {
    try {
      // Fetch the city of the family head from the `familymember` table
      final response = await supabase
          .from('familymember')
          .select('city')
          .eq('first_name', firstName) // Match the first name
          .eq('last_name', lastName) // Match the last name
          .maybeSingle(); // Expect a single result

      return response != null ? response['city'] as String : null;
    } catch (e) {
      print('Error fetching user city: $e');
      return null;
    }
  }

  Future<void> fetchCooks(String userCity) async {
    try {
      // Fetch cooks with the same city as the user and where is_accepted is true
      final response = await supabase
          .from('Local_Cook')
          .select(
            '''
            localcookid, first_name, last_name, age, gender, dateofbirth, phone,
            address_line1, barangay, city, province, postal_code,
            availability_days, time_available_from, time_available_to,
            certifications
            ''',
          )
          .eq('is_accepted', true) // Fetch only accepted cooks
          .eq('city', userCity); // Fetch cooks with the same city as the user

      if (response.isNotEmpty) {
        setState(() {
          cooks = List<Map<String, dynamic>>.from(
              response); // Ensure type consistency
        });
      }
    } catch (e) {
      print('Error fetching cooks: $e');
    }
  }

  Future<void> bookCook(String cookId, DateTime desiredDeliveryTime) async {
    try {
      final uuid = const Uuid().v4();
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

      if (response.isNotEmpty) {
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.yellow,
                            ),
                            child: const Text('Book Cook',
                                style: TextStyle(color: Colors.black)),
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
