
class CachingConstants {
  static const int MAILBOX_CACHE_IDENTIFY = 1;
  static const int MAILBOX_RIGHTS_CACHE_IDENTIFY = 2;
  static const int STATE_CACHE_IDENTIFY = 3;
  static const int STATE_TYPE_IDENTIFY = 4;
  static const int EMAIL_CACHE_IDENTIFY = 5;
  static const int EMAIL_ADDRESS_HIVE_CACHE_IDENTIFY = 6;
  static const int RECENT_SEARCH_HIVE_CACHE_IDENTIFY = 7;
  static const int TOKEN_OIDC_HIVE_CACHE_IDENTIFY = 8;
  static const int ACCOUNT_HIVE_CACHE_IDENTIFY = 9;
  static const int ENCRYPTION_KEY_HIVE_CACHE_IDENTIFY = 10;
  static const int AUTHENTICATION_INFO_HIVE_CACHE_IDENTIFY = 11;
  static const int RECENT_LOGIN_URL_HIVE_CACHE_IDENTITY = 12;
  static const int RECENT_LOGIN_USERNAME_HIVE_CACHE_IDENTITY = 13;
  static const int FCM_SUBSCRIPTION_HIVE_CACHE_IDENTITY = 14;
  static const int ATTACHMENT_HIVE_CACHE_ID = 15;
  static const int EMAIL_HEADER_HIVE_CACHE_ID = 16;
  static const int DETAILED_EMAIL_HIVE_CACHE_ID = 17;
  static const int SENDING_EMAIL_HIVE_CACHE_ID = 18;
  static const int typeIdSessionHiveObj = 19;

  static const String fcmCacheBoxName = 'fcm_cache_box';
  static const String incomingEmailedCacheBoxName = 'incoming_emailed_cache_box';
  static const String openedEmailCacheBoxName = 'opened_email_cache_box';
  static const String sendingEmailCacheBoxName = 'sending_email_cache_box';
  static const String sessionCacheBoxName = 'session_cache_box';

  static const String incomingEmailedContentFolderName = 'incoming_emailed';
  static const String openedEmailContentFolderName = 'opened_email';

  static const int maxNumberNewEmailsForOffline = 10;
  static const int maxNumberOpenedEmailsForOffline = 30;
}