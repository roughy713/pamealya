import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class TransactionPage extends StatefulWidget {
  final String? currentUserId;

  const TransactionPage({
    super.key,
    this.currentUserId,
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> transactions = [];
  bool isLoading = true;
  double totalAmount = 0.0;
  String selectedPaymentMethod = 'All';
  DateTime? selectedStartDate;
  DateTime? selectedEndDate;

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      setState(() => isLoading = true);

      if (widget.currentUserId == null) {
        throw Exception('User ID is required');
      }

      // Build the base query
      var query = supabase.from('transactions').select('''
          *,
          Local_Cook!inner (
            first_name,
            last_name
          ),
          bookingrequest!inner (
            desired_delivery_time,
            meal_price
          )
        ''').eq('user_id', widget.currentUserId!.toString()); // Convert to String

      // Apply payment method filter if selected
      if (selectedPaymentMethod != 'All') {
        query = query.eq('payment_method', selectedPaymentMethod);
      }

      // Apply date range filters if selected
      if (selectedStartDate != null) {
        query = query.gte('created_at', selectedStartDate!.toIso8601String());
      }
      if (selectedEndDate != null) {
        query = query.lte('created_at', selectedEndDate!.toIso8601String());
      }

      // Order by most recent first
      final response = await query.order('created_at', ascending: false);

      setState(() {
        transactions = List<Map<String, dynamic>>.from(response);
        totalAmount = transactions.fold(
          0.0,
          (sum, item) =>
              sum + (double.tryParse(item['amount'].toString()) ?? 0.0),
        );
        isLoading = false;
      });
    } catch (e) {
      print('Error details: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
          transactions = [];
          totalAmount = 0.0;
        });
      }
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
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
        selectedStartDate = picked.start;
        selectedEndDate = picked.end;
      });
      fetchTransactions();
    }
  }

  void _clearFilters() {
    setState(() {
      selectedPaymentMethod = 'All';
      selectedStartDate = null;
      selectedEndDate = null;
    });
    fetchTransactions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  // Summary Card
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
                          'Transaction Summary',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount:',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                            Text(
                              'PHP ${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1CBB80),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Filter Section
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: selectedPaymentMethod,
                                decoration: InputDecoration(
                                  labelText: 'Payment Method',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                items: ['All', 'GCash', 'Credit Card', 'Cash']
                                    .map((method) => DropdownMenuItem(
                                          value: method,
                                          child: Text(method),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  setState(
                                      () => selectedPaymentMethod = value!);
                                  fetchTransactions();
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.calendar_today),
                              onPressed: () => _selectDateRange(context),
                            ),
                            IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: _clearFilters,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Date Range Display
                  if (selectedStartDate != null && selectedEndDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        'Showing transactions from ${DateFormat('MMM dd, yyyy').format(selectedStartDate!)} to ${DateFormat('MMM dd, yyyy').format(selectedEndDate!)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Transaction List
                  Expanded(
                    child: transactions.isEmpty
                        ? const Center(
                            child: Text(
                              'No transactions found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey,
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              final date =
                                  DateTime.parse(transaction['created_at']);
                              final amount = double.tryParse(
                                      transaction['amount'].toString()) ??
                                  0.0;
                              final paymentMethod =
                                  transaction['payment_method'] ?? 'N/A';
                              final cookName = transaction['Local_Cook'] != null
                                  ? '${transaction['Local_Cook']['first_name']} ${transaction['Local_Cook']['last_name']}'
                                  : 'N/A';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Transaction #${transaction['transaction_id'] ?? index + 1}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          'PHP ${amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF1CBB80),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          DateFormat('MMM dd, yyyy - hh:mm a')
                                              .format(date),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          'Cook: $cookName',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Payment Method: $paymentMethod',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Description: ${transaction['description'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      'Reference Number: ${transaction['reference_number'] ?? 'N/A'}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
