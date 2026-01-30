import 'package:flutter/material.dart';

class MobileDashboardSample extends StatelessWidget {
  const MobileDashboardSample({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ======================
            // SECTION 1 – NEW LEADS (SINGLE ROW)
            // ======================
            _sectionTitle('New Leads'),

            Row(
              children: [
                Expanded(
                  child: _bigCard(
                    title: "Today's New Leads",
                    value: '25',
                    subtitle: 'Pending Fresh + Proposal: 10',
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _bigCard(
                    title: "Yesterday's New Leads",
                    value: '31',
                    subtitle: 'Pending Fresh + Proposal: 11',
                    color: Colors.deepPurple,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ======================
            // SECTION 2 – OPERATIONS (NO LIVE LEADS)
            // ======================
            _sectionTitle('Operations'),

            Row(
              children: [
                Expanded(
                  child: _smallCard(
                    title: 'Today Due',
                    value: '279',
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallCard(
                    title: 'Overdue',
                    value: '6916',
                    color: Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _smallCard(
                    title: 'Upcoming',
                    value: '2344',
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _smallCard(
                    title: 'Lost',
                    value: '20492',
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ======================
            // SECTION 3 – STATUS
            // ======================
            _sectionTitle('Status Breakdown'),

            _statusCard(
              status: 'Call Not Received',
              today: 40,
              late: 1568,
              upcoming: 447,
              total: 2055,
            ),

            _statusCard(
              status: 'Fresh',
              today: 17,
              late: 897,
              upcoming: 23,
              total: 937,
            ),

            _statusCard(
              status: 'Cold',
              today: 72,
              late: 436,
              upcoming: 382,
              total: 890,
            ),
          ],
        ),
      ),
    );
  }

  // ======================
  // HELPERS
  // ======================

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _bigCard({
    required String title,
    required String value,
    String? subtitle,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(fontSize: 11, color: Colors.red),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _smallCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusCard({
    required String status,
    required int today,
    required int late,
    required int upcoming,
    required int total,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _metric('Today', today),
                _metric('Late', late),
                _metric('Upcoming', upcoming),
                _metric('Total', total),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label,
            style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
