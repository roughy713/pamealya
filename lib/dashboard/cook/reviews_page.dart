import 'package:flutter/material.dart';

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample data to simulate client reviews
    final List<Map<String, dynamic>> reviews = [
      {
        'clientName': 'John Doe',
        'rating': 5,
        'comment': 'The food was amazing! Will definitely book again.',
        'date': 'Nov 15, 2024',
      },
      {
        'clientName': 'Jane Smith',
        'rating': 4,
        'comment': 'Great experience overall, but delivery was a bit late.',
        'date': 'Nov 14, 2024',
      },
      {
        'clientName': 'Mark Lee',
        'rating': 3,
        'comment': 'The meal was okay, but I expected better.',
        'date': 'Nov 13, 2024',
      },
    ];

    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: reviews.length,
        itemBuilder: (context, index) {
          final review = reviews[index];
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        review['clientName'],
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        review['date'],
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: List.generate(
                      5,
                      (starIndex) => Icon(
                        starIndex < review['rating']
                            ? Icons.star
                            : Icons.star_border,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    review['comment'],
                    style: const TextStyle(fontSize: 14),
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
