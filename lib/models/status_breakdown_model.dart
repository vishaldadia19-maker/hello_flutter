class StatusBreakdownModel {
  final String status;
  final int today;
  final int yesterday;
  final int lateCount; // ✅ FIXED
  final int upcoming;
  final int total;

  StatusBreakdownModel({
    required this.status,
    required this.today,
    required this.yesterday,
    required this.lateCount,
    required this.upcoming,
    required this.total,
  });

  factory StatusBreakdownModel.fromJson(Map<String, dynamic> json) {
    return StatusBreakdownModel(
      status: json['status'] ?? '',
      today: int.tryParse(json['today'].toString()) ?? 0,
      yesterday: int.tryParse(json['yesterday'].toString()) ?? 0,
      lateCount: int.tryParse(json['late'].toString()) ?? 0, // 👈 map stays same
      upcoming: int.tryParse(json['upcoming'].toString()) ?? 0,
      total: int.tryParse(json['total'].toString()) ?? 0,
    );
  }
}
