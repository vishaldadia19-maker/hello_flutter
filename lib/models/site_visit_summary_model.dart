class SummaryModel {
  final String date;
  final int count;

  SummaryModel({required this.date, required this.count});

  factory SummaryModel.fromJson(Map<String, dynamic> json) {
    return SummaryModel(
      date: json['date'],
      count: int.parse(json['count'].toString()),
    );
  }
}