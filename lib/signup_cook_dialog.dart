import 'package:flutter/material.dart';

class SignUpCookDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sign Up as a Cook'),
      content: SingleChildScrollView(
        child: ListBody(
          children: const <Widget>[
            Text(
                'To become one of our cooks, please fill out the following information:'),
            // You can add your form fields here
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        ElevatedButton(
          child: const Text('Submit'),
          onPressed: () {
            // Implement the sign-up functionality here
          },
        ),
      ],
    );
  }
}
