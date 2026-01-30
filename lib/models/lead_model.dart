class LeadModel {
  final int leadId; // ✅ NEW
  final String clientName;
  final String contactNo;
  final String contactNo2;
  final String status;
  final String nextFollowUp;
  final String lastRemarks;
  final String source;
  final String city; 

  LeadModel({
    required this.leadId, // ✅ NEW
    required this.clientName,
    required this.contactNo,
    required this.contactNo2,
    required this.status,
    required this.nextFollowUp,
    required this.lastRemarks,
    required this.source,
    required this.city,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      leadId: int.tryParse(json['lead_id'].toString()) ?? 0, // ✅ NEW
      clientName: json['client_name'] ?? '',
      contactNo: json['contact_no'] ?? '',
      contactNo2: json['contact_no2'],
      status: json['status'] ?? '',
      nextFollowUp: json['next_fup_date'] ?? '',
      lastRemarks: json['last_remarks'] ?? '',
      source: json['source'] ?? '',
      city: json['city'] ?? '',
    );
  }
}
