import 'package:flutter/material.dart';
import '../models/site_visit_model.dart';
import '../services/site_visit_service.dart';
import 'site_visit_screen.dart';

class SiteVisitListScreen extends StatefulWidget {
  const SiteVisitListScreen({super.key});

  @override
  State<SiteVisitListScreen> createState() => _SiteVisitListScreenState();
}

class _SiteVisitListScreenState extends State<SiteVisitListScreen> {
  List<SiteVisitModel> visits = [];
  bool isLoading = true;
  int page = 1;
  bool hasMore = true;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData({bool loadMore = false}) async {
    if (loadMore) page++;

    final data = await SiteVisitService.fetchVisits(page: page);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        title: const Text('Site Visit Records'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SiteVisitScreen(),
                ),
              );

              // Refresh after coming back
              refresh();
            },
          )
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

            /// CLIENT NAME + STATUS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
              ],
            ),

            const SizedBox(height: 6),

            /// MOBILE
            Text(
              v.mobile,
              style: const TextStyle(fontSize: 14),
            ),

            const SizedBox(height: 6),


/// BDM NAME
if (v.bdm.isNotEmpty)
  Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      "BDM: ${v.bdm}",
      style: const TextStyle(
        fontSize: 12,
        color: Colors.grey,
        fontStyle: FontStyle.italic,
      ),
    ),
  ),


            /// PRODUCT (NOT HIGHLIGHTED)
            Text(
              v.project,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            /// VISIT DATE
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