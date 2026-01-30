class FollowupHistoryModel {
  final String fupDate;
  final String activity;
  final String status;
  final String nextFupDate;
  final String remarks;
  final String callTiming;
  final String bdmName;

  FollowupHistoryModel({
    required this.fupDate,
    required this.activity,
    required this.status,
    required this.nextFupDate,
    required this.remarks,
    required this.callTiming,
    required this.bdmName,
  });

  factory FollowupHistoryModel.fromJson(Map<String, dynamic> json) {
    return FollowupHistoryModel(
      fupDate: json['fup_date'] ?? '',
      activity: json['call_activity'] ?? '',
      status: json['status'] ?? '',
      nextFupDate: json['next_fup_date'] ?? '',
      remarks: json['remarks'] ?? '',
      callTiming: json['call_timing'] ?? '',
      bdmName: json['bdm_name'] ?? '',
    );
  }
}
