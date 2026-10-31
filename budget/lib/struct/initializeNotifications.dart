// Budgie is web-only, where Cashew's scheduled notifications don't run.
// These stay as no-ops because the rest of the app calls them.

Future<String?> initializeNotifications() async {
  return null;
}

Future<bool> runNotificationPayLoads(context) async {
  return false;
}

Future<void> setDailyNotifications(context) async {}

Future<void> setUpcomingNotifications(context) async {}
