import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ViewFamilyHeadsPage extends StatefulWidget {
  const ViewFamilyHeadsPage({super.key});

  @override
  _ViewFamilyHeadsPageState createState() => _ViewFamilyHeadsPageState();
}

class _ViewFamilyHeadsPageState extends State<ViewFamilyHeadsPage> {
  List<dynamic> familyHeads = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchFamilyHeads();
  }

  Future<void> _fetchFamilyHeads() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response =
          await Supabase.instance.client.from('Family_Head').select();

      setState(() {
        familyHeads = response;
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
      appBar: AppBar(title: const Text('View Family Heads')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading data'))
              : familyHeads.isEmpty
                  ? const Center(child: Text('No family heads found'))
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('First Name')),
                          DataColumn(label: Text('Last Name')),
                          DataColumn(label: Text('Email')),
                          DataColumn(label: Text('Phone')),
                          DataColumn(label: Text('Address')),
                        ],
                        rows: familyHeads
                            .map(
                              (head) => DataRow(cells: [
                                DataCell(Text(head['first_name'] ?? '')),
                                DataCell(Text(head['last_name'] ?? '')),
                                DataCell(Text(head['email'] ?? '')),
                                DataCell(Text(head['phone'] ?? '')),
                                DataCell(Text(head['address_line1'] ?? '')),
                              ]),
                            )
                            .toList(),
                      ),
                    ),
    );
  }
}
