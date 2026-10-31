import 'dart:convert';
import 'package:budget/functions.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/walletEntry.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/defaultCategories.dart';
import 'package:http/http.dart' as http;

//Initialize default values in database
Future<bool> initializeDefaultDatabase() async {
  //Initialize default categories, but not after a backup load
  if (isDatabaseImportedOnThisSession != true &&
      (await database.getAllCategories()).length <= 0) {
    Map<String, dynamic>? seed = await loadSeed();
    if (seed != null) {
      await applySeed(seed);
    } else {
      await createDefaultCategories();
    }
  }

  if ((await database.getAllWallets()).length <= 0) {
    await database.createOrUpdateWallet(
      defaultWallet(),
      customDateTimeModified: DateTime(0),
    );
  }
  return true;
}

// Budgie: a fresh database is set up from seed.json, served next to the app.
// The file is personal and gitignored; see seed.example.json for the format.
Future<Map<String, dynamic>?> loadSeed() async {
  try {
    final response = await http.get(Uri.base.resolve("seed.json"));
    if (response.statusCode == 200) return jsonDecode(response.body);
  } catch (e) {
    print("No seed.json, using default categories: " + e.toString());
  }
  return null;
}

// Primary keys are fixed so running this twice overwrites rather than duplicates
Future applySeed(Map<String, dynamic> seed) async {
  print("Creating database from seed.json");
  List wallets = seed["wallets"] ?? [];
  for (int i = 0; i < wallets.length; i++) {
    await database.createOrUpdateWallet(
      TransactionWallet(
        walletPk: i.toString(),
        name: wallets[i]["name"],
        colour: null,
        iconName: null,
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        order: i,
        currency: wallets[i]["currency"],
        decimals: 2,
        homePageWidgetDisplay: defaultWalletHomePageWidgetDisplay,
      ),
      customDateTimeModified: DateTime(0),
    );
  }

  Map<String, String> categoryPks = {};
  List categories = seed["categories"] ?? [];
  for (int i = 0; i < categories.length; i++) {
    Map category = categories[i];
    String pk = (i + 1).toString();
    categoryPks[category["name"]] = pk;
    await database.createOrUpdateCategory(
      TransactionCategory(
        categoryPk: pk,
        name: category["name"],
        colour: seedColour(category["colour"]),
        iconName: category["icon"],
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        order: i,
        income: category["income"] == true,
      ),
      customDateTimeModified: DateTime(0),
    );
  }

  List budgets = seed["budgets"] ?? [];
  for (int i = 0; i < budgets.length; i++) {
    Map budget = budgets[i];
    DateTime start = DateTime.parse(budget["start"]);
    await database.createOrUpdateBudget(
      updateSharedEntry: false,
      Budget(
        budgetPk: "seed-budget-" + i.toString(),
        name: budget["name"],
        amount: (budget["amount"] as num).toDouble(),
        colour: seedColour(budget["colour"]),
        startDate: start,
        endDate: DateTime.parse(budget["end"] ?? budget["start"]),
        categoryFks: [
          for (String name in budget["categories"] ?? [])
            if (categoryPks[name] != null) categoryPks[name]!
        ],
        addedTransactionsOnly: false,
        periodLength: 1,
        reoccurrence: BudgetReoccurence.values.byName(budget["period"]),
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        pinned: true,
        order: i,
        walletFk: "0",
        budgetTransactionFilters: [],
        memberTransactionFilters: null,
        sharedKey: null,
        sharedOwnerMember: null,
        sharedDateUpdated: null,
        sharedMembers: null,
        sharedAllMembersEver: null,
        isAbsoluteSpendingLimit: false,
        income: false,
        archived: false,
      ),
    );
  }

  List goals = seed["goals"] ?? [];
  for (int i = 0; i < goals.length; i++) {
    Map goal = goals[i];
    await database.createOrUpdateObjective(
      Objective(
        objectivePk: "seed-goal-" + i.toString(),
        name: goal["name"],
        amount: (goal["amount"] as num).toDouble(),
        order: i,
        colour: seedColour(goal["colour"]),
        dateCreated: DateTime.now(),
        dateTimeModified: null,
        iconName: goal["icon"],
        emojiIconName: null,
        income: true,
        pinned: true,
        walletFk: "0",
        archived: false,
        type: ObjectiveType.goal,
      ),
    );
  }

  if (wallets.isNotEmpty) await setPrimaryWallet("0");
  if (seed["firstDayOfWeek"] != null) {
    await updateSettings("firstDayOfWeek", seed["firstDayOfWeek"],
        updateGlobalState: false);
  }
  // The seed replaces onboarding
  await updateSettings("hasOnboarded", true, updateGlobalState: true);
}

// "#7cb342" -> "0xff7cb342", the format Cashew stores colours in
String? seedColour(String? hex) =>
    hex == null ? null : "0xff" + hex.replaceFirst("#", "");

Future<bool> createDefaultCategories() async {
  print("Creating default categories");
  for (TransactionCategory category in defaultCategories()) {
    try {
      await database.getCategory(category.categoryPk).$2;
    } catch (e) {
      print(
          e.toString() + " default category does not already exist, creating");
      await database.createOrUpdateCategory(category,
          customDateTimeModified: DateTime(0));
    }
  }
  return true;
}

TransactionWallet defaultWallet() {
  return TransactionWallet(
    walletPk: "0",
    name: "default-account-name".tr(),
    dateCreated: DateTime.now(),
    order: 0,
    currency: getDevicesDefaultCurrencyCode(),
    dateTimeModified: null,
    decimals: 2,
    homePageWidgetDisplay: defaultWalletHomePageWidgetDisplay,
  );
}
