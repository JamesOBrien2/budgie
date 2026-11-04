// Plain Dart (no Flutter import) so test/spending_pace_check.dart runs with
// `dart run --enable-asserts`.
import 'dart:math';

// Calendar days from [from] to [to], both counted (Nov 1 -> Nov 10 is 10).
int inclusiveDays(DateTime from, DateTime to) =>
    (DateTime(to.year, to.month, to.day + 1)
                .difference(DateTime(from.year, from.month, from.day))
                .inHours /
            24)
        .round();

// Last day of the first [days] days of a period, clipped so day 31 stays
// inside a shorter month.
DateTime sameStageEnd(DateTime start, DateTime end, int days) {
  DateTime stage = DateTime(start.year, start.month, start.day + days - 1);
  return stage.isAfter(end) ? end : stage;
}

// Mean spent by this stage across earlier periods, skipping periods with no
// spending at all (before the data starts). Null when none have any.
double? typicalByNow(List<double> soFar, List<double> fullPeriod) {
  List<double> used = [
    for (int i = 0; i < soFar.length; i++)
      if (fullPeriod[i] != 0) soFar[i]
  ];
  if (used.isEmpty) return null;
  return used.reduce((a, b) => a + b) / used.length;
}

double? typicalFullPeriod(List<double> fullPeriod) {
  List<double> used = fullPeriod.where((t) => t != 0).toList();
  if (used.isEmpty) return null;
  return used.reduce((a, b) => a + b) / used.length;
}

double projectedTotal(double spentSoFar, int daysElapsed, int periodDays) =>
    spentSoFar / daysElapsed * periodDays;

// Income lands in lumps (payday), so it isn't extrapolated: expect at least a
// typical period's income, or more if more has already arrived.
double expectedIncome(double incomeSoFar, double? typicalIncome) =>
    max(incomeSoFar, typicalIncome ?? 0);

// What can still be spent per day for the rest of the period to finish at
// [target]; zero once past it. Null on the last day.
double? dailyAllowance(double target, double spent, int daysLeft) =>
    daysLeft <= 0 ? null : max(0, target - spent) / daysLeft;
