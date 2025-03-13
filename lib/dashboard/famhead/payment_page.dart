import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

class PaymentPage extends StatefulWidget {
  final String? currentUserId;
  final String bookingrequestId;

  const PaymentPage({
    super.key,
    this.currentUserId,
    required this.bookingrequestId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final supabase = Supabase.instance.client;
  String selectedPaymentMethod = 'GCash';
  bool isProcessing = false;
  bool isLoading = true;
  List<Map<String, dynamic>> pendingBookings = [];
  Map<String, dynamic>? bookingDetails;
  String? errorMessage;
  String? selectedBookingId;

  @override
  void initState() {
    super.initState();
    if (widget.bookingrequestId.isNotEmpty) {
      fetchBookingDetails(widget.bookingrequestId);
    } else {
      fetchPendingandAcceptedBookings();
    }
  }

  Future<void> fetchPendingandAcceptedBookings() async {
    try {
      setState(() => isLoading = true);

      if (widget.currentUserId == null) {
        throw Exception('User ID is required');
      }

      final response = await supabase
          .from('bookingrequest')
          .select('''
            *,
            Local_Cook (
              localcookid,
              first_name,
              last_name,
              city,
              barangay
            )
          ''')
          .eq('user_id', widget.currentUserId!)
          .eq('status', 'accepted')
          .eq('_isBookingAccepted', true)
          .eq('is_paid', false) // Ensures payment is not yet made
          .order('request_date', ascending: false);

      if (mounted) {
        setState(() {
          pendingBookings = List<Map<String, dynamic>>.from(response);
          isLoading = false;
        });

        print(
            'Fetched ${pendingBookings.length} pending and accepted bookings'); // Debug print
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error fetching pending bookings: $e';
          isLoading = false;
        });
      }
      print('Error in fetchPendingBookings: $e'); // Debug print
    }
  }

  Future<void> fetchBookingDetails(String bookingId) async {
    try {
      setState(() => isLoading = true);

      final response = await supabase.from('bookingrequest').select('''
              *,
              Local_Cook (
                localcookid,
                first_name,
                last_name,
                city,
                barangay,
                user_id
              )
            ''').eq('bookingrequest_id', bookingId).single();

      setState(() {
        bookingDetails = response;
        selectedBookingId = bookingId;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching booking details: $e';
        isLoading = false;
      });
    }
  }

  Future<void> processPayment() async {
    if (bookingDetails == null ||
        widget.currentUserId == null ||
        selectedBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Missing required information for payment')),
      );
      return;
    }

    try {
      setState(() => isProcessing = true);

      // Generate transaction details
      final transactionId = const Uuid().v4();
      final referenceNumber = 'REF${DateTime.now().millisecondsSinceEpoch}';
      final cookId = bookingDetails!['Local_Cook']['localcookid'];
      final amount =
          double.tryParse(bookingDetails!['meal_price'].toString()) ?? 0.0;
      final cookUserId = bookingDetails!['Local_Cook']['user_id'];

      if (amount <= 0) {
        throw Exception('Invalid amount. Amount must be greater than 0.');
      }

      // Debug logs
      print('Creating transaction with:');
      print('- transaction_id: $transactionId');
      print('- user_id (payer): ${widget.currentUserId}');
      print('- localcookid: $cookId');
      print('- cook user_id: $cookUserId');
      print('- amount: $amount');
      print('- bookingrequest_id: $selectedBookingId');

      // Create the transaction record - make sure localcookid is included properly
      await supabase.from('transactions').insert({
        'transaction_id': transactionId,
        'user_id': widget.currentUserId!,
        'localcookid': cookId,
        'familymember_id': bookingDetails!['familymember_id'],
        'amount': amount,
        'payment_method': selectedPaymentMethod,
        'description': 'Payment for cooking service',
        'reference_number': referenceNumber,
        'status': 'Completed',
        'bookingrequest_id': selectedBookingId!,
        'payment_date': DateTime.now().toIso8601String(),
      });

      // Double-check transaction was created with proper localcookid
      final verifyTransaction = await supabase
          .from('transactions')
          .select('*')
          .eq('transaction_id', transactionId)
          .single();

      print('Verified transaction:');
      print('- localcookid in DB: ${verifyTransaction['localcookid']}');
      print('- expected localcookid: $cookId');

      // If localcookid is missing or null, try updating it
      if (verifyTransaction['localcookid'] == null) {
        print('WARNING: Transaction created without localcookid, fixing...');
        await supabase.from('transactions').update({'localcookid': cookId}).eq(
            'transaction_id', transactionId);
      }

      // Also add a transaction summary record if you have that table
      try {
        await supabase.from('transaction_summaries').insert({
          'user_id': widget.currentUserId!,
          'localcookid': cookId,
          'amount': amount,
          'transaction_count': 1,
          'total_amount': amount,
          'status': 'Completed',
        });
      } catch (e) {
        print('Error creating transaction summary (non-critical): $e');
      }

      // Update booking request status
      await supabase
          .from('bookingrequest')
          .update({'is_paid': true, 'status': 'Processing'}).eq(
              'bookingrequest_id', selectedBookingId!);

      // Create notification for the cook
      await supabase.rpc(
        'create_notification',
        params: {
          'p_recipient_id': cookUserId,
          'p_sender_id': widget.currentUserId,
          'p_title': 'Payment Received',
          'p_message': 'Payment has been received for your cooking service.',
          'p_notification_type': 'payment',
          'p_related_id': transactionId,
        },
      );

      if (mounted) {
        await showSuccessDialog(referenceNumber);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error processing payment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isProcessing = false);
      }
    }
  }

  Future<void> showSuccessDialog(String referenceNumber) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 48),
              SizedBox(height: 16),
              Text(
                'Payment Successful!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Amount Paid: PHP ${(double.tryParse(bookingDetails!['meal_price'].toString()) ?? 0.0).toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Reference Number: $referenceNumber',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Your payment has been processed successfully.',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                  if (widget.bookingrequestId.isEmpty) {
                    setState(() {
                      bookingDetails = null;
                      selectedBookingId = null;
                      fetchPendingandAcceptedBookings();
                    });
                  } else {
                    Navigator.of(context).pop(); // Return to previous screen
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(errorMessage!),
        ),
      );
    }

    // Show list of pending bookings if no booking is selected
    if (bookingDetails == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Pending Payments'),
          backgroundColor: Colors.white,
        ),
        body: pendingBookings.isEmpty
            ? const Center(
                child: Text(
                  'No pending payments',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
            : ListView.builder(
                itemCount: pendingBookings.length,
                itemBuilder: (context, index) {
                  final booking = pendingBookings[index];
                  final cookName =
                      '${booking['Local_Cook']['first_name']} ${booking['Local_Cook']['last_name']}';
                  final amount =
                      double.tryParse(booking['meal_price'].toString()) ?? 0.0;
                  final bookingDate =
                      DateTime.parse(booking['desired_delivery_time']);

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    child: ListTile(
                      title: Text(cookName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              'Date: ${DateFormat('MMM dd, yyyy').format(bookingDate)}'),
                          Text('Amount: PHP ${amount.toStringAsFixed(2)}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        onPressed: () =>
                            fetchBookingDetails(booking['bookingrequest_id']),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1CBB80),
                        ),
                        child: const Text('Pay Now'),
                      ),
                    ),
                  );
                },
              ),
      );
    }

    final cookName =
        '${bookingDetails!['Local_Cook']['first_name']} ${bookingDetails!['Local_Cook']['last_name']}';
    final cookLocation =
        '${bookingDetails!['Local_Cook']['city']}, ${bookingDetails!['Local_Cook']['barangay']}';
    final amount =
        double.tryParse(bookingDetails!['meal_price'].toString()) ?? 0.0;
    final bookingDate =
        DateTime.parse(bookingDetails!['desired_delivery_time']);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Details'),
        backgroundColor: Colors.white,
        leading: widget.bookingrequestId.isEmpty
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    bookingDetails = null;
                    selectedBookingId = null;
                  });
                },
              )
            : null,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cook Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Cook Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cookName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      cookLocation,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Booking Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Booking Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Date: ${DateFormat('MMMM dd, yyyy').format(bookingDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Time: ${DateFormat('hh:mm a').format(bookingDate)}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Amount to Pay',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      'PHP ${amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1CBB80),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Payment Methods
              const Text(
                'Select Payment Method',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),

              // Payment Method Cards
              Column(
                children: [
                  PaymentMethodCard(
                    icon: Icons.account_balance_wallet,
                    title: 'GCash',
                    isSelected: selectedPaymentMethod == 'GCash',
                    onTap: () {
                      setState(() {
                        selectedPaymentMethod = 'GCash';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  PaymentMethodCard(
                    icon: Icons.credit_card,
                    title: 'Credit Card',
                    isSelected: selectedPaymentMethod == 'Credit Card',
                    onTap: () {
                      setState(() {
                        selectedPaymentMethod = 'Credit Card';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  PaymentMethodCard(
                    icon: Icons.payments,
                    title: 'Cash',
                    isSelected: selectedPaymentMethod == 'Cash',
                    onTap: () {
                      setState(() {
                        selectedPaymentMethod = 'Cash';
                      });
                    },
                  ),
                ],
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isProcessing ? null : processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1CBB80),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Pay Now',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
}

class PaymentMethodCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const PaymentMethodCard({
    super.key,
    required this.icon,
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE8F5E9) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? const Color(0xFF1CBB80) : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.grey.shade700),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF1CBB80),
              ),
          ],
        ),
      ),
    );
  }
}
