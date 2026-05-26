import 'package:flutter/material.dart';
import '../models/site_visit_summary_model.dart';
import '../services/site_visit_summary_service.dart';
import 'site_visit_list_screen.dart';


class SummaryScreen extends StatefulWidget {
  final String userId;

  const SummaryScreen({super.key, required this.userId});

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late Future<List<SummaryModel>> futureData;

  DateTime? fromDate;
  DateTime? toDate;  

  @override
  void initState() {
    super.initState();
    loadData();
  }

void loadData() {
  futureData = SummaryService.fetchSummary(
    userId: widget.userId,
    fromDate: formatDate(fromDate),
    toDate: formatDate(toDate),
  );
}



  Future<void> _refresh() async {
    setState(() {
      loadData();
    });
  }

  int getTotal(List<SummaryModel> list) {
    return list.fold(0, (sum, item) => sum + item.count);
  }

Future<void> pickDate({required bool isFrom}) async {
  final picked = await showDatePicker(
    context: context,
    initialDate: DateTime.now(),
    firstDate: DateTime(2020),
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    setState(() {
      if (isFrom) {
        fromDate = picked;
      } else {
        toDate = picked;
      }
    });
  }
}

String formatDate(DateTime? date) {
  if (date == null) return "";
  return "${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";
}



  String formatToApiDate(String input) {
    final parts = input.split("-");
    final day = parts[0];
    final monthStr = parts[1];
    final year = parts[2];

    final monthMap = {
      "Jan": "01","Feb": "02","Mar": "03","Apr": "04",
      "May": "05","Jun": "06","Jul": "07","Aug": "08",
      "Sep": "09","Oct": "10","Nov": "11","Dec": "12"
    };

    return "$year-${monthMap[monthStr]}-$day";
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Date-wise Summary"),
      ),
      body: FutureBuilder<List<SummaryModel>>(
        future: futureData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text("Error: ${snapshot.error}"),
              );
          }

          final data = snapshot.data ?? [];

          if (data.isEmpty) {
            return const Center(child: Text("No data found"));
          }

          final total = getTotal(data);

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [

Card(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
  ),
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(10),
    child: Row(
      children: [

        /// FROM DATE
        Expanded(
          child: InkWell(
            onTap: () => pickDate(isFrom: true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  fromDate == null
                      ? "From Date"
                      : "${fromDate!.day}-${fromDate!.month}-${fromDate!.year}",
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        /// TO DATE
        Expanded(
          child: InkWell(
            onTap: () => pickDate(isFrom: false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  toDate == null
                      ? "To Date"
                      : "${toDate!.day}-${toDate!.month}-${toDate!.year}",
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        /// FILTER BUTTON
        ElevatedButton(
          onPressed: () {
            setState(() {
              loadData();
            });
          },
          child: const Text("Go"),
        ),
      ],
    ),
  ),
),


                // 🔹 TOTAL CARD
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 3,
                  child: ListTile(
                    title: const Text(
                      "Total Visits",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      total.toString(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 🔹 LIST
                ...data.map((item) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(
                        item.date,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      trailing: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SiteVisitListScreen(
                                selectedDate: formatToApiDate(item.date),
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item.count.toString(),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                      ),
                      
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }
}