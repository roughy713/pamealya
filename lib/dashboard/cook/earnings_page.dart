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
          .maybeSingle();

      if (cookResponse == null) {
        throw Exception('Cook not found');
      }

      final localCookId = cookResponse['localcookid'];

      // Get paid bookings for this cook
      final paidBookings = await supabase.from('bookingrequest').select('''
            bookingrequest_id,
            meal_price,
            request_date,
            familymember (
              first_name,
              last_name
            )
          ''').eq('localcookid', localCookId).eq('is_paid', true);

      print('Found ${paidBookings.length} paid bookings');

      // Process each booking
      List<Map<String, dynamic>> processedTransactions = [];
      double totalEarningsAmount = 0.0;

      for (final booking in paidBookings) {
        final bookingId = booking['bookingrequest_id'];

        // Get transaction using the transaction_details view
        final response = await supabase
            .from('transaction_details')
            .select()
            .eq('bookingrequest_id', bookingId)
            .maybeSingle();

        print('Transaction response for booking $bookingId: $response');

        if (response != null) {
          final processedTransaction = {
            'transaction_id': response['transaction_id'],
            'bookingrequest_id': bookingId,
            'amount': double.tryParse(response['amount'].toString()) ?? 0.0,
            'payment_method': response[
                'payment_method_text'], // Use the text version from the view
            'payment_date': response['created_at'],
            'reference_number': response['reference_number'] ?? 'N/A',
            'status': response['status'],
            'familymember': booking['familymember']
          };

          processedTransactions.add(processedTransaction);
          totalEarningsAmount += processedTransaction['amount'];
        } else {
          // Fallback to using booking data if no transaction found
          final amount =
              double.tryParse(booking['meal_price'].toString()) ?? 0.0;
          final processedTransaction = {
            'transaction_id': 'transaction-${booking['bookingrequest_id']}',
            'bookingrequest_id': booking['bookingrequest_id'],
            'amount': amount,
            'payment_method':
                'Unknown', // Default for bookings without transactions
            'payment_date': booking['request_date'],
            'reference_number':
                'REF-${booking['bookingrequest_id'].toString().substring(0, 8)}',
            'status': 'Completed',
            'familymember': booking['familymember']
          };

          processedTransactions.add(processedTransaction);
          totalEarningsAmount += amount;
        }
      }

      // Apply time frame filtering if needed
      if (selectedTimeFrame != 'All Time') {
        processedTransactions =
            _filterTransactionsByTimeFrame(processedTransactions);
        totalEarningsAmount = processedTransactions.fold(
            0.0, (sum, transaction) => sum + (transaction['amount'] ?? 0.0));
      }

      setState(() {
        transactions = processedTransactions;
        totalEarnings = totalEarningsAmount;
        isLoading = false;
      });

      print('Processed ${transactions.length} transactions');
      print('Total earnings: $totalEarnings');
    } catch (e) {
      print('Error fetching earnings: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          transactions = [];
          totalEarnings = 0.0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching earnings: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> _filterTransactionsByTimeFrame(
      List<Map<String, dynamic>> allTransactions) {
    if (selectedStartDate == null || selectedEndDate == null) {
      return allTransactions;
    }

    return allTransactions.where((transaction) {
      final paymentDateStr = transaction['payment_date'];
      if (paymentDateStr == null) return false;

      DateTime transactionDate;
      try {
        transactionDate = DateTime.parse(paymentDateStr);
      } catch (e) {
        print('Error parsing date: $e');
        return false;
      }

      // Add one day to end date to include the full end date
      final adjustedEndDate = selectedEndDate!.add(const Duration(days: 1));

      return transactionDate.isAfter(selectedStartDate!) &&
          transactionDate.isBefore(adjustedEndDate);
    }).toList();
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
    // Ensure critical fields are non-null
    final paymentDate =
        transaction['payment_date'] ?? DateTime.now().toIso8601String();
    final paymentMethod = transaction['payment_method'] ?? 'Unknown';
    final amount = double.tryParse(transaction['amount'].toString()) ?? 0.0;
    final bookingId = transaction['bookingrequest_id'] ?? 'Unknown';
    final referenceNumber = transaction['reference_number'] ?? 'N/A';
    final status = transaction['status'] ?? 'Completed';

    // Parse the payment date
    DateTime date;
    try {
      date = DateTime.parse(paymentDate);
    } catch (e) {
      print('Error parsing date for transaction $index: $e');
      date = DateTime.now();
    }

    // Format date with correct time
    String formattedDate = DateFormat('MMM dd, yyyy • hh:mm a').format(date);

    // Customer name extraction
    String customerName = 'Customer';
    final familyMember = transaction['familymember'];
    if (familyMember != null) {
      customerName =
          '${familyMember['first_name'] ?? ''} ${familyMember['last_name'] ?? ''}'
              .trim();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      color: Colors.white,
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
              'Payment Date: $formattedDate',
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
                  child: Text(
                    status,
                    style: const TextStyle(
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
