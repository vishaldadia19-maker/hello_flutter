import 'package:flutter/material.dart';
import '../models/site_visit_model.dart';
import '../services/site_visit_service.dart';
import 'site_visit_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/user_session.dart'; // if not already
import 'site_visit_summary_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';


class SiteVisitListScreen extends StatefulWidget {
  final String? selectedDate; // ✅ ADD
  
 const SiteVisitListScreen({
    super.key,
    this.selectedDate, // ✅ FIX
  });  

  @override
  State<SiteVisitListScreen> createState() => _SiteVisitListScreenState();
}

class _SiteVisitListScreenState extends State<SiteVisitListScreen> {
  List<SiteVisitModel> visits = [];
  bool isLoading = true;
  int page = 1;
  bool hasMore = true;

  final String baseUrl = "https://backoffice.thecubeclub.co/apis/";


  @override
  void initState() {
    super.initState();
    fetchData();
  }



Future<void> fetchData({bool loadMore = false}) async {
  if (loadMore) page++;

  int userId = UserSession.bdmId ?? 0;

  final data = await SiteVisitService.fetchVisits(
    page: page,
    userId: userId,
    fromDate: widget.selectedDate, // ✅ ADD
    toDate: widget.selectedDate,   // ✅ ADD    
  );

  setState(() {
    if (loadMore) {
      visits.addAll(data);
    } else {
      visits = data;
    }

    isLoading = false;
    if (data.length < 20) hasMore = false;
  });
}  

void generateReportText() {
  if (visits.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No data available")),
    );
    return;
  }

  // 📅 Get date from first record (since single date filter)
  String reportDate = visits.first.date;

  String message = "📊 Site Visit Report\n";
  message += "📅 $reportDate\n\n";

  for (var v in visits) {
    message +=
        "👤 ${v.name}\n"
        "📞 ${v.mobile}\n"
        "🏠 ${v.project}\n"
        "👨‍💼 BDM: ${v.bdm.isNotEmpty ? v.bdm : "-"}\n"
        "🔥 Status: ${v.status}\n"
        "${v.remarks.isNotEmpty ? "📝 Remarks: ${v.remarks}\n" : ""}"
        "\n";
  }

  message += "Total Visits: ${visits.length}";

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text("Report"),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: SelectableText(message),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            copyToClipboard(message);
          },
          child: const Text("Copy"),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    ),
  );
}


void copyToClipboard(String text) {
  Clipboard.setData(ClipboardData(text: text));

  Navigator.pop(context);

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text("Copied to clipboard")),
  );
}

void generateWhatsAppMessage() async {
  if (visits.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("No data to share")),
    );
    return;
  }

  String message = "";

  for (var v in visits) {
    message +=
        "Name: ${v.name}\n"
        "Mobile: ${v.mobile}\n"
        "Project: ${v.project}\n"
        "Status: ${v.status}\n"
        "Visit Date: ${v.date}\n"
        "${v.remarks.isNotEmpty ? "Remarks: ${v.remarks}\n" : ""}"
        "--------------------------\n";
  }

  shareToWhatsApp(message);
}

void shareToWhatsApp(String message) async {
  final url = Uri.parse("https://wa.me/?text=${Uri.encodeComponent(message)}");

  if (await canLaunchUrl(url)) {
    await launchUrl(url, mode: LaunchMode.externalApplication);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Could not open WhatsApp")),
    );
  }
}


Future<void> deleteVisit(int id) async {

  print("📥 DELETE CLICK");

  final request = http.Request(
    "POST",
    Uri.parse("${baseUrl}delete_site_visit.php"),
  );

  request.headers["Content-Type"] = "application/json";
  request.body = json.encode({"id": id});

  final streamedResponse = await request.send();
  final res = await http.Response.fromStream(streamedResponse);

  print("📥 DELETE RESPONSE: ${res.body}");

  final data = json.decode(res.body);

  if (data['success'] == true) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Deleted successfully")),
    );

    refresh();
  } else {
    throw Exception("Delete failed");
  }
}



  Future<void> refresh() async {
    page = 1;
    hasMore = true;
    await fetchData();
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hot':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'cold':
        return Colors.blue;
      case 'hot closing':
        return Colors.purple;
      case 'not interested':
        return Colors.grey;
      default:
        return Colors.green;
    }
  }

  /// ✏️ EDIT
  void onEdit(SiteVisitModel v) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SiteVisitScreen(visit: v),
      ),
    );
    refresh();
  }

  /// 🗑 DELETE
  void onDelete(SiteVisitModel v) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete"),
        content: const Text("Are you sure you want to delete this record?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await SiteVisitService.deleteVisit(v.id);
              refresh();

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Deleted successfully")),
              );
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(

appBar: AppBar(
  title: const Text('Site Visit Records'),
  actions: [

    /// 📊 SUMMARY BUTTON (NEW)
    IconButton(
      icon: const Icon(Icons.bar_chart), // or Icons.analytics
      tooltip: "Summary",
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SummaryScreen(
              userId: (UserSession.bdmId ?? 0).toString(),
            ),
          ),
        );
      },
    ),

    /// ➕ ADD BUTTON (EXISTING)
    IconButton(
      icon: const Icon(Icons.add),
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const SiteVisitScreen(),
          ),
        );
        refresh();
      },
    ),
    IconButton(
      icon: const Icon(Icons.copy, color: Colors.blue),
      tooltip: "Generate Report",
      onPressed: generateReportText,
    ),       
  ],
),


      body: RefreshIndicator(
        onRefresh: refresh,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: visits.length + 1,
                itemBuilder: (context, index) {
                  if (index < visits.length) {
                    return visitCard(visits[index]);
                  } else {
                    if (hasMore) {
                      fetchData(loadMore: true);
                      return const Padding(
                        padding: EdgeInsets.all(10),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    } else {
                      return const SizedBox();
                    }
                  }
                },
              ),
      ),
    );
  }

  Widget visitCard(SiteVisitModel v) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// NAME + STATUS + MENU
            Row(
              children: [
                Expanded(
                  child: Text(
                    v.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                /// STATUS
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: getStatusColor(v.status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    v.status,
                    style: TextStyle(
                      color: getStatusColor(v.status),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

                /// MENU
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      onEdit(v);
                    } else if (value == 'delete') {
                      onDelete(v);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// MOBILE
            Text(
              v.mobile,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 6),

            /// PRODUCT
            Text(
              v.project,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),

            /// BDM
            if ((v.bdm).isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "BDM: ${v.bdm}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.blueGrey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),


            if (v.remarks.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  "Remarks: ${v.remarks}",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),         
              
              const SizedBox(height: 6),
   

            /// DATE
            Text(
              "Visit Date: ${v.date}",
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}