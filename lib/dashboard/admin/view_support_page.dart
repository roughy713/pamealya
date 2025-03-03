import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class ViewSupportPage extends StatefulWidget {
  const ViewSupportPage({Key? key}) : super(key: key);

  @override
  _ViewSupportPageState createState() => _ViewSupportPageState();
}

class _ViewSupportPageState extends State<ViewSupportPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> supportRequests = [];
  bool isLoading = true;
  String? errorMessage;
  String statusFilter = 'All';
  String sortBy = 'Newest';
  String searchQuery = '';

  final TextEditingController _responseController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSupportRequests();
  }

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _fetchSupportRequests() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      // Create a base query
      final query = supabase.from('support_requests').select();

      // Apply status filter if not 'All'
      if (statusFilter != 'All') {
        query.eq('status', statusFilter.toLowerCase());
      }

      // Apply sorting
      if (sortBy == 'Newest') {
        query.order('timestamp', ascending: false);
      } else if (sortBy == 'Oldest') {
        query.order('timestamp', ascending: true);
      } else if (sortBy == 'Pending first') {
        query
            .order('status', ascending: false)
            .order('timestamp', ascending: false);
      }

      final data = await query;

      if (mounted) {
        setState(() {
          supportRequests = List<Map<String, dynamic>>.from(data);

          // Apply search filter locally if search query exists
          if (searchQuery.isNotEmpty) {
            supportRequests = supportRequests.where((request) {
              final email = request['email'] ?? '';
              final message = request['message'] ?? '';
              final issueType = request['issue_type'] ?? '';

              return email.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  message.toLowerCase().contains(searchQuery.toLowerCase()) ||
                  issueType.toLowerCase().contains(searchQuery.toLowerCase());
            }).toList();
          }

          isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          errorMessage = 'Error fetching support requests: $e';
          isLoading = false;
        });
      }
    }
  }

  Future<void> _updateSupportRequestStatus(
      String requestId, String newStatus) async {
    try {
      await supabase.from('support_requests').update({
        'status': newStatus,
        'resolved_at':
            newStatus == 'resolved' ? DateTime.now().toIso8601String() : null,
        'resolved_by':
            newStatus == 'resolved' ? supabase.auth.currentUser?.id : null,
      }).eq('request_id', requestId);

      _fetchSupportRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request status updated to $newStatus')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> _respondToSupportRequest(
      String requestId, String response) async {
    try {
      await supabase.from('support_requests').update({
        'admin_response': response,
        'status': 'in_progress',
      }).eq('request_id', requestId);

      _fetchSupportRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response submitted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting response: $e')),
      );
    }
  }

  void _showResponseDialog(String requestId, String existingResponse) {
    _responseController.text = existingResponse;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Respond to Support Request'),
        content: TextField(
          controller: _responseController,
          decoration: const InputDecoration(
            labelText: 'Your Response',
            border: OutlineInputBorder(),
          ),
          maxLines: 5,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_responseController.text.trim().isNotEmpty) {
                _respondToSupportRequest(
                    requestId, _responseController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Submit Response'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header and filters section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Support Requests',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    // Search field
                    Expanded(
                      flex: 3,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search by email, issue type, or content',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                        onSubmitted: (_) => _fetchSupportRequests(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Status filter
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Status',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 15),
                        ),
                        value: statusFilter,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              statusFilter = newValue;
                              _fetchSupportRequests();
                            });
                          }
                        },
                        items: ['All', 'Pending', 'In progress', 'Resolved']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(status),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Sort option
                    Expanded(
                      flex: 2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          labelText: 'Sort by',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 15),
                        ),
                        value: sortBy,
                        onChanged: (newValue) {
                          if (newValue != null) {
                            setState(() {
                              sortBy = newValue;
                              _fetchSupportRequests();
                            });
                          }
                        },
                        items: ['Newest', 'Oldest', 'Pending first']
                            .map((sort) => DropdownMenuItem(
                                  value: sort,
                                  child: Text(sort),
                                ))
                            .toList(),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Refresh button
                    ElevatedButton.icon(
                      onPressed: _fetchSupportRequests,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Refresh'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 15),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results section
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : errorMessage != null
                    ? Center(
                        child: Text(errorMessage!,
                            style: const TextStyle(color: Colors.red)))
                    : supportRequests.isEmpty
                        ? const Center(
                            child: Text('No support requests found.'))
                        : ListView.builder(
                            itemCount: supportRequests.length,
                            itemBuilder: (context, index) {
                              final request = supportRequests[index];
                              final requestId = request['request_id'];
                              final email = request['email'] ?? 'No email';
                              final issueType =
                                  request['issue_type'] ?? 'No issue type';
                              final message =
                                  request['message'] ?? 'No message';
                              final timestamp = request['timestamp'] != null
                                  ? DateTime.parse(request['timestamp'])
                                  : DateTime.now();
                              final formattedDate =
                                  DateFormat('MMM d, y - h:mm a')
                                      .format(timestamp);
                              final status = request['status'] ?? 'pending';
                              final adminResponse = request['admin_response'];
                              final userType =
                                  request['user_type'] ?? 'Unknown';

                              // Determine color based on status
                              Color statusColor;
                              switch (status) {
                                case 'pending':
                                  statusColor = Colors.orange;
                                  break;
                                case 'in_progress':
                                  statusColor = Colors.blue;
                                  break;
                                case 'resolved':
                                  statusColor = Colors.green;
                                  break;
                                default:
                                  statusColor = Colors.grey;
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: statusColor.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          // Left column: Request info
                                          Expanded(
                                            flex: 3,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    CircleAvatar(
                                                      backgroundColor:
                                                          statusColor
                                                              .withOpacity(0.2),
                                                      radius: 20,
                                                      child: Icon(
                                                        userType == 'cook'
                                                            ? Icons.restaurant
                                                            : Icons
                                                                .family_restroom,
                                                        color: statusColor,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            email,
                                                            style:
                                                                const TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 16,
                                                            ),
                                                          ),
                                                          Text(
                                                            'User Type: ${userType.toUpperCase()}',
                                                            style: TextStyle(
                                                              color: Colors
                                                                  .grey[600],
                                                              fontSize: 12,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                                  decoration: BoxDecoration(
                                                    color: Colors.grey[200],
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            4),
                                                  ),
                                                  child: Text(
                                                    issueType,
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: Colors.grey[800],
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                const Text(
                                                  'Message:',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(message),
                                                const SizedBox(height: 10),
                                                Text(
                                                  'Submitted: $formattedDate',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          const SizedBox(width: 16),

                                          // Right column: Status and actions
                                          Expanded(
                                            flex: 2,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 8,
                                                          vertical: 4),
                                                      decoration: BoxDecoration(
                                                        color: statusColor
                                                            .withOpacity(0.2),
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(4),
                                                      ),
                                                      child: Text(
                                                        status.toUpperCase(),
                                                        style: TextStyle(
                                                          color: statusColor,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    PopupMenuButton<String>(
                                                      onSelected: (value) {
                                                        if (value ==
                                                            'respond') {
                                                          _showResponseDialog(
                                                              requestId,
                                                              adminResponse ??
                                                                  '');
                                                        } else {
                                                          _updateSupportRequestStatus(
                                                              requestId, value);
                                                        }
                                                      },
                                                      itemBuilder: (context) =>
                                                          [
                                                        const PopupMenuItem(
                                                          value: 'respond',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons.reply),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text('Respond'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'pending',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons
                                                                  .hourglass_empty),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                  'Mark as Pending'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'in_progress',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons
                                                                  .pending_actions),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                  'Mark as In Progress'),
                                                            ],
                                                          ),
                                                        ),
                                                        const PopupMenuItem(
                                                          value: 'resolved',
                                                          child: Row(
                                                            children: [
                                                              Icon(Icons
                                                                  .check_circle),
                                                              SizedBox(
                                                                  width: 8),
                                                              Text(
                                                                  'Mark as Resolved'),
                                                            ],
                                                          ),
                                                        ),
                                                      ],
                                                      child: IconButton(
                                                        icon: const Icon(
                                                            Icons.more_vert),
                                                        onPressed: null,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 16),
                                                if (adminResponse != null &&
                                                    adminResponse
                                                        .isNotEmpty) ...[
                                                  const Text(
                                                    'Admin Response:',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 5),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.blue[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              4),
                                                      border: Border.all(
                                                          color: Colors
                                                              .blue[100]!),
                                                    ),
                                                    child: Text(adminResponse),
                                                  ),
                                                ] else ...[
                                                  ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _showResponseDialog(
                                                            requestId, ''),
                                                    icon:
                                                        const Icon(Icons.reply),
                                                    label:
                                                        const Text('Respond'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.blue,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 10),
                                                if (status != 'resolved') ...[
                                                  ElevatedButton.icon(
                                                    onPressed: () =>
                                                        _updateSupportRequestStatus(
                                                            requestId,
                                                            'resolved'),
                                                    icon: const Icon(
                                                        Icons.check_circle),
                                                    label: const Text(
                                                        'Mark Resolved'),
                                                    style: ElevatedButton
                                                        .styleFrom(
                                                      backgroundColor:
                                                          Colors.green,
                                                      foregroundColor:
                                                          Colors.white,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
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
