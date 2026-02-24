import 'package:intl/intl.dart';

class DateUtilsCustom {
  static String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static String formatDisplay(String date) {
    final parsed = DateTime.parse(date);
    return DateFormat('dd-MMM-yyyy hh:mm a').format(parsed);
  }
}