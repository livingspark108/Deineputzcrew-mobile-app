import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Lets an employee request time off (holiday / rest / sick / other) and see
/// the status of their past requests. Submitted requests start 'pending' and
/// need an admin to approve/reject them — this screen doesn't decide that.
class AvailabilityScreen extends StatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  State<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends State<AvailabilityScreen> {
  static const Map<String, String> _reasons = {
    'holiday': 'Holiday',
    'rest': 'Rest / Personal',
    'sick': 'Sick',
    'other': 'Other',
  };

  DateTime? _startDate;
  DateTime? _endDate;
  String _reason = 'holiday';
  final _noteController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoadingRequests = true;
  List<dynamic> _requests = [];

  // Leave proposals an admin created for this employee, awaiting their
  // approve/reject response.
  bool _isLoadingAdminRequests = true;
  List<dynamic> _adminRequests = [];
  final Set<dynamic> _respondingIds = {};

  @override
  void initState() {
    super.initState();
    _loadRequests();
    _loadAdminRequests();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  Future<void> _loadRequests() async {
    setState(() => _isLoadingRequests = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse('https://admin.deineputzcrew.de/api/availability/my-requests/'),
        headers: {'Authorization': 'token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => _requests = data['requests'] ?? []);
        }
      }
    } catch (_) {
      // Silent — the form above still works even if history fails to load.
    } finally {
      if (mounted) setState(() => _isLoadingRequests = false);
    }
  }

  Future<void> _loadAdminRequests() async {
    setState(() => _isLoadingAdminRequests = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http.get(
        Uri.parse(
            'https://admin.deineputzcrew.de/api/availability/admin-requests/?status=pending'),
        headers: {'Authorization': 'token $token'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          setState(() => _adminRequests = data['requests'] ?? []);
        }
      }
    } catch (_) {
      // Silent — same as _loadRequests, the rest of the screen still works.
    } finally {
      if (mounted) setState(() => _isLoadingAdminRequests = false);
    }
  }

  Future<void> _respondAdminRequest(dynamic id, String action,
      {String note = ''}) async {
    setState(() => _respondingIds.add(id));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http
          .post(
            Uri.parse(
                'https://admin.deineputzcrew.de/api/availability/admin-requests/$id/respond/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'token $token',
            },
            body: jsonEncode({'action': action, 'note': note}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'approve'
                  ? '✅ Request approved'
                  : '❌ Request rejected'),
              backgroundColor:
                  action == 'approve' ? Colors.green : Colors.red,
            ),
          );
        }
        await Future.wait([_loadAdminRequests(), _loadRequests()]);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text(data['error'] ?? 'Failed to respond to request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _respondingIds.remove(id));
    }
  }

  Future<void> _confirmRejectAdminRequest(dynamic id) async {
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reject request'),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Note for admin (optional)',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _respondAdminRequest(id, 'reject', note: noteController.text.trim());
    }
  }

  Future<void> _pickDate({required bool isStart}) async {
    final now = DateTime.now();
    final initial = isStart
        ? (_startDate ?? now)
        : (_endDate ?? _startDate ?? now);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked == null) return;

    setState(() {
      if (isStart) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(_startDate!)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both a start and end date')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      final response = await http
          .post(
            Uri.parse('https://admin.deineputzcrew.de/api/availability/request/'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'token $token',
            },
            body: jsonEncode({
              'start_date': _fmt(_startDate!),
              'end_date': _fmt(_endDate!),
              'reason': _reason,
              'note': _noteController.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Time off requested — awaiting admin approval'),
              backgroundColor: Colors.green,
            ),
          );
          setState(() {
            _startDate = null;
            _endDate = null;
            _reason = 'holiday';
            _noteController.clear();
          });
        }
        await _loadRequests();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Failed to submit request')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _statusBadge(String status) {
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = 'Approved';
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = 'Rejected';
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.orange.shade800;
        label = 'Pending';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAdminRequestCard(dynamic r) {
    final id = r['id'];
    final isResponding = _respondingIds.contains(id);
    final requestedBy = (r['requested_by_name'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${r['start_date']} → ${r['end_date']}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              _statusBadge(r['status'] ?? 'pending'),
            ],
          ),
          const SizedBox(height: 4),
          Text(_reasons[r['reason']] ?? r['reason'] ?? '',
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (requestedBy.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text('Requested by: $requestedBy',
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ],
          if ((r['note'] ?? '').toString().isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(r['note'], style: const TextStyle(fontSize: 12)),
          ],
          const SizedBox(height: 10),
          if (isResponding)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  height: 20, width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _confirmRejectAdminRequest(id),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondAdminRequest(id, 'approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: const Text('Approve', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text('Time Off / Availability',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
      ),
      body: RefreshIndicator(
        onRefresh: () => Future.wait([_loadRequests(), _loadAdminRequests()]),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoadingAdminRequests)
              const Padding(
                padding: EdgeInsets.only(bottom: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_adminRequests.isNotEmpty) ...[
              const Text('Requests from your admin',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text(
                'Your admin proposed time off for you. Review and respond below.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ..._adminRequests.map((r) => _buildAdminRequestCard(r)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
            ],

            const Text('Request time off',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
              'Let your admin know you\'ll be on holiday, resting, or otherwise unavailable. They\'ll review and approve it.',
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null ? 'Start date' : _fmt(_startDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(_endDate == null ? 'End date' : _fmt(_endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _reason,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
              items: _reasons.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'holiday'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 18, width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit request'),
              ),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            const Text('Your requests',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            if (_isLoadingRequests)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (_requests.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No requests yet.', style: TextStyle(color: Colors.black54)),
              )
            else
              ..._requests.map((r) => Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${r['start_date']} → ${r['end_date']}',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            _statusBadge(r['status'] ?? 'pending'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(_reasons[r['reason']] ?? r['reason'] ?? '',
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        if (r['is_admin_initiated'] == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Requested by: ${r['requested_by_name'] ?? 'your admin'}',
                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic),
                          ),
                        ],
                        if ((r['note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r['note'], style: const TextStyle(fontSize: 12)),
                        ],
                        if (r['status'] != 'pending' && (r['admin_note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('Admin note: ${r['admin_note']}',
                              style: const TextStyle(fontSize: 11, color: Colors.black45, fontStyle: FontStyle.italic)),
                        ],
                      ],
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
