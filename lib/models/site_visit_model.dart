class SiteVisitModel {
  final int id;
  final String name;
  final String mobile;
  final String project;
  final String status;
  final String remarks;
  final String date;
  final String ? visitDoneBy;
  final String bdm;
  final String division;

  SiteVisitModel({
    required this.id,
    required this.name,
    required this.mobile,
    required this.project,
    required this.status,
    required this.remarks,
    required this.date,
    this.visitDoneBy,
    required this.bdm,
    required this.division,
  });

factory SiteVisitModel.fromJson(Map<String, dynamic> json) {
  return SiteVisitModel(
    id: int.tryParse(json['id'].toString()) ?? 0,
    name: json['name']?.toString() ?? '',
    mobile: json['mobile']?.toString() ?? '',
    division: json['division']?.toString() ?? '',
    project: json['project']?.toString() ?? '',
    status: json['status']?.toString() ?? '',
    remarks: json['remarks']?.toString() ?? '',
    date: json['date']?.toString() ?? '',
    visitDoneBy: json['visit_done_by']?.toString() ?? '',
    bdm: json['bdm']?.toString() ?? '',
  );
}



}