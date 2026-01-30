class DashboardModel {
  final int todayNewLeads;
  final int todayPendingFP;
  final int yesterdayNewLeads;
  final int yesterdayPendingFP;
  final int liveLeads;
  final int todayDue;
  final int overdue;
  final int upcoming;
  final int lost;

  DashboardModel({
    required this.todayNewLeads,
    required this.todayPendingFP,
    required this.yesterdayNewLeads,
    required this.yesterdayPendingFP,
    required this.liveLeads,
    required this.todayDue,
    required this.overdue,
    required this.upcoming,
    required this.lost,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    return DashboardModel(
      todayNewLeads: json['today_new_leads'],
      todayPendingFP: json['today_pending_fresh_proposal'],
      yesterdayNewLeads: json['yesterday_new_leads'],
      yesterdayPendingFP: json['yesterday_pending_fresh_proposal'],
      liveLeads: json['live_leads'],
      todayDue: json['today_due'],
      overdue: json['overdue'],
      upcoming: json['upcoming'],
      lost: json['lost'],
    );
  }
}
