import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  _TransactionPageState createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final TextEditingController _amountController = TextEditingController();
  bool _isProcessing = false;

  Future<void> _makePayment() async {
    final amount = _amountController.text;

    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    const url = 'https://api.paymongo.com/v1/sources';
    final headers = {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('sk_test_TTwEdeQ8myrEc4yuoK2LgeBg'))}',
      'Content-Type': 'application/json'
    };

    final body = jsonEncode({
      'data': {
        'attributes': {
          'amount': (double.parse(amount) * 100).toInt(),
          'currency': 'PHP',
          'type': 'gcash',
          'redirect': {
            'success': 'https://your-success-url.com',
            'failed': 'https://your-failure-url.com'
          }
        }
      }
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: body,
      );

      setState(() {
        _isProcessing = false;
      });

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        final checkoutUrl =
            responseData['data']['attributes']['redirect']['checkout_url'];

        if (await canLaunchUrl(Uri.parse(checkoutUrl))) {
          await launchUrl(Uri.parse(checkoutUrl));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open payment URL.')),
          );
        }
      } else {
        print('Error: ${response.body}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Payment creation failed. Please try again.')),
        );
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (PHP)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isProcessing ? null : _makePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1CBB80),
              ),
              child: _isProcessing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Pay with GCash'),
            ),
          ],
        ),
      ),
    );
  }
}
