
import 'package:flutter/cupertino.dart';
import 'package:model/mailbox/expand_mode.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_categories_expand_mode.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';

enum MailboxCategories {
  exchange,
  personalMailboxes,
  appGrid,
  teamMailboxes
}

extension MailboxCategoriessExtension on MailboxCategories {

  String get keyValue {
    switch(this) {
      case MailboxCategories.exchange:
        return 'exchange';
      case MailboxCategories.personalMailboxes:
        return 'personalMailboxes';
      case MailboxCategories.appGrid:
        return 'appGrid';
      case MailboxCategories.teamMailboxes:
        return 'teamMailboxes';
    }
  }

  String getTitle(BuildContext context) {
    switch(this) {
      case MailboxCategories.exchange:
        return AppLocalizations.of(context).exchange;
      case MailboxCategories.personalMailboxes:
        return AppLocalizations.of(context).personalMailboxes;
      case MailboxCategories.appGrid:
        return AppLocalizations.of(context).appGridTittle;
      case MailboxCategories.teamMailboxes:
        return AppLocalizations.of(context).teamMailBoxes;
    }
  }

  ExpandMode getExpandMode(MailboxCategoriesExpandMode categoriesExpandMode) {
    switch(this) {
      case MailboxCategories.exchange:
        return categoriesExpandMode.defaultMailbox;
      case MailboxCategories.personalMailboxes:
        return categoriesExpandMode.personalMailboxes;
      case MailboxCategories.teamMailboxes:
        return categoriesExpandMode.teamMailboxes;
      default:
        return ExpandMode.COLLAPSE;
    }
  }
}