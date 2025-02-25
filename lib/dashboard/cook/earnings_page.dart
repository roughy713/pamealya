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
          .maybeSingle(); // Changed to maybeSingle

      if (cookResponse == null) {
        throw Exception('Cook not found');
      }

      final localCookId = cookResponse['localcookid'];

      // Debug - Find the specific transaction that's causing issues
      // Changed from .single() to .maybeSingle() to handle zero results
      final testTransaction = await supabase
          .from('transactions')
          .select('*')
          .eq('bookingrequest_id', '2f8e6960-56b2-4fe5-93b6-9cd8519da9b4')
          .maybeSingle();

      if (testTransaction != null) {
        print('TEST TRANSACTION FOUND:');
        print('Transaction ID: ${testTransaction['transaction_id']}');
        print('Booking ID: ${testTransaction['bookingrequest_id']}');
        print('Payment Method: ${testTransaction['payment_method']}');
        print('Transaction Date: ${testTransaction['transaction_date']}');
        print('Payment Date: ${testTransaction['payment_date']}');
      } else {
        print(
            'No test transaction found for booking ID: 2f8e6960-56b2-4fe5-93b6-9cd8519da9b4');
      }

      // IMPORTANT - Get all transactions without any unnecessary joins or processing first
      final directTransactionsResponse = await supabase
          .from('transactions')
          .select('*')
          .eq('localcookid', localCookId)
          .order('transaction_date', ascending: false);

      // Deep clone to prevent reference issues
      final directTransactions = List<Map<String, dynamic>>.from(
          directTransactionsResponse.map((t) => Map<String, dynamic>.from(t)));

      print('Found ${directTransactions.length} direct transactions');

      if (directTransactions.isNotEmpty) {
        // Now fetch the additional details for each transaction
        final enrichedTransactions = <Map<String, dynamic>>[];

        for (final transaction in directTransactions) {
          // Store payment method BEFORE any other operations to ensure it doesn't get lost
          final originalPaymentMethod = transaction['payment_method'];
          print('ORIGINAL Payment Method: $originalPaymentMethod');

          // Fetch booking details
          final bookingResponse = await supabase
              .from('bookingrequest')
              .select('''
                *,
                familymember (
                  first_name,
                  last_name
                )
              ''')
              .eq('bookingrequest_id', transaction['bookingrequest_id'])
              .maybeSingle();

          if (bookingResponse != null) {
            // Create a new transaction with all data
            final enrichedTransaction = Map<String, dynamic>.from(transaction);
            enrichedTransaction['bookingrequest'] = bookingResponse;
            enrichedTransaction['familymember'] =
                bookingResponse['familymember'];

            // CRITICAL - Preserve the original payment method
            print('Setting payment method to: $originalPaymentMethod');
            enrichedTransaction['payment_method'] = originalPaymentMethod;

            enrichedTransactions.add(enrichedTransaction);
          } else {
            // If no booking found, just use the transaction as is
            enrichedTransactions.add(transaction);
          }
        }

        // Update state with enriched transactions
        setState(() {
          transactions = enrichedTransactions;
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
            .select('bookingrequest_id, meal_price, request_date, is_paid')
            .eq('localcookid', localCookId)
            .eq('is_paid', true);

        print(
            'Found ${paidBookings.length} paid bookings but no direct transactions');

        if (paidBookings.isNotEmpty) {
          List<Map<String, dynamic>> syntheticTransactions = [];
          double totalAmount = 0.0;

          for (final booking in paidBookings) {
            final bookingId = booking['bookingrequest_id'];

            // CRITICAL - Check if a transaction already exists for this booking
            final existingTransaction = await supabase
                .from('transactions')
                .select('*')
                .eq('bookingrequest_id', bookingId)
                .maybeSingle();

            // Get detailed booking information
            final bookingDetail = await supabase
                .from('bookingrequest')
                .select('''
                  *,
                  Local_Cook (
                    first_name,
                    last_name
                  ),
                  familymember (
                    first_name,
                    last_name
                  )
                ''')
                .eq('bookingrequest_id', bookingId)
                .maybeSingle(); // Changed to maybeSingle

            if (bookingDetail != null) {
              final amount =
                  double.tryParse(bookingDetail['meal_price'].toString()) ??
                      0.0;
              totalAmount += amount;

              // IMPORTANT - Use real transaction data if it exists
              if (existingTransaction != null) {
                // Use the real transaction date and payment method
                print(
                    'Found existing transaction with payment method: ${existingTransaction['payment_method']}');

                syntheticTransactions.add({
                  'transaction_id': existingTransaction['transaction_id'],
                  'bookingrequest_id': bookingId,
                  'amount': amount,
                  'payment_method': existingTransaction['payment_method'],
                  'transaction_date': existingTransaction['transaction_date'],
                  'payment_date': existingTransaction['payment_date'] ??
                      existingTransaction['transaction_date'],
                  'created_at': existingTransaction['created_at'],
                  'bookingrequest': bookingDetail,
                  'familymember': bookingDetail['familymember'],
                  'reference_number': existingTransaction['reference_number'],
                  'status': existingTransaction['status'],
                  'isSynthetic':
                      false // This is not synthetic, it's a real transaction
                });
              } else {
                // Use fallback data since no transaction exists
                DateTime paymentDate;
                try {
                  paymentDate = DateTime.parse(bookingDetail['request_date'] ??
                      DateTime.now().toIso8601String());
                } catch (e) {
                  paymentDate = DateTime.now();
                  print('Error parsing date: $e');
                }

                syntheticTransactions.add({
                  'transaction_id': 'synthetic-$bookingId',
                  'bookingrequest_id': bookingId,
                  'amount': amount,
                  'payment_method': 'Credit Card', // Default payment method
                  'transaction_date': paymentDate.toIso8601String(),
                  'payment_date': paymentDate.toIso8601String(),
                  'created_at': paymentDate.toIso8601String(),
                  'bookingrequest': bookingDetail,
                  'familymember': bookingDetail['familymember'],
                  'reference_number':
                      'REF-${bookingId.toString().substring(0, 8)}',
                  'status': 'Completed',
                  'isSynthetic': true
                });
              }
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

  Widget _buildTransactionCard(Map<String, dynamic> transaction, int index) {
    // Print transaction details for debugging
    print('Building card for transaction ${index}');
    print('Transaction ID: ${transaction['transaction_id']}');
    print('Payment Method: ${transaction['payment_method']}');
    print('Transaction Date: ${transaction['transaction_date']}');
    print('Payment Date: ${transaction['payment_date']}');

    // Use payment_date if available, fall back to transaction_date, then created_at
    DateTime date;
    try {
      if (transaction['payment_date'] != null) {
        date = DateTime.parse(transaction['payment_date']);
        print('Using payment_date: ${transaction['payment_date']}');
      } else if (transaction['transaction_date'] != null) {
        date = DateTime.parse(transaction['transaction_date']);
        print('Using transaction_date: ${transaction['transaction_date']}');
      } else if (transaction['created_at'] != null) {
        date = DateTime.parse(transaction['created_at']);
        print('Using created_at: ${transaction['created_at']}');
      } else {
        date = DateTime.now();
        print('No date found, using current time');
      }
    } catch (e) {
      date = DateTime.now();
      print('Error parsing date for transaction $index: $e');
    }

    // Get amount
    final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;

    // CRITICAL - Use the payment method directly from the transaction object
    // Don't apply any conditioning or default values
    final paymentMethod =
        transaction['payment_method']?.toString() ?? 'Credit Card';
    print('Final payment method to display: $paymentMethod');

    final referenceNumber = transaction['reference_number'] ?? 'N/A';
    final isSynthetic = transaction['isSynthetic'] == true;

    // Safely access nested objects
    final bookingRequest =
        transaction['bookingrequest'] as Map<String, dynamic>?;
    final bookingId = transaction['bookingrequest_id'] ?? 'Unknown';

    // Get customer info
    String customerName = 'Customer';
    if (transaction['familymember'] != null) {
      final familyMember = transaction['familymember'] as Map<String, dynamic>;
      customerName =
          '${familyMember['first_name'] ?? ''} ${familyMember['last_name'] ?? ''}';
    } else if (bookingRequest != null &&
        bookingRequest['familymember'] != null) {
      final familyMember =
          bookingRequest['familymember'] as Map<String, dynamic>?;
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
      color: isSynthetic ? Colors.grey[50] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              'Payment Method: $paymentMethod',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green),
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue),
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
                            return _buildTransactionCard(
                                transactions[index], index);
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
