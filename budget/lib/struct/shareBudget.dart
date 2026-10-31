import 'package:budget/database/tables.dart';

// Shared budgets synced through Cashew's Firebase project, which Budgie
// doesn't use. These stay as no-ops because the rest of the app calls them;
// the sharing UI is gated on the "sharedBudgets" setting, which stays off.

Future<bool> shareBudget(Budget? budgetToShare, context) async => false;

Future<bool> removedSharedFromBudget(Budget sharedBudget,
        {bool removeFromServer = true}) async =>
    false;

Future<bool> leaveSharedBudget(Budget sharedBudget) async => false;

Future<bool> addMemberToBudget(
        String sharedKey, String member, Budget budget) async =>
    false;

Future<bool> removeMemberFromBudget(
        String sharedKey, String member, Budget budget) async =>
    false;

Future<dynamic> getMembersFromBudget(String sharedKey, Budget budget) async =>
    null;

Future<bool> getCloudBudgets() async => false;

Future<bool> sendTransactionSet(Transaction transaction, Budget budget) async =>
    false;

Future<bool> sendTransactionAdd(Transaction transaction, Budget budget) async =>
    false;

Future<bool> sendTransactionDelete(
        Transaction transaction, Budget budget) async =>
    false;

Future<bool> syncPendingQueueOnServer() async => false;

Future<bool> updateTransactionOnServerAfterChangingCategoryInformation(
        TransactionCategory category) async =>
    false;
