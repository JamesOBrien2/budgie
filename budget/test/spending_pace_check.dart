// Run: dart run --enable-asserts test/spending_pace_check.dart
import 'package:budget/struct/spendingPace.dart';

void main() {
  assert(inclusiveDays(DateTime(2026, 11, 1), DateTime(2026, 11, 10, 15)) == 10);
  // Crosses the October DST change.
  assert(inclusiveDays(DateTime(2026, 10, 1), DateTime(2026, 10, 31)) == 31);

  DateTime febStart = DateTime(2026, 2, 1), febEnd = DateTime(2026, 2, 28);
  assert(sameStageEnd(febStart, febEnd, 10) == DateTime(2026, 2, 10));
  assert(sameStageEnd(febStart, febEnd, 31) == febEnd);

  assert(typicalByNow([100, 0, 50], [300, 0, 200]) == 75);
  assert(typicalFullPeriod([300, 0, 200]) == 250);
  assert(typicalByNow([0, 0], [0, 0]) == null);

  assert(projectedTotal(100, 10, 30) == 300);
  assert(expectedIncome(500, 2000) == 2000); // payday still to come
  assert(expectedIncome(2100, 2000) == 2100);
  assert(expectedIncome(0, null) == 0);

  assert(dailyAllowance(300, 100, 20) == 10);
  assert(dailyAllowance(300, 400, 20) == 0);
  assert(dailyAllowance(300, 100, 0) == null);
  print('spending pace checks passed');
}
