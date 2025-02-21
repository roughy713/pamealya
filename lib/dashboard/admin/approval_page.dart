import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:html' as html;
import 'dart:typed_data';

class ApprovalPage extends StatefulWidget {
  const ApprovalPage({Key? key}) : super(key: key);

  @override
  _ApprovalPageState createState() => _ApprovalPageState();
}

class _ApprovalPageState extends State<ApprovalPage> {
  List<dynamic> cooks = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchCooks();
  }

  Future<void> downloadFile(Uint8List bytes, String fileName) async {
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..style.display = 'none'
      ..download = fileName;

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
  }

  Future<void> _fetchCooks() async {
    setState(() {
      isLoading = true;
      hasError = false;
    });

    try {
      final response = await Supabase.instance.client
          .from('Local_Cook')
          .select()
          .eq('is_accepted', false);

      if (response != null) {
        setState(() {
          cooks = response as List<dynamic>;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to fetch cooks');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        hasError = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching cooks: $e')),
      );
    }
  }

  void _showCookDetailsDialog(BuildContext context, Map<String, dynamic> cook) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: 500,
            height: 600,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.grey[200],
                        child: Icon(Icons.person,
                            size: 40, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${cook['first_name'] ?? 'N/A'} ${cook['last_name'] ?? 'N/A'}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personal Details',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text('Age: ${cook['age'] ?? 'N/A'}'),
                        Text('Gender: ${cook['gender'] ?? 'N/A'}'),
                        Text('Date of Birth: ${cook['dateofbirth'] ?? 'N/A'}'),
                        Text('Phone: ${cook['phone'] ?? 'N/A'}'),
                        const SizedBox(height: 16),
                        const Text(
                          'Address Information',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text('Address: ${cook['address_line1'] ?? 'N/A'}'),
                        Text('Barangay: ${cook['barangay'] ?? 'N/A'}'),
                        Text('City: ${cook['city'] ?? 'N/A'}'),
                        Text('Province: ${cook['province'] ?? 'N/A'}'),
                        Text('Postal Code: ${cook['postal_code'] ?? 'N/A'}'),
                        const SizedBox(height: 16),
                        const Text(
                          'Availability',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            'Days Available: ${cook['availability_days'] ?? 'N/A'}'),
                        Text('From: ${cook['time_available_from'] ?? 'N/A'}'),
                        Text('To: ${cook['time_available_to'] ?? 'N/A'}'),
                        const SizedBox(height: 16),
                        const Text(
                          'Certification',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: () async {
                            try {
                              // Get the file extension
                              final String fileName =
                                  cook['certifications']?.split('/').last ?? '';
                              final String fileExt =
                                  fileName.split('.').last.toLowerCase();

                              // Determine file type and icon
                              IconData fileIcon;
                              String fileType;
                              switch (fileExt) {
                                case 'pdf':
                                  fileIcon = Icons.picture_as_pdf;
                                  fileType = 'PDF Document';
                                  break;
                                case 'doc':
                                case 'docx':
                                  fileIcon = Icons.description;
                                  fileType = 'Word Document';
                                  break;
                                case 'jpg':
                                case 'jpeg':
                                case 'png':
                                  fileIcon = Icons.image;
                                  fileType = 'Image';
                                  break;
                                case 'txt':
                                  fileIcon = Icons.text_snippet;
                                  fileType = 'Text Document';
                                  break;
                                default:
                                  fileIcon = Icons.insert_drive_file;
                                  fileType = 'Document';
                              }

                              // Show download dialog
                              await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  bool isDownloading = false;

                                  return StatefulBuilder(
                                    builder: (context, setState) {
                                      return Dialog(
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.all(16),
                                          width: 400,
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                fileIcon,
                                                size: 64,
                                                color: Colors.blue,
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                fileType,
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'File: $fileName',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 24),
                                              isDownloading
                                                  ? const CircularProgressIndicator()
                                                  : ElevatedButton(
                                                      onPressed: () async {
                                                        try {
                                                          setState(() {
                                                            isDownloading =
                                                                true;
                                                          });

                                                          final String fileUrl =
                                                              cook['certifications'] ??
                                                                  '';
                                                          if (fileUrl.isEmpty) {
                                                            throw Exception(
                                                                'No certification file available');
                                                          }

                                                          // Download the file using Supabase Storage
                                                          final bytes = await Supabase
                                                              .instance
                                                              .client
                                                              .storage
                                                              .from(
                                                                  'certifications')
                                                              .download(
                                                                  'cooks certifications/$fileName');

                                                          // Use the web-compatible download function
                                                          await downloadFile(
                                                              bytes, fileName);

                                                          setState(() {
                                                            isDownloading =
                                                                false;
                                                          });

                                                          Navigator.of(context)
                                                              .pop(); // Close dialog

                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            const SnackBar(
                                                              content: Text(
                                                                  'File downloaded successfully!'),
                                                              backgroundColor:
                                                                  Colors.green,
                                                            ),
                                                          );
                                                        } catch (e) {
                                                          print(
                                                              'Download error: $e');
                                                          setState(() {
                                                            isDownloading =
                                                                false;
                                                          });
                                                          ScaffoldMessenger.of(
                                                                  context)
                                                              .showSnackBar(
                                                            SnackBar(
                                                              content: Text(
                                                                  'Error downloading file: $e'),
                                                              backgroundColor:
                                                                  Colors.red,
                                                            ),
                                                          );
                                                        }
                                                      },
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.blue,
                                                        padding:
                                                            const EdgeInsets
                                                                .symmetric(
                                                                horizontal: 32,
                                                                vertical: 16),
                                                      ),
                                                      child: const Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          Icon(Icons.download),
                                                          SizedBox(width: 8),
                                                          Text('Download File'),
                                                        ],
                                                      ),
                                                    ),
                                              const SizedBox(height: 8),
                                              TextButton(
                                                onPressed: isDownloading
                                                    ? null
                                                    : () {
                                                        Navigator.of(context)
                                                            .pop();
                                                      },
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              );
                            } catch (e) {
                              print('Error details: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content:
                                        Text('Error with certification: $e')),
                              );
                            }
                          },
                          child: const Text(
                            'View Certification',
                            style: TextStyle(
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          context,
                          'Are you sure you want to approve this cook?',
                        );
                        if (confirmed) {
                          await _approveCook(cook);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        final confirmed = await _showConfirmationDialog(
                          context,
                          'Are you sure you want to reject this cook?',
                        );
                        if (confirmed) {
                          await _rejectCook(cook);
                          Navigator.of(context).pop();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Reject'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _showConfirmationDialog(
      BuildContext context, String message) async {
    return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Confirmation'),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  Future<void> _approveCook(Map<String, dynamic> cook) async {
    try {
      await Supabase.instance.client
          .from('Local_Cook')
          .update({'is_accepted': true}).eq('localcookid', cook['localcookid']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cook successfully approved!')),
      );
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving cook: $e')),
      );
    }
  }

  Future<void> _rejectCook(Map<String, dynamic> cook) async {
    try {
      await Supabase.instance.client
          .from('Local_Cook')
          .delete()
          .eq('localcookid', cook['localcookid']);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cook successfully rejected!')),
      );
      _fetchCooks();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error rejecting cook: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Approval Page')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : hasError
              ? const Center(child: Text('Error loading data'))
              : ListView.builder(
                  itemCount: cooks.length,
                  itemBuilder: (context, index) {
                    final cook = cooks[index];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Icon(Icons.person, color: Colors.green[700]),
                        ),
                        title: Text(
                          '${cook['first_name'] ?? 'N/A'} ${cook['last_name'] ?? 'N/A'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        subtitle: Text(
                          'Age: ${cook['age'] ?? 'N/A'} | City: ${cook['city'] ?? 'N/A'}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _showCookDetailsDialog(context, cook),
                      ),
                    );
                  },
                ),
    );
  }
}
