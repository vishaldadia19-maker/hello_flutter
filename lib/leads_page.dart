//import 'dart:io'; // ✅ REQUIRED
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:hello_flutter/models/lead_model.dart';
import 'package:hello_flutter/services/lead_service.dart';
//import 'package:android_intent_plus/android_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_flutter/utils/user_session.dart';
import 'package:hello_flutter/screens/followup_history_page.dart';
import 'package:hello_flutter/services/status_service.dart';
import 'package:hello_flutter/services/lost_reason_service.dart';
import 'package:hello_flutter/services/whatsapp_template_service.dart';





class LeadsPage extends StatefulWidget {
  final int bdmId;
  final String? reportType; // 👈 optional
  final String? reportStatus;   // Call Not Received / Cold / Fresh etc
  final int? leadId;



  const LeadsPage({
  Key? key,
  required this.bdmId,
  this.reportType,
  this.reportStatus,
  this.leadId,
}) : super(key: key);


  @override
  _LeadsPageState createState() => _LeadsPageState();
}

class _LeadsPageState extends State<LeadsPage>
    with WidgetsBindingObserver {

  List<LeadModel> leads = [];
  bool isLoading = false;
  bool hasMore = true;

  int limit = 10;
  int offset = 0;

  DateTime? _callStartTime;


  LeadModel? _lastCalledLead;
  bool _waitingForCallReturn = false;



  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    if (widget.leadId != null) {
        loadLeadById(widget.leadId!); // 🔥 notification case
    } else {
        loadMoreLeads(); // normal listing
    }    
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }




@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed &&
      _waitingForCallReturn &&
      _lastCalledLead != null &&
      _callStartTime != null) {

    final duration = DateTime.now().difference(_callStartTime!);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;

    _waitingForCallReturn = false;
    _callStartTime = null;

    showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => FollowupLookOnly(
        leadId: _lastCalledLead!.leadId,
        initialMinutes: minutes,
        initialSeconds: seconds,
      ),
    ).then((removedLeadId) {
      if (removedLeadId != null && mounted) {
        setState(() {
          leads.removeWhere((l) => l.leadId == removedLeadId);
        });
      }
    });
  }
}

Future<void> loadLeadById(int leadId) async {
  debugPrint('🟡 loadLeadById CALLED with leadId=$leadId');

  setState(() => isLoading = true);

  try {
    final response = await http.post(
      Uri.parse('https://backoffice.thecubeclub.co/apis/lead_listing.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "bdm_id":0,
        "lead_id": leadId.toString(),
        "report_type": "search_lead"
      }),
    );

    final data = jsonDecode(response.body);

    debugPrint('🟡 API RESPONSE: ${response.body}');


    if (data['status'] == 'success' && data['data'] != null) {
      final List list = data['data'];

      setState(() {
        leads = list.map((e) => LeadModel.fromJson(e)).toList();
        hasMore = false; // 🔴 disable pagination
      });
    }
  } catch (e) {
    debugPrint('Error loading lead: $e');
  } finally {
    setState(() => isLoading = false);
  }
}



  Future<void> loadMoreLeads() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);

    final newLeads = await LeadService.fetchLeads(
      offset: offset,
      limit: limit,
      reportType: widget.reportType, 
      reportStatus: widget.reportStatus, // 👈 ADD THIS

    );

    setState(() {
      leads.addAll(newLeads);
      offset += newLeads.length;
      isLoading = false;
      if (newLeads.length < limit) hasMore = false;
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Leads Information")),
      body: NotificationListener<ScrollNotification>(
        onNotification: (scrollInfo) {
          if (widget.leadId == null && !isLoading &&
              hasMore &&
              scrollInfo.metrics.pixels ==
                  scrollInfo.metrics.maxScrollExtent) {
            loadMoreLeads();
          }
          return false;
        },
        child: ListView.builder(
          itemCount: leads.length + (hasMore ? 1 : 0),
          itemBuilder: (context, index) {
            if (index < leads.length) {
              return LeadCard(
                  lead: leads[index],
                  onCallStarted: (lead) {
                    _lastCalledLead = lead;
                    _waitingForCallReturn = true;
                    _callStartTime = DateTime.now(); // ✅ ADD THIS

                  },
                  onLeadRemoved: (leadId) {
                    setState(() {
                      leads.removeWhere((l) => l.leadId == leadId);
                    });
                  },
                );
              
            } else {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
      ),
    );
  }
}

/* ====================== LEAD CARD ====================== */

class LeadCard extends StatelessWidget {
  final LeadModel lead;
  final void Function(int leadId) onLeadRemoved;
  final void Function(LeadModel lead) onCallStarted;



  //const LeadCard({required this.lead});

  const LeadCard({
    Key? key,
    required this.lead,
    required this.onLeadRemoved,
    required this.onCallStarted,
  }) : super(key: key);


  String getInitials(String name) {
  if (name.trim().isEmpty) return "NA";

  final parts = name
      .trim()
      .split(RegExp(r'\s+')) // 👈 handles multiple spaces
      .where((p) => p.isNotEmpty)
      .toList();

  if (parts.length >= 2) {
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  return parts[0][0].toUpperCase();
}


  String _cleanPhone(String? phone) {
    if (phone == null) return '';
    return phone.replaceAll(RegExp(r'[^0-9]'), '');
  }

  List<String> getDisplayNumbers() {
    final p1 = _cleanPhone(lead.contactNo);
    final p2 = _cleanPhone(lead.contactNo2);

    final List<String> numbers = [];

    if (p1.isNotEmpty) {
      numbers.add(lead.contactNo);
    }

    if (p2.isNotEmpty && p2 != p1) {
      numbers.add(lead.contactNo2!);
    }

    return numbers;
  }
  

  String normalizePhone(String phone) {
    String p = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (!p.startsWith('+') && p.length == 10) {
      p = '+91$p';
    }
    return p;
  }

  Future<void> makeCall(BuildContext context, String phone) async {
    final String finalPhone = normalizePhone(phone);
    final Uri uri = Uri.parse("tel:$finalPhone");

    debugPrint("DIALING => $uri");

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to make call')),
      );
    }
  }


void _showCallChooser(BuildContext context, List<String> numbers) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: numbers.map((n) {
          return ListTile(
            leading: const Icon(Icons.call),
            title: Text(n),
            onTap: () {
              Navigator.pop(context);
              makeCall(context, n);
            },
          );
        }).toList(),
      ),
    ),
  );
}


Future<void> openWhatsApp(BuildContext context, String phone, String name) async {
  String cleanPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');

  if (cleanPhone.length == 10) {
    cleanPhone = '91$cleanPhone';
  }

  final message = '''
Hello $name,

This is regarding your inquiry with The Cube Club.
Please let me know a good time to connect.

Thanks,
${UserSession.userName ?? ''}
''';

  final Uri url = Uri.parse(
    'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
  );

  try {
    await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('WhatsApp not installed')),
    );
  }
}



  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// -------- TOP ROW --------
            Row(
              children: [
                  
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      /// NAME + FOLLOW-UP + STATUS
                      Row(
                        children: [
                          /// Client Name
                          Expanded(
                            child: Text(
                              lead.clientName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                          /// Follow-up Button
                          IconButton(
                            icon: const Icon(
                              Icons.call, // ✅ relatable follow-up icon
                              size: 20,
                              color: Colors.blue,
                            ),
                            tooltip: 'Follow-up',
                            visualDensity: VisualDensity.compact, // 👈 saves space
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () async {
                              final removedLeadId = await showModalBottomSheet<int>(
                                context: context,
                                isScrollControlled: true,
                                shape: const RoundedRectangleBorder(
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                                ),
                                builder: (_) => FollowupLookOnly(
                                  leadId: lead.leadId,
                                ),
                              );

                              if (removedLeadId != null) {
                                onLeadRemoved(removedLeadId);
                              }
                            },
                          ),

                          const SizedBox(width: 6),

                          /// Status Badge
                          Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                                lead.status,
                                style: const TextStyle(
                                  fontSize: 10,           // 👈 smaller
                                  color: Colors.orange,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),

                          ),
                        ],
                      ),

                      /// CONTACT NUMBER (UNCHANGED)
/// CONTACT NUMBER
const SizedBox(height: 4),

Builder(
  builder: (context) {
    final numbers = getDisplayNumbers();
    final city = lead.city?.trim() ?? '';


    if (numbers.isNotEmpty) {
      return Column(
        children: numbers.map((num) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /// PHONE NUMBER (LEFT)
              Expanded(
                child: Text(
                  num,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              /// CITY (RIGHT)
              if (lead.city.isNotEmpty)
                Text(
                  city,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
            ],
          );
        }).toList(),
      );

    }

    return const Text(
      'No contact number',
      style: TextStyle(fontSize: 13, color: Colors.grey),
    );
  },
),
                      
                      

                    

                    ],
                  ),
                ),
                
              ],
            ),

            /// -------- SOURCE --------
            if (lead.source.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "📍 ${lead.source}",
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            /// -------- REMARKS --------
            if (lead.lastRemarks != null && lead.lastRemarks!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "📝 ${lead.lastRemarks}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                ),
              ),
            ],

            /// -------- NEXT FOLLOW UP --------
            if (lead.nextFollowUp != null &&
                lead.nextFollowUp!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                "📅 Next Follow-up: ${lead.nextFollowUp}",
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],

            const Divider(height: 20),

            /// -------- ACTIONS --------
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                  IconButton(
                    icon: const Icon(Icons.call, color: Colors.green),
                    onPressed: () {
                      final numbers = getDisplayNumbers();

                      if (numbers.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('No contact number available')),
                        );
                        return;
                      }

                      onCallStarted(lead);

                      if (numbers.length == 1) {
                        makeCall(context, numbers[0]); // safe
                      } else {
                        _showCallChooser(context, numbers);
                      }
                    },
                  ),                
                IconButton(
                  icon: const Icon(Icons.history, color: Colors.blue),
                  tooltip: 'Follow-up History',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FollowupHistoryPage(
                          leadId: lead.leadId,
                          clientName: lead.clientName,
                        ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.chat,
                    color: Colors.green, // WhatsApp feel
                  ),
                  onPressed: () => openWhatsApp(
                    context,
                    lead.contactNo,
                    lead.clientName,
                  ),
                ),
                
                /// ✅ NEW: WhatsApp Template Button (Design Only)
                _WhatsAppTemplateButton(
                  onTap: () {
                    showWhatsAppTemplateSheet(context, lead.leadId);
                  },
                ),  

              ],
            ),
            
          ],
        ),
      ),
    );
  }
}

class _WhatsAppTemplateButton extends StatelessWidget {
  final VoidCallback onTap;

  const _WhatsAppTemplateButton({required this.onTap});


  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFE7F6EE),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF25D366),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.chat,
              size: 18,
              color: Color(0xFF25D366),
            ),
            SizedBox(width: 6),
            Text(
              'Template',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF128C7E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showWhatsAppTemplateSheet(
  BuildContext context,
  int leadId,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => WhatsAppTemplateSheet(leadId: leadId),
  );
}


class WhatsAppTemplateSheet extends StatefulWidget {
  final int leadId;

  const WhatsAppTemplateSheet({
    super.key,
    required this.leadId,
  });

  @override
  State<WhatsAppTemplateSheet> createState() =>
      _WhatsAppTemplateSheetState();
}





class _WhatsAppTemplateSheetState extends State<WhatsAppTemplateSheet> {
  final TextEditingController searchCtrl = TextEditingController();

  List<Map<String, dynamic>> allTemplates = []; // id + name
  List<Map<String, dynamic>> filteredTemplates = [];

  Map<String, dynamic>? selectedTemplate;

  bool isLoading = true;
  bool isSending = false;

  @override
  void initState() {
    super.initState();
    loadTemplates();              // ✅ correct
    searchCtrl.addListener(_filterTemplates); // ✅ correct
  }

  @override
  void dispose() {
    searchCtrl.dispose();         // ✅ very important
    super.dispose();
  }  


Future<void> loadTemplates() async {
  try {
    final list = await WhatsAppTemplateService.getTemplates();

    setState(() {
      allTemplates = List<Map<String, dynamic>>.from(list);
      filteredTemplates = allTemplates;
      isLoading = false;
    });
  } catch (e) {
    setState(() => isLoading = false);
  }
}



  
  

Future<void> sendTemplate() async {
  if (selectedTemplate == null || isSending) return;

  setState(() => isSending = true);

  try {
    final res = await http.post(
      Uri.parse(
        'https://backoffice.thecubeclub.co/apis/send_whatsapp_template.php',
      ),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'lead_id': widget.leadId,
        'template_id': selectedTemplate!['id'],
      }),
    );

    final data = jsonDecode(res.body);

    if (data['status'] == 'success') {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(data['message'] ?? 'WhatsApp sent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      _showError(data['message']);
    }
  } catch (e) {
    _showError('Network error. Please try again');
  } finally {
    setState(() => isSending = false);
  }
}

void _showError(String? msg) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(msg ?? 'Something went wrong'),
      backgroundColor: Colors.red,
    ),
  );
}

  

  void _filterTemplates() {
    final q = searchCtrl.text.toLowerCase();

    setState(() {
      filteredTemplates = allTemplates
          .where(
            (t) => t['name']
                .toString()
                .toLowerCase()
                .contains(q),
          )
          .toList();
    });
  }
  

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      maxChildSize: 0.75,
      minChildSize: 0.4,
      builder: (_, controller) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(context),
              const SizedBox(height: 12),

              /// 🔍 SEARCH
              TextField(
                controller: searchCtrl,
                decoration: const InputDecoration(
                  hintText: 'Search template',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 12),

              /// LIST
              Expanded(
                child: isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : filteredTemplates.isEmpty
                        ? const Center(
                            child: Text('No templates found'),
                          )
                        : ListView.builder(
                            controller: controller,
                            itemCount: filteredTemplates.length,
                            itemBuilder: (_, index) {
                              final t = filteredTemplates[index];
                              final isSelected = selectedTemplate?['id'] == t['id'];

                              return InkWell(
                                onTap: () {
                                  setState(() => selectedTemplate = t);
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(vertical: 6),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFFE7F6EE)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF25D366)
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                  child: Text(
                                    t['name'], // ✅ FIXED
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              );
                            },
                            
                          ),
              ),

              _sendButton(),
            ],
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const Expanded(
          child: Text(
            'Send WhatsApp Template',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        InkWell(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _sendButton() {
    return SafeArea(
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed:
              selectedTemplate == null || isSending ? null : sendTemplate,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isSending
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  'Send WhatsApp',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }

}






class FollowupLookOnly extends StatefulWidget {
  final int leadId; // ✅ ADD THIS

  // ✅ ADD THESE
  final int initialMinutes;
  final int initialSeconds;  

  const FollowupLookOnly({
    Key? key,
    required this.leadId, // ✅ REQUIRED
    this.initialMinutes = 0,
    this.initialSeconds = 0,    
  }) : super(key: key);

  @override
  State<FollowupLookOnly> createState() => _FollowupLookOnlyState();
}



class _FollowupLookOnlyState extends State<FollowupLookOnly> {

  bool isSubmitting = false;
  bool get isLost => selectedStatus == 'Lost';


  bool get isCallConversation =>
    selectedActivity == 'Call Conversation';


  List<String> lostReasons = [];
  String? selectedLostReason;
  bool isLostReasonLoading = false;


 Future<void> loadStatuses() async {
    setState(() => isStatusLoading = true);

    try {
      statuses = await StatusService.getStatuses();
      selectedStatus = statuses.isNotEmpty ? statuses.first : null;
    } catch (e) {
      _showToast(context, 'Unable to load status');
    } finally {
      setState(() => isStatusLoading = false);
    }
  }

  Future<void> loadLostReasons() async {
    setState(() => isLostReasonLoading = true);

    try {
      lostReasons = await LostReasonService.getReasons();
    } catch (e) {
      _showToast(context, 'Failed to load lost reasons');
    } finally {
      setState(() => isLostReasonLoading = false);
    }
  }




    @override
      void initState() {
        super.initState();
        loadStatuses();

        // ✅ AUTO-FILL CALL DURATION
        callMinutes = widget.initialMinutes;
        callSeconds = widget.initialSeconds;        
      }



  /// Followup Activity
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

  /// Status
  
  List<String> statuses = [];
  String? selectedStatus;
  bool isStatusLoading = false;


  /// Call Duration
  int callMinutes = 0;
  int callSeconds = 0;

  /// Date + Time
  DateTime? nextFollowupDateTime;

  /// Remarks
  final TextEditingController remarksCtrl = TextEditingController();

  // ===========================
  // ✅ COPY SUBMIT FUNCTION HERE

    Future<void> submitFollowup(BuildContext context) async {

      if (selectedStatus == 'Lost' && selectedLostReason == null) {
        _showToast(context, 'Please select lost reason');
        return;
      }
      
      if (isSubmitting) return;

      if (!isLost && nextFollowupDateTime == null) {
        _showToast(context, 'Please select next follow-up date & time');
        return;
      }
     

      setState(() => isSubmitting = true);

      try {
        final payload = {
          "lead_id": widget.leadId ?? 0, // if you pass leadId
          "bdm_id": UserSession.bdmId,
          "call_activity": selectedActivity,
          "status": selectedStatus,
          "next_fup_date": isLost
              ? null
              : _formatDateTimeForApi(nextFollowupDateTime!),
          "remarks": remarksCtrl.text,
          "call_minutes": callMinutes,
          "call_seconds": callSeconds,
          "lost_reason": selectedStatus == 'Lost' ? selectedLostReason : null,

        };

        final response = await http.post(
          Uri.parse('https://backoffice.thecubeclub.co/apis/add_followup.php'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        );

        final data = jsonDecode(response.body);

        if (data['status'] == 'success') {
          _showToast(context, 'Follow-up added successfully');
          Navigator.pop(context, widget.leadId); // close popup
        } else {
          _showToast(context, data['message'] ?? 'Something went wrong');
        }
      } catch (e) {
        _showToast(context, 'Network error. Please try again');
      } finally {
        setState(() => isSubmitting = false);
      }
    }

  // ===========================

  void _showToast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

String _formatDateTimeForApi(DateTime dt) {
  return '${dt.year}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}:00';
}


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _dragHandle(),

            const Text(
              'Add Follow-up',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            /// FOLLOWUP ACTIVITY
            DropdownButtonFormField<String>(
              value: selectedActivity,
              decoration: _input('Followup Activity'),
              items: activities
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  selectedActivity = v!;

                  // 👇 Reset call duration if not Call Conversation
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
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                          onChanged: (v) {
                            setState(() {
                              selectedStatus = v;

                              if (isLost) {
                                selectedLostReason ??= null;
                                nextFollowupDateTime = null; // ✅ CLEAR DATE
                              } else {
                                selectedLostReason = null;
                              }
                            });

                            if (v == 'Lost' && lostReasons.isEmpty) {
                              loadLostReasons();
                            }
                          },
                      
                    ),

                    /// LOST REASON (ONLY WHEN STATUS = LOST)
                    if (selectedStatus == 'Lost') ...[
                      const SizedBox(height: 12),

                      isLostReasonLoading
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<String>(
                              value: selectedLostReason,
                              decoration: _input('Reason'),
                              items: lostReasons
                                  .map(
                                    (e) => DropdownMenuItem(
                                      value: e,
                                      child: Text(e),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) => setState(() => selectedLostReason = v),
                            ),
                    ],


            const SizedBox(height: 12),

            /// CALL DURATION (ONLY FOR CALL CONVERSATION)
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

            /// DATE + TIME (HIDE WHEN LOST)
            if (!isLost) ...[
              _dateTimeField(context),
              const SizedBox(height: 12),
            ],


            /// REMARKS + LOAD PREVIOUS
            _remarksSection(),

            const SizedBox(height: 16),

            /// ACTIONS
            _actions(context),
          ],
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

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
        final DateTime? date = await showDatePicker(
          context: context,
          firstDate: DateTime.now(),
          lastDate: DateTime(2035),
          initialDate: DateTime.now(),
        );

        if (date == null) return;

        final TimeOfDay? time = await showTimePicker(
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

  Widget _remarksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Remarks',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        TextField(
          controller: remarksCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Enter remarks',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _actions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        
        ElevatedButton(
          onPressed: isSubmitting ? null : () => submitFollowup(context),
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


        const SizedBox(width: 10),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ],
    );
  }

  Widget _dragHandle() {
    return Center(
      child: Container(
        height: 4,
        width: 40,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  InputDecoration _input(String label) {
    return const InputDecoration(
      labelText: '',
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
}


