String dateToHumanReadable(DateTime date) {
  const List weekday = [null, 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const List months = [
    null,
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December'
  ];
  String toBeDisplayed = weekday[date.weekday] +
      ', ' +
      date.day.toString() +
      ' ' +
      months[date.month] +
      ' ' +
      date.year.toString() +
      ' at ' +
      (date.hour.toString() == '0' ? '00' : date.hour.toString()) +
      ':' +
      (date.minute.toString().length == 1
          ? '0' + date.minute.toString()
          : date.minute.toString());
  return toBeDisplayed;
}
