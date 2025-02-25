import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class EarningsPage extends StatefulWidget {
  final String? currentUserId;

  const EarningsPage({
    super.key,
    this.currentUserId,
  });

  @override
  State<EarningsPage> createState() => _EarningsPageState();
}

class _EarningsPageState extends State<EarningsPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  double totalEarnings = 0.0;
  String selectedTimeFrame = 'All Time';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    fetchEarnings();
  }

  Future<void> fetchEarnings() async {
    try {
      setState(() {
        isLoading = true;
      });

      if (widget.currentUserId == null) {
        throw Exception('User ID is required');
      }

      final String userId = widget.currentUserId!;

      // First get the cook's info
      final cookResponse = await supabase
          .from('Local_Cook')
          .select('localcookid, first_name, last_name')
          .eq('user_id', userId)
          .single();

      if (cookResponse == null) {
        throw Exception('Cook not found');
      }

      final localCookId = cookResponse['localcookid'];

      // Get transactions directly - ensure we have payment_method included
      final directTransactionsResponse = await supabase
          .from('transactions')
          .select('''
      *,
      bookingrequest!transactions_bookingrequest_id_fkey (
        desired_delivery_time,
        status,
        meal_price,
        user_id,
        is_paid,
        request_date
      ),
      familymember (
        first_name,
        last_name
      )
    ''')
          .eq('localcookid', localCookId)
          .order('created_at', ascending: false); // Sort by most recent first

      // Deep clone to prevent reference issues
      final directTransactions = List<Map<String, dynamic>>.from(
          directTransactionsResponse.map((t) => Map<String, dynamic>.from(t)));

      print('Found ${directTransactions.length} direct transactions');

      for (var i = 0; i < directTransactions.length; i++) {
        // Debug print each transaction payment method
        print(
            'Transaction ${i + 1} payment method: ${directTransactions[i]['payment_method']}');
      }

      if (directTransactions.isNotEmpty) {
        setState(() {
          transactions = directTransactions;
          totalEarnings = transactions.fold(
            0.0,
            (sum, transaction) =>
                sum +
                (double.tryParse(transaction['amount'].toString()) ?? 0.0),
          );
          isLoading = false;
        });
      } else {
        // If no direct transactions, look for paid bookings without transactions
        final paidBookings = await supabase
            .from('bookingrequest')
            .select('bookingrequest_id, meal_price, request_date')
            .eq('localcookid', localCookId)
            .eq('is_paid', true);

        print(
            'Found ${paidBookings.length} paid bookings but no direct transactions');

        if (paidBookings.isNotEmpty) {
          List<Map<String, dynamic>> syntheticTransactions = [];
          double totalAmount = 0.0;

          for (final booking in paidBookings) {
            final bookingId = booking['bookingrequest_id'];

            // Get detailed booking information
            final bookingDetail =
                await supabase.from('bookingrequest').select('''
                  *,
                  Local_Cook (
                    first_name,
                    last_name
                  ),
                  familymember (
                    first_name,
                    last_name
                  )
                ''').eq('bookingrequest_id', bookingId).single();

            if (bookingDetail != null) {
              final amount =
                  double.tryParse(bookingDetail['meal_price'].toString()) ??
                      0.0;
              totalAmount += amount;

              // Use a fixed date for created_at in synthetic transactions
              // based on request_date rather than the current time
              final requestDate = DateTime.parse(
                  bookingDetail['request_date'] ??
                      DateTime.now().toIso8601String());

              syntheticTransactions.add({
                'transaction_id': 'synthetic-$bookingId',
                'bookingrequest_id': bookingId,
                'amount': amount,
                'payment_method':
                    'GCash', // Default payment method for synthetic transactions only
                'created_at': requestDate.toIso8601String(),
                'bookingrequest': bookingDetail,
                'familymember': bookingDetail['familymember'],
                'reference_number':
                    'Booking-${bookingId.toString().substring(0, 8)}',
                'status': 'Completed',
                'isSynthetic': true
              });
            }
          }

          setState(() {
            transactions = syntheticTransactions;
            totalEarnings = totalAmount;
            isLoading = false;
          });
        } else {
          setState(() {
            transactions = [];
            totalEarnings = 0.0;
            isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching earnings: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          transactions = [];
          totalEarnings = 0.0;
        });
      }
    }
  }

  Future<void> _selectTimeFrame(String timeFrame) async {
    setState(() {
      selectedTimeFrame = timeFrame;
    });

    final now = DateTime.now();
    switch (timeFrame) {
      case 'Today':
        selectedStartDate = DateTime(now.year, now.month, now.day);
        selectedEndDate = now;
        break;
      case 'This Week':
        // Start of the week (Sunday)
        selectedStartDate = now.subtract(Duration(days: now.weekday % 7));
        selectedStartDate = DateTime(selectedStartDate!.year,
            selectedStartDate!.month, selectedStartDate!.day);
        selectedEndDate = now;
        break;
      case 'This Month':
        selectedStartDate = DateTime(now.year, now.month, 1);
        selectedEndDate = now;
        break;
      case 'This Year':
        selectedStartDate = DateTime(now.year, 1, 1);
        selectedEndDate = now;
        break;
      case 'All Time':
        selectedStartDate = null;
        selectedEndDate = null;
        break;
      default:
        selectedStartDate = null;
        selectedEndDate = null;
    }

    fetchEarnings();
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: selectedStartDate != null && selectedEndDate != null
          ? DateTimeRange(start: selectedStartDate!, end: selectedEndDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        selectedTimeFrame = 'Custom';
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
      });
      fetchEarnings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Earnings Card
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    margin: const EdgeInsets.symmetric(vertical: 20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          'Total Earnings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          '₱${totalEarnings.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          selectedTimeFrame,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Time frame selector
                Container(
                  width: MediaQuery.of(context).size.width * 0.9,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final timeFrame in [
                          'Today',
                          'This Week',
                          'This Month',
                          'This Year',
                          'All Time'
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: ChoiceChip(
                              label: Text(timeFrame),
                              selected: selectedTimeFrame == timeFrame,
                              onSelected: (selected) {
                                if (selected) {
                                  _selectTimeFrame(timeFrame);
                                }
                              },
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ActionChip(
                            label: const Text('Custom Range'),
                            avatar: const Icon(Icons.calendar_today, size: 16),
                            onPressed: () => _selectCustomDateRange(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Custom date range display
                if (selectedTimeFrame == 'Custom' &&
                    selectedStartDate != null &&
                    selectedEndDate != null)
                  Center(
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.9,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        '${DateFormat('MMM dd, yyyy').format(selectedStartDate!)} - ${DateFormat('MMM dd, yyyy').format(selectedEndDate!)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                // Transaction History Title
                Padding(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        '${transactions.length} transactions',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),

                // Transaction List
                Expanded(
                  child: transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No transactions yet',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Transactions will appear here once payments are processed',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];

                            // Parse date correctly from transaction created_at
                            DateTime date;
                            try {
                              date = DateTime.parse(transaction['created_at']);
                            } catch (e) {
                              date = DateTime.now();
                            }

                            final amount = double.tryParse(
                                    transaction['amount'].toString()) ??
                                0.0;

                            // Debug print the payment method for verification
                            final rawPaymentMethod =
                                transaction['payment_method'];
                            print(
                                'Transaction $index payment method: $rawPaymentMethod');

                            final referenceNumber =
                                transaction['reference_number'] ?? 'N/A';
                            final isSynthetic =
                                transaction['isSynthetic'] == true;

                            // Safely access nested objects
                            final bookingRequest = transaction['bookingrequest']
                                as Map<String, dynamic>?;
                            final bookingId =
                                transaction['bookingrequest_id'] ?? 'Unknown';

                            // Get customer info
                            String customerName = 'Customer';
                            if (transaction['familymember'] != null) {
                              final familyMember = transaction['familymember']
                                  as Map<String, dynamic>;
                              customerName =
                                  '${familyMember['first_name'] ?? ''} ${familyMember['last_name'] ?? ''}';
                            } else if (bookingRequest != null &&
                                bookingRequest['familymember'] != null) {
                              final familyMember =
                                  bookingRequest['familymember']
                                      as Map<String, dynamic>?;
                              if (familyMember != null) {
                                customerName =
                                    '${familyMember['first_name'] ?? ''} ${familyMember['last_name'] ?? ''}';
                              }
                            }

                            return Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              color:
                                  isSynthetic ? Colors.grey[50] : Colors.white,
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Payment for Booking #$bookingId',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          '₱${amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            color: Colors.green,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Payment Date: ${DateFormat('MMM dd, yyyy • hh:mm a').format(date)}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'From: $customerName',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Payment Method: ${transaction['payment_method']}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    Text(
                                      'Reference: $referenceNumber',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.green[50],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border:
                                                Border.all(color: Colors.green),
                                          ),
                                          child: const Text(
                                            'Completed',
                                            style: TextStyle(
                                              color: Colors.green,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blue[50],
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border:
                                                Border.all(color: Colors.blue),
                                          ),
                                          child: const Text(
                                            'Paid',
                                            style: TextStyle(
                                              color: Colors.blue,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
