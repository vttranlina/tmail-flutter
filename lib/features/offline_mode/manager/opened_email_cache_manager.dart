import 'package:core/utils/app_logger.dart';
import 'package:core/utils/file_utils.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/user_name.dart';
import 'package:jmap_dart_client/jmap/mail/email/email.dart';
import 'package:model/extensions/account_id_extensions.dart';
import 'package:model/extensions/email_id_extensions.dart';
import 'package:tmail_ui_user/features/caching/clients/opened_email_hive_cache_client.dart';
import 'package:tmail_ui_user/features/caching/utils/cache_utils.dart';
import 'package:tmail_ui_user/features/caching/utils/caching_constants.dart';
import 'package:tmail_ui_user/features/email/domain/extensions/detailed_email_extension.dart';
import 'package:tmail_ui_user/features/email/domain/model/detailed_email.dart';
import 'package:tmail_ui_user/features/offline_mode/extensions/list_detailed_email_hive_cache_extension.dart';
import 'package:tmail_ui_user/features/offline_mode/model/detailed_email_hive_cache.dart';

class OpenedEmailCacheManager {

  final OpenedEmailHiveCacheClient _cacheClient;
  final FileUtils _fileUtils;

  OpenedEmailCacheManager(this._cacheClient, this._fileUtils);

  Future<void> insertDetailedEmail(
    AccountId accountId,
    UserName userName,
    DetailedEmailHiveCache detailedEmailCache
  ) {
    final keyCache = TupleKey(detailedEmailCache.emailId, accountId.asString, userName.value).encodeKey;
    log('OpenedEmailCacheManager::insertDetailedEmail(): $keyCache');
    return _cacheClient.insertItem(keyCache, detailedEmailCache);
  }

  Future<void> removeDetailedEmail(
    AccountId accountId,
    UserName userName,
    String emailId
  ) {
    final keyCache = TupleKey(emailId, accountId.asString, userName.value).encodeKey;
    log('OpenedEmailCacheManager::removeDetailedEmail(): $keyCache');
    return _cacheClient.deleteItem(keyCache);
  }

  Future<List<DetailedEmailHiveCache>> getAllDetailedEmails(AccountId accountId, UserName userName) async {
    final detailedEmailCacheList = await _cacheClient.getListByTupleKey(accountId.asString, userName.value);
    detailedEmailCacheList.sortByLatestTime();
    log('OpenedEmailCacheManager::getAllDetailedEmails():SIZE: ${detailedEmailCacheList.length}');
    return detailedEmailCacheList;
  }

  Future<void> storeOpenedEmail(
    AccountId accountId,
    UserName userName,
    DetailedEmail detailedEmail
  ) async {
    final listDetailedEmails = await getAllDetailedEmails(accountId, userName);

    if (listDetailedEmails.length >= CachingConstants.maxNumberOpenedEmailsForOffline) {
      final lastElementsListEmail = listDetailedEmails.sublist(CachingConstants.maxNumberOpenedEmailsForOffline, listDetailedEmails.length);
      for (var email in lastElementsListEmail) {
        log('OpenedEmailCacheManager::handleStoreDetailedEmail():latestEmail: $email');
        if (email.emailContentPath != null) {
          await _deleteFileExisted(email.emailContentPath!);
        }
        await removeDetailedEmail(accountId, userName, email.emailId);
      }
    }
    await insertDetailedEmail(accountId, userName, detailedEmail.toHiveCache());
  }

  Future<bool> isOpenedDetailEmailCached(
    AccountId accountId,
    UserName userName,
    EmailId emailId
  ) async {
    final emailContentPathExists = await _isFileExisted(emailId);
    final detailedEmailCacheExists = await getOpenedEmailExistedInCache(accountId, userName, emailId);

    return emailContentPathExists == true && detailedEmailCacheExists != null;
  }

  Future<bool?> _isFileExisted(EmailId emailId) async {
    final fileSaved = await _fileUtils.isFileExisted(
      nameFile: emailId.asString,
      folderPath: CachingConstants.openedEmailContentFolderName,
    );
    log('OpenedEmailCacheManager::_getDetailedEmailCache():_getEmailContentPath: $fileSaved');
    return fileSaved;
  }

  Future<DetailedEmailHiveCache?> getOpenedEmailExistedInCache(
    AccountId accountId,
    UserName userName,
    EmailId emailId
  ) async {
    final keyCache = TupleKey(emailId.asString, accountId.asString, userName.value).encodeKey;
    final detailedEmailCache = await _cacheClient.getItem(keyCache,needToReopen: true);
    log('OpenedEmailCacheManager::getOpenedEmailExistedInCache(): $detailedEmailCache');
    return detailedEmailCache;
  }

  Future<void> _deleteFileExisted(String pathFile) async {
    await _fileUtils.deleteFile(pathFile);
  }
}