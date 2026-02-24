class FollowupReportModel {
  final bool status;
  final Summary summary;
  final List<FollowupData> data;

  FollowupReportModel({
    required this.status,
    required this.summary,
    required this.data,
  });

  factory FollowupReportModel.fromJson(Map<String, dynamic> json) {
    return FollowupReportModel(
      status: json['status'] ?? false,
      summary: Summary.fromJson(json['summary'] ?? {}),
      data: (json['data'] as List?)
              ?.map((e) => FollowupData.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class Summary {
  final int totalCalls;
  final String totalDuration;
  final int freshCalls;
  final int followupCalls;

  Summary({
    required this.totalCalls,
    required this.totalDuration,
    required this.freshCalls,
    required this.followupCalls,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      totalCalls: json['total_calls'] ?? 0,
      totalDuration: json['total_duration'] ?? "0:00",
      freshCalls: json['fresh_calls'] ?? 0,
      followupCalls: json['followup_calls'] ?? 0,
    );
  }
}

class FollowupData {
  final int leadId;
  final String clientName;
  final String contactNo;
  final String followupDate;
  final String status;
  final String duration;
  final String type;
  final String nextFollowup;

  FollowupData({
    required this.leadId,
    required this.clientName,
    required this.contactNo,
    required this.followupDate,
    required this.status,
    required this.duration,
    required this.type,
    required this.nextFollowup,
  });

  factory FollowupData.fromJson(Map<String, dynamic> json) {
    return FollowupData(
      leadId: json['lead_id'] ?? 0,
      clientName: json['client_name'] ?? "",
      contactNo: json['contact_no'] ?? "",
      followupDate: json['followup_date'] ?? "",
      status: json['status'] ?? "",
      duration: json['duration'] ?? "",
      type: json['type'] ?? "",
      nextFollowup: json['next_followup'] ?? "",
    );
  }
}

