const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

/// Formats an ISO date string to "DD MMM YYYY, HH:MM AM/PM"
/// Returns the original string if it's already formatted or can't be parsed.
String formatDate(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr).toLocal();
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final amPm = date.hour >= 12 ? 'PM' : 'AM';
    return '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}, '
        '${hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')} $amPm';
  } catch (_) {
    return dateStr;
  }
}

/// Formats an ISO date string to "DD MMM YYYY" only (no time)
String formatDateShort(String? dateStr) {
  if (dateStr == null || dateStr.isEmpty) return 'N/A';
  try {
    final date = DateTime.parse(dateStr).toLocal();
    return '${date.day.toString().padLeft(2, '0')} ${_months[date.month - 1]} ${date.year}';
  } catch (_) {
    return dateStr;
  }
}
