import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:hello_flutter/services/status_service.dart';
import 'package:hello_flutter/utils/user_session.dart';
import 'package:hello_flutter/leads_page.dart';

class NewLeadEntryPage extends StatefulWidget {
  const NewLeadEntryPage({Key? key}) : super(key: key);

  @override
  State<NewLeadEntryPage> createState() => _NewLeadEntryPageState();
}

class _NewLeadEntryPageState extends State<NewLeadEntryPage> {
  final _formKey = GlobalKey<FormState>();

  /// BASIC FIELDS
  final TextEditingController clientNameCtrl = TextEditingController();
  final TextEditingController mobileCtrl = TextEditingController();
  final TextEditingController remarksCtrl = TextEditingController();

  bool isSubmitting = false;

  /// FOLLOWUP ACTIVITY
  String selectedActivity = 'Call Conversation';
  final List<String> activities = [
    'Only Update Entry',
    'Call Conversation',
    'Number Switched off',
    'Call Not Received',
    'Office Visit Done',
    'Site Visit Done',
    'Office Visit Scheduled',
    'Site Visit Scheduled',
    'Token Amount Received',
    'Follow Up Done for Office Visit',
  ];

  bool get isCallConversation =>
      selectedActivity == 'Call Conversation';

  /// STATUS
  List<String> statuses = [];
  String? selectedStatus;
  bool isStatusLoading = false;

  /// CALL DURATION
  int callMinutes = 0;
  int callSeconds = 0;

  /// DATE + TIME
  DateTime? nextFollowupDateTime;

  @override
  void initState() {
    super.initState();
    loadStatuses();
  }

  Future<void> loadStatuses() async {
    setState(() => isStatusLoading = true);
    try {
      statuses = await StatusService.getStatuses();
      selectedStatus = statuses.isNotEmpty ? statuses.first : null;
    } catch (e) {
      _showToast('Unable to load status');
    } finally {
      setState(() => isStatusLoading = false);
    }
  }

  // ================= SUBMIT =================

  Future<void> submitLead() async {
    if (!_formKey.currentState!.validate()) return;

    if (nextFollowupDateTime == null) {
      _showToast('Please select next follow-up date & time');
      return;
    }

    if (isSubmitting) return;
    setState(() => isSubmitting = true);

    final payload = {
      "bdm_id": UserSession.bdmId,
      "client_name": clientNameCtrl.text.trim(),
      "contact_no": mobileCtrl.text.trim(),
      "call_activity": selectedActivity,
      "status": selectedStatus,
      "call_timing_1": callMinutes.toString(),
      "call_timing_2": callSeconds.toString(),
      "next_fup_date": _formatDateTimeForApi(nextFollowupDateTime!),
      "remarks": remarksCtrl.text.trim(),
    };

    try {
      final response = await http.post(
        Uri.parse('https://backoffice.thecubeclub.co/apis/save_new_lead.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final data = jsonDecode(response.body);

      if (data['success'] == true) {
        _showToast('Lead saved successfully');

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => LeadsPage(
              bdmId: UserSession.bdmId!,
              reportType: "search mobile",           // ✅ SAME AS DASHBOARD
              reportStatus: mobileCtrl.text.trim(),  // ✅ MOBILE NUMBER
            ),
          ),
        );
      }
       else {
        _showToast(data['message'] ?? 'Something went wrong');
      }
    } catch (e) {
      _showToast('Network error. Please try again');
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Lead Entry')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              /// CLIENT NAME
              TextFormField(
                controller: clientNameCtrl,
                decoration: _input('Client Name'),
              ),

              const SizedBox(height: 12),

              /// MOBILE NO
              TextFormField(
                controller: mobileCtrl,
                keyboardType: TextInputType.phone,
                decoration: _input('Mobile No'),
                validator: (v) =>
                    v == null || v.length < 10 ? 'Invalid mobile number' : null,
              ),

              const SizedBox(height: 16),

              /// FOLLOWUP ACTIVITY
              DropdownButtonFormField<String>(
                value: selectedActivity,
                decoration: _input('Followup Activity'),
                items: activities
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    selectedActivity = v!;
                    if (!isCallConversation) {
                      callMinutes = 0;
                      callSeconds = 0;
                    }
                  });
                },
              ),

              const SizedBox(height: 12),

              /// STATUS
              isStatusLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<String>(
                      value: selectedStatus,
                      decoration: _input('Status'),
                      items: statuses
                          .map((e) =>
                              DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => selectedStatus = v),
                    ),

              const SizedBox(height: 12),

              /// CALL DURATION
              if (isCallConversation) ...[
                Row(
                  children: [
                    Expanded(child: _minutesDropdown()),
                    const SizedBox(width: 10),
                    Expanded(child: _secondsDropdown()),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              /// NEXT FOLLOW-UP DATE & TIME
              _dateTimeField(context),

              const SizedBox(height: 12),

              /// REMARKS
              TextField(
                controller: remarksCtrl,
                maxLines: 3,
                decoration: _input('Remarks'),
              ),

              const SizedBox(height: 20),

              /// ACTIONS
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: isSubmitting ? null : submitLead,
                    child: isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit'),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _minutesDropdown() {
    return DropdownButtonFormField<int>(
      value: callMinutes,
      decoration: _input('Call (Minutes)'),
      items: List.generate(
        61,
        (i) => DropdownMenuItem(value: i, child: Text('$i')),
      ),
      onChanged: (v) => setState(() => callMinutes = v!),
    );
  }

  Widget _secondsDropdown() {
    return DropdownButtonFormField<int>(
      value: callSeconds,
      decoration: _input('Call (Seconds)'),
      items: List.generate(
        60,
        (i) => DropdownMenuItem(value: i, child: Text('$i')),
      ),
      onChanged: (v) => setState(() => callSeconds = v!),
    );
  }

  Widget _dateTimeField(BuildContext context) {
    return TextFormField(
      readOnly: true,
      decoration: _input('Next Follow-up Date & Time').copyWith(
        suffixIcon: const Icon(Icons.calendar_today, size: 18),
      ),
      controller: TextEditingController(
        text: nextFollowupDateTime == null
            ? ''
            : _formatDateTime(nextFollowupDateTime!),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2035),
          initialDate: DateTime.now(),
        );

        if (date == null) return;

        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.now(),
        );

        if (time == null) return;

        setState(() {
          nextFollowupDateTime = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      },
    );
  }

  InputDecoration _input(String label) {
    return const InputDecoration(
      border: OutlineInputBorder(),
      isDense: true,
    ).copyWith(labelText: label);
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTimeForApi(DateTime dt) {
    return '${dt.year}-'
        '${dt.month.toString().padLeft(2, '0')}-'
        '${dt.day.toString().padLeft(2, '0')} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:00';
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}
