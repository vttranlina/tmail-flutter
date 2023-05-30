
import 'package:core/utils/app_logger.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:model/extensions/account_id_extensions.dart';
import 'package:tmail_ui_user/features/caching/clients/sending_email_hive_cache_client.dart';
import 'package:tmail_ui_user/features/caching/utils/cache_utils.dart';
import 'package:tmail_ui_user/features/offline_mode/extensions/list_sending_email_hive_cache_extension.dart';
import 'package:tmail_ui_user/features/offline_mode/model/sending_email_hive_cache.dart';

class SendingEmailCacheManager {

  final SendingEmailHiveCacheClient _hiveCacheClient;

  SendingEmailCacheManager(this._hiveCacheClient);

  Future<void> storeSendingEmail(
    AccountId accountId,
    UserName userName,
    SendingEmailHiveCache sendingEmailHiveCache
  ) {
    final keyCache = TupleKey(sendingEmailHiveCache.sendingId, accountId.asString, userName.value).encodeKey;
    log('SendingEmailCacheManager::storeSendingEmail():keyCache: $keyCache | sendingEmailHiveCache: $sendingEmailHiveCache');
    return _hiveCacheClient.insertItem(keyCache, sendingEmailHiveCache);
  }

  Future<List<SendingEmailHiveCache>> getAllSendingEmails(AccountId accountId, UserName userName) async {
     final sendingEmailsCache = await _hiveCacheClient.getListByTupleKey(accountId.asString, userName.value);
     log('SendingEmailCacheManager::getAllSendingEmails():COUNT: ${sendingEmailsCache.length}');
     sendingEmailsCache.sortByLatestTime();
     return sendingEmailsCache;
  }

  Future<void> deleteSendingEmail(
    AccountId accountId,
    UserName userName,
    String sendingEmailId
  ) {
    final keyCache = TupleKey(sendingEmailId, accountId.asString, userName.value).encodeKey;
    log('SendingEmailCacheManager::deleteSendingEmail():keyCache: $keyCache');
    return _hiveCacheClient.deleteItem(keyCache);
  }
}