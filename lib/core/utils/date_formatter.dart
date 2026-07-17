import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static final DateFormat _dueDateFormat = DateFormat('MMM d, yyyy');

  static String dueDate(DateTime date) => _dueDateFormat.format(date);
}
