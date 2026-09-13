import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'l10n/app_localizations.dart';

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

  /// Display label for a reason key ('holiday'/'rest'/'sick'/'other') — the
  /// key itself is what's sent to the API and stays unchanged regardless of
  /// language; only what the user sees is localized.
  String _reasonLabel(AppLocalizations l10n, String key) {
    switch (key) {
      case 'holiday':
        return l10n.reasonDropdownValue;
      case 'rest':
        return l10n.reasonDropdownValue2;
      case 'sick':
        return l10n.reasonDropdownValue3;
      case 'other':
        return l10n.reasonDropdownValue4;
      default:
        return _reasons[key] ?? key;
    }
  }

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

      final l10n = AppLocalizations.of(context);
      if (response.statusCode == 200 && data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(action == 'approve'
                  ? l10n.snackbarAfterApprove
                  : l10n.snackbarAfterReject),
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
                content: Text(
                    data['error'] ?? l10n.fallbackErrorRespondingToAdminRequest)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).exceptionSnackbar(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _respondingIds.remove(id));
    }
  }

  Future<void> _confirmRejectAdminRequest(dynamic id) async {
    final l10n = AppLocalizations.of(context);
    final noteController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.rejectRequestDialogTitle),
        content: TextField(
          controller: noteController,
          maxLines: 3,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.rejectRequestDialogNoteFieldLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.dialogCancelButton),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.adminRequestCardRejectButton, style: const TextStyle(color: Colors.white)),
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
    final l10n = AppLocalizations.of(context);
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.validationSnackbarMissingDates)),
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
            SnackBar(
              content: Text(l10n.submitSuccessSnackbar2),
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
            SnackBar(content: Text(data['error'] ?? l10n.submitFailureFallbackSnackbar)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).exceptionSnackbar(e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Widget _statusBadge(String status) {
    final l10n = AppLocalizations.of(context);
    Color bg;
    Color fg;
    String label;
    switch (status) {
      case 'approved':
        bg = Colors.green.shade50;
        fg = Colors.green.shade700;
        label = l10n.statusBadge;
        break;
      case 'rejected':
        bg = Colors.red.shade50;
        fg = Colors.red.shade700;
        label = l10n.statusBadge2;
        break;
      default:
        bg = Colors.amber.shade50;
        fg = Colors.orange.shade800;
        label = l10n.tabLabel;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildAdminRequestCard(dynamic r) {
    final l10n = AppLocalizations.of(context);
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
          Text(_reasonLabel(l10n, r['reason'] ?? ''),
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
          if (requestedBy.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(l10n.adminRequestCardRequestedByLine(requestedBy),
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
                    child: Text(l10n.adminRequestCardRejectButton),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _respondAdminRequest(id, 'approve'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    child: Text(l10n.adminRequestCardApproveButton, style: const TextStyle(color: Colors.white)),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(l10n.appbarTitle2,
            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
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
              Text(l10n.adminProposalsSectionHeading,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                l10n.adminProposalsSubheading,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 12),
              ..._adminRequests.map((r) => _buildAdminRequestCard(r)),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 16),
            ],

            Text(l10n.requestTimeOffSectionHeading,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              l10n.subheadingUnderRequestTimeOff,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: true),
                    child: Text(_startDate == null ? l10n.startDateButtonPlaceholder : _fmt(_startDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _pickDate(isStart: false),
                    child: Text(_endDate == null ? l10n.endDateButtonPlaceholder : _fmt(_endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _reason,
              decoration: InputDecoration(
                labelText: l10n.reasonDropdownFieldLabel,
                border: const OutlineInputBorder(),
              ),
              items: _reasons.keys
                  .map((key) => DropdownMenuItem(value: key, child: Text(_reasonLabel(l10n, key))))
                  .toList(),
              onChanged: (v) => setState(() => _reason = v ?? 'holiday'),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: l10n.noteFieldLabel,
                border: const OutlineInputBorder(),
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
                    : Text(l10n.submitButton3),
              ),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 8),
            Text(l10n.yourRequestsSectionHeading,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),

            if (_isLoadingRequests)
              const Center(child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ))
            else if (_requests.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(l10n.emptyStateText, style: const TextStyle(color: Colors.black54)),
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
                        Text(_reasonLabel(l10n, r['reason'] ?? ''),
                            style: const TextStyle(fontSize: 12, color: Colors.black54)),
                        if (r['is_admin_initiated'] == true) ...[
                          const SizedBox(height: 4),
                          Text(
                            l10n.adminRequestCardRequestedByLine(
                                r['requested_by_name'] ?? l10n.adminRequestCardDefaultAdminNameFallback),
                            style: const TextStyle(fontSize: 11, color: Colors.blue, fontStyle: FontStyle.italic),
                          ),
                        ],
                        if ((r['note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(r['note'], style: const TextStyle(fontSize: 12)),
                        ],
                        if (r['status'] != 'pending' && (r['admin_note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(l10n.adminRequestCardAdminNotePrefix(r['admin_note']),
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
