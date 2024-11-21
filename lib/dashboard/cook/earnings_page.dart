import 'package:flutter/material.dart';

class EarningsPage extends StatelessWidget {
  const EarningsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> transactions = [
      {
        'date': 'Nov 15, 2024',
        'amount': 150.0,
        'description': 'Meal prepared for John Doe',
      },
      {
        'date': 'Nov 14, 2024',
        'amount': 120.0,
        'description': 'Catering service for Jane Smith',
      },
      {
        'date': 'Nov 13, 2024',
        'amount': 100.0,
        'description': 'Custom meal for Mark Lee',
      },
    ];

    double totalEarnings = transactions.fold(
      0.0,
      (sum, transaction) => sum + transaction['amount'],
    );

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: MediaQuery.of(context).size.width * 0.9,
              margin: const EdgeInsets.symmetric(vertical: 20),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(20),
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
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => const WithdrawalForm(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Colors.orange[600], // Yellow-orange color
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 40,
                        vertical: 15,
                      ),
                    ),
                    child: const Text(
                      'Withdraw Earnings',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(15),
            child: Text(
              'Transaction History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ListTile(
                    title: Text(
                      transaction['description'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(transaction['date']),
                    trailing: Text(
                      '₱${transaction['amount'].toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
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

class WithdrawalForm extends StatefulWidget {
  const WithdrawalForm({super.key});

  @override
  _WithdrawalFormState createState() => _WithdrawalFormState();
}

class _WithdrawalFormState extends State<WithdrawalForm> {
  final _formKey = GlobalKey<FormState>();
  double? withdrawalAmount;
  String? paymentMethod;
  String? accountDetails;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: 500, // Resized dialog width
        height: 400, // Resized dialog height
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Withdraw Earnings',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),

                // Withdrawal Amount Field
                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Withdrawal Amount',
                    prefixIcon: Icon(Icons.money), // Updated to money icon
                    prefixText: '₱ ',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    final parsedValue = double.tryParse(value);
                    if (parsedValue == null || parsedValue <= 0) {
                      return 'Please enter a valid amount';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    withdrawalAmount = double.tryParse(value!);
                  },
                ),
                const SizedBox(height: 20),

                // Payment Method Dropdown
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                    border: OutlineInputBorder(),
                  ),
                  items: ['Bank Transfer', 'PayPal', 'GCash']
                      .map((method) => DropdownMenuItem(
                            value: method,
                            child: Text(method),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      paymentMethod = value;
                    });
                  },
                  validator: (value) =>
                      value == null ? 'Please select a payment method' : null,
                ),
                const SizedBox(height: 20),

                // Account Details Field
                TextFormField(
                  decoration: InputDecoration(
                    labelText: paymentMethod == 'GCash'
                        ? 'GCash Number'
                        : 'Account Details',
                    prefixIcon: const Icon(Icons.account_balance),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return paymentMethod == 'GCash'
                          ? 'Please enter your GCash number'
                          : 'Please enter your account details';
                    }
                    return null;
                  },
                  onSaved: (value) {
                    accountDetails = value;
                  },
                ),
                const Spacer(),

                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Withdrawal request of ₱${withdrawalAmount!.toStringAsFixed(2)} submitted!',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Colors.orange[600], // Yellow-orange color
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Submit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
