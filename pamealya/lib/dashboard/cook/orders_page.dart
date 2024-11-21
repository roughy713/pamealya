import 'package:flutter/material.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  _OrdersPageState createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  List<Map<String, dynamic>> orders = [
    {
      'bookingrequest_id': '12345',
      'famhead_id': 'Rafael Delloson',
      'localcook_id': 'b6fc9666-6251-41c4-8e61-092eb5c5e52f',
      'mealplan_id': 'N/A',
      'request_date': '2024-11-14',
      'desired_delivery_time': '2024-11-15T00:04:00',
      'ingredients': ['Rice', 'Chicken', 'Spices', 'Vegetables'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailsPage(order: order),
                ),
              );
            },
            child: Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking ID: ${order['bookingrequest_id']}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Family Member: ${order['famhead_id']}'),
                    Text('Cook: ${order['localcook_id']}'),
                    Text('Meal: ${order['mealplan_id']}'),
                    Text('Date: ${order['request_date']}'),
                    Text('Time: ${order['desired_delivery_time']}'),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class OrderDetailsPage extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetailsPage({super.key, required this.order});

  @override
  _OrderDetailsPageState createState() => _OrderDetailsPageState();
}

class _OrderDetailsPageState extends State<OrderDetailsPage> {
  int currentStep =
      0; // Tracks the current step: 0 for none, 1 for preparing, etc.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        backgroundColor: Colors.green[600],
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Booking ID: ${widget.order['bookingrequest_id']}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Divider(thickness: 1, color: Colors.grey),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRow('Family Member', widget.order['famhead_id']),
                const SizedBox(height: 10),
                _buildDetailRow('Cook', widget.order['localcook_id']),
                const SizedBox(height: 10),
                _buildDetailRow('Meal Plan', widget.order['mealplan_id']),
                const SizedBox(height: 10),
                _buildDetailRow('Request Date', widget.order['request_date']),
                const SizedBox(height: 10),
                _buildDetailRow(
                  'Delivery Time',
                  widget.order['desired_delivery_time'],
                ),
                const SizedBox(height: 20),
                const Text(
                  'Ingredients:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    widget.order['ingredients']
                        .map((ingredient) => '- $ingredient')
                        .join('\n'),
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Actions:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStepCircle(1, 'Preparing', Icons.fastfood),
                    _buildDashedLine(),
                    _buildStepCircle(2, 'On Delivery', Icons.delivery_dining),
                    _buildDashedLine(),
                    _buildStepCircle(3, 'Done', Icons.check_circle),
                  ],
                ),
                const SizedBox(height: 20),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to chat page
                    },
                    icon: const Icon(Icons.chat, color: Colors.white),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrange,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = step == currentStep + 1 || step <= currentStep;

    return Column(
      children: [
        GestureDetector(
          onTap: isActive
              ? () {
                  _confirmAction(step, label);
                }
              : () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Complete the previous step first!'),
                      backgroundColor: Colors.red,
                    ),
                  );
                },
          child: CircleAvatar(
            radius: 30,
            backgroundColor:
                step <= currentStep ? Colors.green : Colors.grey[300],
            child: Icon(
              icon,
              color: step <= currentStep ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: step <= currentStep ? Colors.green : Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildDashedLine() {
    return Container(
      width: 40,
      height: 2,
      color: Colors.grey[400],
      margin: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  void _confirmAction(int step, String label) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $label'),
        content: Text('Are you sure you want to mark this step as "$label"?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                currentStep = step;
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Step "$label" marked as completed!'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }
}
