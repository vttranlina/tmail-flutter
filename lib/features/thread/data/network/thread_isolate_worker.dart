import 'dart:async';

import 'package:core/utils/app_logger.dart';
import 'package:core/utils/build_utils.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/properties/properties.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/core/sort/comparator.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_comparator.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_comparator_property.dart';
import 'package:jmap_dart_client/jmap/mail/email/email_filter_condition.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/email_property.dart';
import 'package:model/extensions/list_email_extension.dart';
import 'package:tmail_ui_user/features/email/data/network/email_api.dart';
import 'package:tmail_ui_user/features/thread/data/model/empty_trash_folder_arguments.dart';
import 'package:tmail_ui_user/features/thread/data/network/thread_api.dart';
import 'package:worker_manager/worker_manager.dart';

class ThreadIsolateWorker {
  final ThreadAPI _threadAPI;
  final EmailAPI _emailAPI;
  final Executor _isolateExecutor;

  ThreadIsolateWorker(this._threadAPI, this._emailAPI, this._isolateExecutor);

  Future<List<EmailId>> emptyTrashFolder(
    Session session,
    AccountId accountId,
    MailboxId mailboxId,
    Future<void> Function(List<EmailId>? newDestroyed) updateDestroyedEmailCache,
  ) async {
    if (BuildUtils.isWeb) {
      return _emptyTrashFolderOnWeb(session, accountId, mailboxId, updateDestroyedEmailCache);
    } else {
      final result = await _isolateExecutor.execute(
          arg1: EmptyTrashFolderArguments(session, _threadAPI, _emailAPI, accountId, mailboxId),
          fun1: _emptyTrashFolderAction,
          notification: (value) {
            if (value is List<EmailId>) {
              updateDestroyedEmailCache.call(value);
              log('ThreadIsolateWorker::emptyTrashFolder(): onUpdateProgress: PERCENT ${value.length}');
            }
          });
      return result;
    }
  }

  static Future<List<EmailId>> _emptyTrashFolderAction(EmptyTrashFolderArguments args, TypeSendPort sendPort) async {
    List<EmailId> emailListCompleted = List.empty(growable: true);
    try {
      var hasEmails = true;
      Email? lastEmail;

      while (hasEmails) {
        final emailsResponse = await args.threadAPI.getAllEmail(
          args.session,
          args.accountId,
          sort: <Comparator>{}..add(
            EmailComparator(EmailComparatorProperty.receivedAt)
              ..setIsAscending(false)),
          filter: EmailFilterCondition(inMailbox: args.trashMailboxId, before: lastEmail?.receivedAt),
          properties: Properties({EmailProperty.id}));

        var newEmailList = emailsResponse.emailList ?? <Email>[];
        if (lastEmail != null) {
          newEmailList = newEmailList.where((email) => email.id != lastEmail!.id).toList();
        }

        log('ThreadIsolateWorker::_emptyTrashFolderAction(): ${newEmailList.length}');

        if (newEmailList.isNotEmpty) {
          lastEmail = newEmailList.last;
          hasEmails = true;
          final listEmailIdDeleted = await args.emailAPI.deleteMultipleEmailsPermanently(args.session, args.accountId, newEmailList.listEmailIds);

          if (listEmailIdDeleted.isNotEmpty && listEmailIdDeleted.length == newEmailList.listEmailIds.length) {
            sendPort.send(listEmailIdDeleted);
          }
          emailListCompleted.addAll(listEmailIdDeleted);

          sendPort.send(emailListCompleted);
        } else {
          hasEmails = false;
        }
      }
    } catch (e) {
      log('ThreadIsolateWorker::_emptyTrashFolderAction(): ERROR: $e');
    }
    log('ThreadIsolateWorker::_emptyTrashFolderAction(): TOTAL_REMOVE: ${emailListCompleted.length}');
    return emailListCompleted;
  }

  Future<List<EmailId>> _emptyTrashFolderOnWeb(
    Session session,
    AccountId accountId,
    MailboxId trashMailboxId,
    Future<void> Function(List<EmailId> newDestroyed) updateDestroyedEmailCache,
  ) async {
    List<EmailId> emailListCompleted = List.empty(growable: true);
    try {
      var hasEmails = true;
      Email? lastEmail;

      while (hasEmails) {
        final emailsResponse = await _threadAPI.getAllEmail(
          session,
          accountId,
          sort: <Comparator>{}..add(
            EmailComparator(EmailComparatorProperty.receivedAt)
              ..setIsAscending(false)),
          filter: EmailFilterCondition(inMailbox: trashMailboxId, before: lastEmail?.receivedAt),
          properties: Properties({EmailProperty.id}));

        var newEmailList = emailsResponse.emailList ?? <Email>[];
        if (lastEmail != null) {
          newEmailList = newEmailList.where((email) => email.id != lastEmail!.id).toList();
        }

        log('ThreadIsolateWorker::_emptyTrashFolderOnWeb(): ${newEmailList.length}');

        if (newEmailList.isNotEmpty) {
          lastEmail = newEmailList.last;
          hasEmails = true;
          final listEmailIdDeleted = await _emailAPI.deleteMultipleEmailsPermanently(session, accountId, newEmailList.listEmailIds);

          if (listEmailIdDeleted.isNotEmpty && listEmailIdDeleted.length == newEmailList.listEmailIds.length) {
            await updateDestroyedEmailCache(listEmailIdDeleted);
          }
          emailListCompleted.addAll(listEmailIdDeleted);

        } else {
          hasEmails = false;
        }
      }
    } catch (e) {
      log('ThreadIsolateWorker::_emptyTrashFolderOnWeb(): ERROR: $e');
    }
    log('ThreadIsolateWorker::_emptyTrashFolderOnWeb(): TOTAL_REMOVE: ${emailListCompleted.length}');
    return emailListCompleted;
  }
}
