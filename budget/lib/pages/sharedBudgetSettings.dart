import 'package:budget/functions.dart';
import 'package:budget/pages/addTransactionPage.dart';
import 'package:budget/widgets/openBottomSheet.dart';
import 'package:budget/widgets/openPopup.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/framework/popupFramework.dart';

class CategoryMemberContainer extends StatelessWidget {
  const CategoryMemberContainer({
    Key? key,
    required this.member,
    required this.setMember,
    required this.onDelete,
    required this.isOwner,
    required this.isYou,
    required this.canModify,
  }) : super(key: key);

  final String member;
  final Function(String) setMember;
  final VoidCallback onDelete;
  final bool isOwner;
  final bool isYou;
  final bool canModify;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 8.0),
      child: Tappable(
        onTap: () {
          if (!canModify)
            memberPopup(context, member);
          else
            openBottomSheet(
              context,
              PopupFramework(
                title: "Edit Member",
                subtitle: "Edit the nickname of the member",
                child: Column(
                  children: [
                    SelectText(
                      buttonLabel: null,
                      icon: appStateSettings["outlinedIcons"]
                          ? Icons.person_outlined
                          : Icons.person_rounded,
                      setSelectedText: (_) {},
                      nextWithInput: setMember,
                      selectedText: member,
                      placeholder: "example@gmail.com",
                      autoFocus: false,
                    ),
                    SelectText(
                      buttonLabel: "Edit Member",
                      icon: appStateSettings["outlinedIcons"]
                          ? Icons.sell_outlined
                          : Icons.sell_rounded,
                      setSelectedText: (_) {},
                      nextWithInput: (text) {
                        Map<dynamic, dynamic> nicknames =
                            appStateSettings["usersNicknames"];
                        nicknames[member] = text;
                        updateSettings("usersNicknames", nicknames,
                            pagesNeedingRefresh: [], updateGlobalState: false);
                      },
                      selectedText:
                          appStateSettings["usersNicknames"][member] ?? "",
                      placeholder: "Nickname",
                      textCapitalization: TextCapitalization.words,
                      autoFocus: true,
                    ),
                  ],
                ),
              ),
            );
        },
        borderRadius: 15,
        color: getColor(context, "lightDarkAccent"),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsetsDirectional.symmetric(
                    horizontal: 25, vertical: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFont(
                      text: isOwner
                          ? isYou
                              ? getMemberNickname(member) == member
                                  ? "Owner (You)"
                                  : getMemberNickname(member) + " (Owner - You)"
                              : getMemberNickname(member) == member
                                  ? "Owner"
                                  : getMemberNickname(member) + " (Owner)"
                          : isYou
                              ? getMemberNickname(member) != "Me"
                                  ? getMemberNickname(member) + " (Member - Me)"
                                  : "Me (Member)"
                              : getMemberNickname(member) == member
                                  ? "Member"
                                  : getMemberNickname(member) + " (Member)",
                      fontSize: 15,
                      textColor: Theme.of(context).colorScheme.secondary,
                    ),
                    TextFont(
                      text: member,
                      fontSize: 16,
                    ),
                  ],
                ),
              ),
            ),
            canModify
                ? Tappable(
                    onTap: () async {
                      await openPopup(
                        context,
                        title: "Remove Member?",
                        description:
                            "The transactions this user has downloaded will still be available to them",
                        icon: appStateSettings["outlinedIcons"]
                            ? Icons.delete_outlined
                            : Icons.delete_rounded,
                        onSubmitLabel: "Remove",
                        onSubmit: () {
                          popRoute(context);
                          onDelete();
                        },
                        onCancelLabel: "cancel".tr(),
                        onCancel: () {
                          popRoute(context);
                        },
                      );
                    },
                    borderRadius: 15,
                    color: getColor(context, "lightDarkAccent"),
                    child: Padding(
                      padding: const EdgeInsetsDirectional.all(14),
                      child: Icon(
                        appStateSettings["outlinedIcons"]
                            ? Icons.close_outlined
                            : Icons.close_rounded,
                        size: 25,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  )
                : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}

memberPopup(context, String member) {
  openBottomSheet(
    context,
    PopupFramework(
      title: "Edit Nickname",
      subtitle: "Edit the nickname of the member",
      child: Column(
        children: [
          Opacity(
            opacity: 0.4,
            child: SelectText(
              buttonLabel: null,
              icon: appStateSettings["outlinedIcons"]
                  ? Icons.person_outlined
                  : Icons.person_rounded,
              setSelectedText: (_) {},
              selectedText: member,
              placeholder: "example@gmail.com",
              autoFocus: false,
              readOnly: true,
            ),
          ),
          SelectText(
            buttonLabel: "Edit Nickname",
            icon: appStateSettings["outlinedIcons"]
                ? Icons.sell_outlined
                : Icons.sell_rounded,
            setSelectedText: (_) {},
            nextWithInput: (text) {
              Map<dynamic, dynamic> nicknames =
                  appStateSettings["usersNicknames"];
              nicknames[member] = text;
              updateSettings("usersNicknames", nicknames,
                  pagesNeedingRefresh: [], updateGlobalState: false);
            },
            selectedText: appStateSettings["usersNicknames"][member] ?? "",
            placeholder: "Nickname",
            autoFocus: false,
          ),
        ],
      ),
    ),
  );
}
