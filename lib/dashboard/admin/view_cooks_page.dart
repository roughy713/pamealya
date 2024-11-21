import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewCooksPage extends StatefulWidget {
  const ViewCooksPage({super.key});

  @override
  _ViewCooksPageState createState() => _ViewCooksPageState();
}

class _ViewCooksPageState extends State<ViewCooksPage> {
  List<dynamic> cooks = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchCooks();
  }

  Future<void> _fetchCooks() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response =
          await Supabase.instance.client.from('Local_Cook').select();

      setState(() {
        cooks = response;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('View Cooks')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading cooks'))
              : cooks.isEmpty
                  ? const Center(child: Text('No cooks found'))
                  : ListView.builder(
                      itemCount: cooks.length,
                      itemBuilder: (context, index) {
                        final cook = cooks[index];
                        return ListTile(
                          title: Text(
                              '${cook['first_name']} ${cook['last_name']}'),
                          subtitle: Text('Email: ${cook['email']}'),
                        );
                      },
                    ),
    );
  }
}
