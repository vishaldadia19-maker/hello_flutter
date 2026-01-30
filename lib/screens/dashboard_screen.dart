import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:hello_flutter/models/dashboard_model.dart';
import 'package:hello_flutter/services/dashboard_api.dart';

import 'package:hello_flutter/models/lead_model.dart';
import 'package:hello_flutter/services/lead_service.dart';
import 'package:hello_flutter/leads_page.dart';

import 'package:hello_flutter/new_lead_entry_page.dart';

import 'package:hello_flutter/utils/user_session.dart';
import 'package:hello_flutter/login_screen.dart';

import 'package:hello_flutter/models/status_breakdown_model.dart';
import 'package:hello_flutter/services/status_breakdown_api.dart';










class DashboardScreen extends StatefulWidget {
  final int bdmId;
  
  const DashboardScreen({
      super.key,
      required this.bdmId,
    });  


  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  
  late Future<DashboardModel> dashboardFuture;
  late Future<List<StatusBreakdownModel>> statusFuture;

  bool isSearchMode = false;
  final TextEditingController searchController = TextEditingController();

  // ================= FCM SETUP =================

  Future<void> _initNotifications() async {
    // 1️⃣ Request permission (safe even if already granted)
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2️⃣ Listen for foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📩 Foreground notification received');
      debugPrint('Title: ${message.notification?.title}');
      debugPrint('Body: ${message.notification?.body}');

      // Later: show local notification here
    });

    // 3️⃣ App opened from background via notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('📲 Notification clicked (background)');
      _handleNotificationClick(message);
    });

    // 4️⃣ App opened from terminated state
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null) {
      debugPrint('📲 App opened from terminated state');
      _handleNotificationClick(initialMessage);
    }
  }

  // ================= TOKEN REFRESH =================

  void _listenTokenRefresh() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
      debugPrint('🔁 FCM token refreshed');

      if (UserSession.bdmId != null) {
        _sendTokenToBackend(
          bdmId: UserSession.bdmId!,
          token: newToken,
        );
      }
    });
  }

  // ================= SEND TOKEN TO BACKEND =================

  Future<void> _sendTokenToBackend({
    required int bdmId,
    required String token,
  }) async {
    try {
      await http.post(
        Uri.parse(
            'https://backoffice.thecubeclub.co/apis/save_fcm_token.php'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'bdm_id': bdmId,
          'fcm_token': token,
          'platform': 'android',
        }),
      );
    } catch (e) {
      debugPrint('❌ Failed to update FCM token: $e');
    }
  }

  // ================= NOTIFICATION CLICK HANDLER =================

  void _handleNotificationClick(RemoteMessage message) {
    final data = message.data;

    // Example: open lead / screen later
    // final leadId = data['lead_id'];

    debugPrint('Notification data: $data');

    // TODO: navigate based on data
  }




  @override
  void initState() {
    super.initState();    

    dashboardFuture = DashboardApi.fetchDashboard(widget.bdmId);
    statusFuture = StatusBreakdownApi.fetchStatusBreakdown(widget.bdmId);

    // 🔔 FCM setup
    _initNotifications();
    _listenTokenRefresh();    

  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

Future<void> _refreshDashboard() async {
  setState(() {
    dashboardFuture = DashboardApi.fetchDashboard(widget.bdmId);
    statusFuture = StatusBreakdownApi.fetchStatusBreakdown(widget.bdmId);
  });

  // small delay so refresh indicator is visible
  await Future.delayed(const Duration(milliseconds: 800));
}


  void openLeadsFromStatus({
    required BuildContext context,
    required String status,
    required String reportType,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LeadsPage(
          bdmId: UserSession.bdmId!,
          reportType: reportType,
          reportStatus: status,
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(


        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,

          leading: isSearchMode
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    setState(() {
                      isSearchMode = false;
                      searchController.clear();
                    });
                  },
                )
              : Builder(
                  builder: (context) => IconButton(
                    icon: const Icon(Icons.menu, color: Colors.black),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),

          title: isSearchMode
              ? TextField(
                    controller: searchController,
                    autofocus: true,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    decoration: const InputDecoration(
                      hintText: 'Search by mobile number',
                      border: InputBorder.none,
                      counterText: '',
                    ),

                    onChanged: (mobile) {
                      if (mobile.length == 10) {
                        FocusScope.of(context).unfocus(); // close keyboard

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LeadsPage(
                              bdmId: widget.bdmId,
                              reportType: "search mobile",
                              reportStatus: mobile,
                            ),
                          ),
                        );
                      }
                    },
                  )
              : Row(
                  children: [
                    Image.asset('assets/logo.png', height: 30),
                    const SizedBox(width: 10),
                    const Text(
                      'Dashboard',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

          actions: [
            if (!isSearchMode)
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {
                  setState(() {
                    isSearchMode = true;
                  });
                },
              ),
          ],
        ),

          

drawer: Drawer(
  child: Column(
    children: [
      DrawerHeader(
        decoration: BoxDecoration(
            color: Colors.grey.shade100, // light background
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 80, // 🔼 increased logo size

            ),
            const SizedBox(height: 10),
            const Text(
              'Welcome',
              style: TextStyle(
                color: Colors.black, // 🔲 black text
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),

      ListTile(
        leading: const Icon(Icons.dashboard),
        title: const Text('Dashboard'),
        onTap: () {
          Navigator.pop(context);
        },
      ),

      ListTile(
        leading: Icon(Icons.people),
        title: Text("Leads"),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LeadsPage(bdmId: UserSession.bdmId!)),
          );
        },
      ),

      ListTile(
        leading: const Icon(Icons.add_box_outlined),
        title: const Text('New Lead Entry'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NewLeadEntryPage(),
            ),
          );
        },
      ),


      const Spacer(),

      const Divider(),

      ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () {
          // 1️⃣ Clear session
          UserSession.clear();

          // 2️⃣ Navigate to Login & clear back stack
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        },        
      ),
    ],
  ),
),



      body: RefreshIndicator(
        onRefresh: _refreshDashboard,
        color: Colors.blue,
        child: FutureBuilder<DashboardModel>(
          future: dashboardFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Error loading dashboard',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            final data = snapshot.data!;
            return buildDashboardUI(data);
          },
        ),
      ),
        
    );
  }

  Widget buildDashboardUI(DashboardModel data) {
  return SingleChildScrollView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.all(14),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        /// =============================
        /// SECTION 1 — NEW LEADS (2 CARDS)
        /// =============================

        const Text(
          'New Leads',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Row(
          children: [

            /// TODAY NEW LEADS
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadsPage(
                        bdmId: widget.bdmId,
                        reportType: 'today new leads',
                      ),
                    ),
                  );
                },
                child: summaryCard(
                  "Today's New Leads",
                  data.todayNewLeads.toString(),
                  "Pending Fresh + Proposal: ${data.todayPendingFP}",
                  Colors.blue,
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// YESTERDAY NEW LEADS
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadsPage(
                        bdmId: widget.bdmId,
                        reportType: 'yesterday new leads',
                      ),
                    ),
                  );
                },
                child: summaryCard(
                  "Yesterday's New Leads",
                  data.yesterdayNewLeads.toString(),
                  "Pending Fresh + Proposal: ${data.yesterdayPendingFP}",
                  Colors.deepPurple,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 22),

        /// =============================
        /// SECTION 2 — OPERATIONS (NO LIVE LEADS)
        /// =============================

        const Text(
          'Operations',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        Row(
          children: [

            /// TODAY DUE
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadsPage(
                        bdmId: widget.bdmId,
                        reportType: 'today due', // ✅ hyperlink param
                      ),
                    ),
                  );
                },
                child: kpiCard(
                  "Today Due",
                  data.todayDue,
                  Colors.orange,
                ),
              ),
            ),
          
            const SizedBox(width: 12),

            /// OVERDUE
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadsPage(
                        bdmId: widget.bdmId,
                        reportType: 'overdue',
                      ),
                    ),
                  );
                },
                child: kpiCard(
                  "Overdue",
                  data.overdue,
                  Colors.red,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [

            /// UPCOMING
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadsPage(
                        bdmId: widget.bdmId,
                        reportType: 'upcoming',
                      ),
                    ),
                  );
                },
                child: kpiCard(
                  "Upcoming",
                  data.upcoming,
                  Colors.amber,
                ),
              ),
            ),

            const SizedBox(width: 12),

            /// LOST
            Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LeadsPage(
                        bdmId: widget.bdmId,
                        reportType: 'lost',
                      ),
                    ),
                  );
                },
                child: kpiCard(
                  "Lost",
                  data.lost,
                  Colors.grey,
                ),
              ),
            ),
          ],
        ),

const SizedBox(height: 24),

const Text(
  'Status Breakdown',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),

const SizedBox(height: 10),

FutureBuilder<List<StatusBreakdownModel>>(
  future: statusFuture,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: CircularProgressIndicator(),
      );
    }

    if (snapshot.hasError || !snapshot.hasData) {
      return const Text(
        'Unable to load status breakdown',
        style: TextStyle(color: Colors.red),
      );
    }

    final list = snapshot.data!;

    return Column(
      children: list.map((item) {
        return _statusCard(
          context: context, // ✅ PASS CONTEXT
          status: item.status,
          today: item.today,
          late: item.lateCount,
          upcoming: item.upcoming,
          total: item.total,
        );
      }).toList(),
    );
  },
),



      ],
    ),
  );
}

Widget _statusCard({
  required BuildContext context, // ✅ ADD
  required String status,
  required int today,
  required int late,
  required int upcoming,
  required int total,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 10),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric(context, status, 'Today', today, 'today due'),
              _metric(context, status, 'Late', late, 'overdue'),
              _metric(context, status, 'Upcoming', upcoming, 'upcoming'),
              _metric(context, status, 'Total', total, null),              
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _metric(
  BuildContext context,
  String status,
  String label,
  int value,
  String? reportType,
) {
  final bool isClickable = reportType != null && value > 0;

  return InkWell(
    onTap: isClickable
        ? () => openLeadsFromStatus(
              context: context,
              status: status,
              reportType: reportType,
            )
        : null,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value.toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isClickable ? Colors.blue : Colors.black,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    ),
  );
}



}


Widget summaryCard(
  String title,
  String value,
  String subtitle,
  Color color,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color.withOpacity(0.12),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Text(title),
        const SizedBox(height: 4),
        Text(subtitle,
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    ),
  );
}



Widget kpiCard(String title, int value, Color color) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 6,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value.toString(),
          style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold, color: color),
        ),
        const SizedBox(height: 6),
        Text(title, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

Widget sizedKpiCard(
  String title,
  int value,
  Color color,
  double width,
) {
  return SizedBox(
    width: width,
    child: kpiCard(title, value, color),
  );
}

