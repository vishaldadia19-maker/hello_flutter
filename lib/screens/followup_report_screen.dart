import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/followup_report_model.dart';
import '../services/followup_report_service.dart';
import '../utils/date_utils.dart';

class FollowupReportScreen extends StatefulWidget {
  final int bdmId;

  const FollowupReportScreen({Key? key, required this.bdmId})
      : super(key: key);

  @override
  State<FollowupReportScreen> createState() =>
      _FollowupReportScreenState();
}

class _FollowupReportScreenState extends State<FollowupReportScreen> {
  DateTime startDate = DateTime.now();
  DateTime endDate = DateTime.now();

  FollowupReportModel? report;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    loadReport();
  }

  Future<void> loadReport() async {
    setState(() => isLoading = true);

    final result = await FollowupReportService.fetchReport(
      bdmId: widget.bdmId,
      startDate: DateUtilsCustom.formatDate(startDate),
      endDate: DateUtilsCustom.formatDate(endDate),
    );

    setState(() {
      report = result;
      isLoading = false;
    });
  }

  Future<void> _callNumber(String number) async {
    final Uri callUri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(callUri)) {
      await launchUrl(callUri);
    }
  }

  Future<void> pickDate(bool isStart) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? startDate : endDate,
      firstDate: DateTime(2023),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case "hot":
        return Colors.red;
      case "medium":
        return Colors.orange;
      case "new":
        return Colors.blue;
      case "interested":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Followup Report"),
      ),
      body: Column(
        children: [

          /// DATE FILTER
          Container(
            padding: const EdgeInsets.all(10),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => pickDate(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateUtilsCustom.formatDate(startDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () => pickDate(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateUtilsCustom.formatDate(endDate),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: loadReport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text("Filter"),
                ),
              ],
            ),
          ),

          /// SUMMARY CARD
          if (!isLoading && report != null)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff4facfe), Color(0xff00f2fe)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceAround,
                children: [
                  _summary("Calls",
                      report!.summary.totalCalls.toString()),
                  _summary("Duration",
                      report!.summary.totalDuration),
                  _summary("Fresh",
                      report!.summary.freshCalls.toString()),
                  _summary("Follow-up",
                      report!.summary.followupCalls.toString()),
                ],
              ),
            ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator())
                : report == null
                    ? const Center(child: Text("No Data"))
                    : ListView.builder(
                        itemCount: report!.data.length,
                        padding:
                            const EdgeInsets.symmetric(horizontal: 12),
                        itemBuilder: (context, index) {
                          final item = report!.data[index];

                          return Container(
                            margin:
                                const EdgeInsets.only(bottom: 12),
                            padding:
                                const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black
                                      .withOpacity(0.05),
                                  blurRadius: 6,
                                  offset:
                                      const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [

                                /// Name + Followup Date + Duration
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.clientName,
                                        style:
                                            const TextStyle(
                                          fontSize: 15,
                                          fontWeight:
                                              FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          DateUtilsCustom
                                              .formatDisplay(
                                                  item
                                                      .followupDate),
                                          style:
                                              const TextStyle(
                                            fontSize: 11,
                                            color:
                                                Colors.grey,
                                          ),
                                        ),
                                        const SizedBox(
                                            height: 4),
                                        Text(
                                          "Duration: ${item.duration}",
                                          style:
                                              const TextStyle(
                                            fontSize: 11,
                                            color: Colors
                                                .black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 6),

                                /// Contact
                                InkWell(
                                  onTap: () =>
                                      _callNumber(
                                          item.contactNo),
                                  child: Row(
                                    children: [
                                      const Icon(
                                          Icons.call,
                                          size: 16,
                                          color:
                                              Colors.green),
                                      const SizedBox(width: 5),
                                      Text(
                                        item.contactNo,
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.green,
                                          fontWeight:
                                              FontWeight
                                                  .w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                /// Status
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                              horizontal:
                                                  10,
                                              vertical: 4),
                                  decoration:
                                      BoxDecoration(
                                    color: _statusColor(
                                            item.status)
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius
                                            .circular(20),
                                  ),
                                  child: Text(
                                    item.status,
                                    style: TextStyle(
                                      color:
                                          _statusColor(
                                              item
                                                  .status),
                                      fontWeight:
                                          FontWeight
                                              .w600,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 6),

                                /// Next Follow-up
                                if (item.nextFollowup !=
                                        null &&
                                    item.nextFollowup!
                                        .isNotEmpty)
                                  Text(
                                    "Next Follow-up: ${DateUtilsCustom.formatDisplay(item.nextFollowup!)}",
                                    style:
                                        const TextStyle(
                                      fontSize: 12,
                                      color: Colors
                                          .deepPurple,
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _summary(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
              fontSize: 12,
              color: Colors.white70),
        ),
      ],
    );
  }
}