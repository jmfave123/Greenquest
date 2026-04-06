/// Get day abbreviation
String getDayAbbreviation(String day) {
  switch (day.toLowerCase()) {
    case 'monday':
      return 'Mon';
    case 'tuesday':
      return 'Tue';
    case 'wednesday':
      return 'Wed';
    case 'thursday':
      return 'Thu';
    case 'friday':
      return 'Fri';
    case 'saturday':
      return 'Sat';
    case 'sunday':
      return 'Sun';
    default:
      return day;
  }
}
