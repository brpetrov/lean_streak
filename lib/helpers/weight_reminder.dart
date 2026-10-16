/// When the next "time to weigh in" reminder should fire: seven days after
/// [lastWeighIn] at 09:00 local, pushed forward in whole weeks until it is
/// after [now]. Built with the DateTime constructor rather than Duration
/// arithmetic so 09:00 stays 09:00 across DST changes and month ends.
DateTime nextWeightReminder({
  required DateTime lastWeighIn,
  required DateTime now,
}) {
  var due = DateTime(
    lastWeighIn.year,
    lastWeighIn.month,
    lastWeighIn.day + 7,
    9,
  );
  while (!due.isAfter(now)) {
    due = DateTime(due.year, due.month, due.day + 7, 9);
  }
  return due;
}
