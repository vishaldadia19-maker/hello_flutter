import 'package:flutter/material.dart';
import 'package:hello_flutter/models/followup_history_model.dart';
import 'package:hello_flutter/services/followup_history_api.dart';
import 'package:intl/intl.dart';


class FollowupHistoryPage extends StatefulWidget {
  final int leadId;
  final String clientName;

  const FollowupHistoryPage({
    Key? key,
    required this.leadId,
    required this.clientName,
  }) : super(key: key);

  @override
  State<FollowupHistoryPage> createState() => _FollowupHistoryPageState();
}

class _FollowupHistoryPageState extends State<FollowupHistoryPage> {
  late Future<List<FollowupHistoryModel>> historyFuture;

  @override
  void initState() {
    super.initState();
    historyFuture = FollowupHistoryApi.fetchHistory(widget.leadId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Follow-up History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              widget.clientName,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              
            ),
          ),
        ),
      ),

      body: FutureBuilder<List<FollowupHistoryModel>>(
        future: historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading follow-up history',
                style: TextStyle(color: Colors.red),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('No follow-ups found'),
            );
          }

          final list = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];

              return _HistoryCard(
                dateTime: item.fupDate,
                activity: item.activity,
                status: item.status,
                bdm: item.bdmName,
                remarks: item.remarks,
                duration: item.callTiming,
                nextFollowup: item.nextFupDate,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String dateTime;
  final String activity;
  final String status;
  final String bdm;
  final String remarks;
  final String duration;
  final String nextFollowup;

  const _HistoryCard({
    required this.dateTime,
    required this.activity,
    required this.status,
    required this.bdm,
    required this.remarks,
    required this.duration,
    required this.nextFollowup,
  });

  Color _statusColor() {
    switch (status.toLowerCase()) {
      case 'hot':
        return Colors.orange;
      case 'warm':
        return Colors.amber;
      case 'cold':
        return Colors.blueGrey;
      default:
        return Colors.grey;
    }
  }

  String formatIndianDateTime(String rawDate) {
    final dt = DateTime.parse(rawDate);
    return DateFormat('dd MMM yyyy, hh:mm a').format(dt);
  }


  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// DATE + TIME
            Text(
              '🕒 ${formatIndianDateTime(dateTime)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            /// ACTIVITY + STATUS
            Row(
              children: [
                Expanded(
                  child: Text(
                    activity,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor().withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _statusColor(),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 6),

            /// BDM
            Text(
              '👤 $bdm',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),

            const SizedBox(height: 8),

            /// REMARKS
            if (remarks.isNotEmpty)
              Text(
                '📝 $remarks',
                style: const TextStyle(fontSize: 14),
              ),

            const SizedBox(height: 10),

            /// CALL DURATION + NEXT FOLLOW-UP
            Row(
              children: [
                Text(
                  '⏱ $duration',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                if (nextFollowup.isNotEmpty)
                  Text(
                    '📅 Next: $nextFollowup',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
