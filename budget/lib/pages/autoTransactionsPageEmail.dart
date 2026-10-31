import 'dart:async';
import 'package:budget/colors.dart';
import 'package:budget/database/tables.dart';
import 'package:budget/pages/addEmailTemplate.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/struct/databaseGlobal.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/button.dart';
import 'package:budget/widgets/categoryIcon.dart';
import 'package:budget/widgets/globalSnackbar.dart';
import 'package:budget/widgets/navigationFramework.dart';
import 'package:budget/widgets/openContainerNavigation.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/openSnackbar.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:budget/widgets/util/appLinks.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:budget/functions.dart';
import 'package:html/parser.dart';

// Messages sent in via the messageToParse app link, newest first
List<String> recentCapturedNotifications = [];

Future queueTransactionFromMessage(String messageString,
    {bool willPushRoute = true, DateTime? dateTime}) async {
  String? title;
  double? amountDouble;
  List<ScannerTemplate> scannerTemplates =
      await database.getAllScannerTemplates();
  ScannerTemplate? templateFound;

  for (ScannerTemplate scannerTemplate in scannerTemplates) {
    if (messageString.contains(scannerTemplate.contains)) {
      templateFound = scannerTemplate;
      title = getTransactionTitleFromEmail(
          messageString,
          scannerTemplate.titleTransactionBefore,
          scannerTemplate.titleTransactionAfter);
      amountDouble = getTransactionAmountFromEmail(
          messageString,
          scannerTemplate.amountTransactionBefore,
          scannerTemplate.amountTransactionAfter);
      break;
    }
  }

  if (templateFound == null) return false;

  //if (amountDouble == null) amountDouble = getAmountFromString(title ?? "");
  // We don't need this line, we can still queue up a transaction without these details,
  // however maybe the user doesn't want to queue it up if its missing details?
  if (amountDouble == null || title == null) return false;

  TransactionCategory? category;
  TransactionAssociatedTitleWithCategory? foundTitle =
      (await database.getSimilarAssociatedTitles(title: title, limit: 1))
          .firstOrNull;
  category = foundTitle?.category;
  if (category == null) {
    category = await database
        .getCategoryInstanceOrNull(templateFound.defaultCategoryFk);
  }

  TransactionWallet? wallet = templateFound.walletFk == "-1"
      ? null
      : await database.getWalletInstanceOrNull(templateFound.walletFk);

  if (willPushRoute) {
    pushRoute(
      null,
      AddTransactionPage(
        useCategorySelectedIncome: true,
        routesToPopAfterDelete: RoutesToPopAfterDelete.None,
        selectedAmount: amountDouble,
        selectedTitle: title,
        selectedCategory: category,
        startInitialAddTransactionSequence: false,
        selectedWallet: wallet,
        selectedDate: dateTime,
      ),
    );
  } else {
    processAddTransactionFromParams(navigatorKey.currentContext!, {
      "title": title,
      "categoryPk": category?.categoryPk,
      "walletPk": wallet?.walletPk,
      "amount": amountDouble.toString(),
      "date": dateTime.toString(),
    });
  }
}

String? getTransactionTitleFromEmail(String messageString,
    String titleTransactionBefore, String titleTransactionAfter) {
  String? title;
  try {
    int startIndex = messageString.indexOf(titleTransactionBefore) +
        titleTransactionBefore.length;
    int endIndex = messageString.indexOf(titleTransactionAfter, startIndex);
    title = messageString.substring(startIndex, endIndex);
    title = title.replaceAll("\n", "");
    title = title.toLowerCase();
    title = title.capitalizeFirst;
  } catch (e) {}
  return title;
}

double? getTransactionAmountFromEmail(String messageString,
    String amountTransactionBefore, String amountTransactionAfter) {
  double? amountDouble;
  try {
    int startIndex = messageString.indexOf(amountTransactionBefore) +
        amountTransactionBefore.length;
    int endIndex = messageString.indexOf(amountTransactionAfter, startIndex);
    String amountString = messageString.substring(startIndex, endIndex);
    amountDouble = double.parse(amountString.replaceAll(RegExp('[^0-9.]'), ''));
  } catch (e) {}
  return amountDouble;
}

class ScannerTemplateEntry extends StatelessWidget {
  const ScannerTemplateEntry({
    required this.scannerTemplate,
    required this.messagesList,
    super.key,
  });
  final ScannerTemplate scannerTemplate;
  final List<String> messagesList;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15, bottom: 10),
      child: OpenContainerNavigation(
        openPage: AddEmailTemplate(
          messagesList: messagesList,
          scannerTemplate: scannerTemplate,
        ),
        borderRadius: 15,
        button: (openContainer) {
          return Tappable(
            borderRadius: 15,
            color: getColor(context, "lightDarkAccent"),
            onTap: openContainer,
            child: Padding(
              padding: const EdgeInsetsDirectional.only(
                start: 7,
                end: 15,
                top: 5,
                bottom: 5,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      CategoryIcon(
                          categoryPk: scannerTemplate.defaultCategoryFk,
                          size: 25),
                      SizedBox(width: 7),
                      TextFont(
                        text: scannerTemplate.templateName,
                        fontWeight: FontWeight.bold,
                      ),
                    ],
                  ),
                  ButtonIcon(
                    onTap: () async {
                      DeletePopupAction? action = await openDeletePopup(
                        context,
                        title: "Delete template?",
                        subtitle: scannerTemplate.templateName,
                      );
                      if (action == DeletePopupAction.Delete) {
                        await database.deleteScannerTemplate(
                            scannerTemplate.scannerTemplatePk);
                        popRoute(context);
                        openSnackbar(
                          SnackbarMessage(
                            title: "Deleted " + scannerTemplate.templateName,
                            icon: Icons.delete,
                          ),
                        );
                      }
                    },
                    icon: appStateSettings["outlinedIcons"]
                        ? Icons.delete_outlined
                        : Icons.delete_rounded,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String parseHtmlString(String htmlString) {
  final document = parse(htmlString);
  final String parsedString = parse(document.body!.text).documentElement!.text;

  return parsedString;
}

class EmailsList extends StatelessWidget {
  const EmailsList({
    required this.messagesList,
    this.onTap,
    this.backgroundColor,
    super.key,
  });
  final List<String> messagesList;
  final Function(String)? onTap;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ScannerTemplate>>(
      stream: database.watchAllScannerTemplates(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<ScannerTemplate> scannerTemplates = snapshot.data!;
          List<Widget> messageTxt = [];
          for (String messageString in messagesList) {
            bool doesEmailContain = false;
            String? title;
            double? amountDouble;
            String? templateFound;

            for (ScannerTemplate scannerTemplate in scannerTemplates) {
              if (messageString.contains(scannerTemplate.contains)) {
                doesEmailContain = true;
                templateFound = scannerTemplate.templateName;
                title = getTransactionTitleFromEmail(
                    messageString,
                    scannerTemplate.titleTransactionBefore,
                    scannerTemplate.titleTransactionAfter);
                amountDouble = getTransactionAmountFromEmail(
                    messageString,
                    scannerTemplate.amountTransactionBefore,
                    scannerTemplate.amountTransactionAfter);
                break;
              }
            }

            messageTxt.add(
              Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 15, vertical: 5),
                child: Tappable(
                  borderRadius: 15,
                  color: doesEmailContain &&
                          (title == null || amountDouble == null)
                      ? Theme.of(context)
                          .colorScheme
                          .selectableColorRed
                          .withOpacity(0.5)
                      : doesEmailContain
                          ? Theme.of(context)
                              .colorScheme
                              .selectableColorGreen
                              .withOpacity(0.5)
                          : backgroundColor ??
                              getColor(context, "lightDarkAccent"),
                  onTap: () {
                    if (onTap != null) onTap!(messageString);
                    if (onTap == null)
                      queueTransactionFromMessage(messageString);
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsetsDirectional.symmetric(
                              horizontal: 20, vertical: 15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              doesEmailContain &&
                                      (title == null || amountDouble == null)
                                  ? Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                          bottom: 5),
                                      child: TextFont(
                                        text: "Parsing failed.",
                                        fontWeight: FontWeight.bold,
                                        fontSize: 17,
                                      ),
                                    )
                                  : SizedBox(),
                              doesEmailContain
                                  ? templateFound == null
                                      ? TextFont(
                                          fontSize: 19,
                                          text: "Template Not found.",
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : TextFont(
                                          fontSize: 19,
                                          text: templateFound,
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                  : SizedBox(),
                              doesEmailContain
                                  ? title == null
                                      ? TextFont(
                                          fontSize: 15,
                                          text: "Title: Not found.",
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                      : TextFont(
                                          fontSize: 15,
                                          text: "Title: " + title,
                                          maxLines: 10,
                                          fontWeight: FontWeight.bold,
                                        )
                                  : SizedBox(),
                              doesEmailContain
                                  ? amountDouble == null
                                      ? Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  bottom: 8.0),
                                          child: TextFont(
                                            fontSize: 15,
                                            text:
                                                "Amount: Not found / invalid number.",
                                            maxLines: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Padding(
                                          padding:
                                              const EdgeInsetsDirectional.only(
                                                  bottom: 8.0),
                                          child: TextFont(
                                            fontSize: 15,
                                            text: "Amount: " +
                                                convertToMoney(
                                                    Provider.of<AllWallets>(
                                                        context),
                                                    amountDouble),
                                            maxLines: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                  : SizedBox(),
                              TextFont(
                                fontSize: 13,
                                text: messageString,
                                maxLines: 10,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return Column(
            children: messageTxt,
          );
        } else {
          return Container(width: 100, height: 100, color: Colors.white);
        }
      },
    );
  }
}
