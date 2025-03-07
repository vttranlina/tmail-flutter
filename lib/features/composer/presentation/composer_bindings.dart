import 'package:core/core.dart';
import 'package:core/utils/file_utils.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:get/get.dart';
import 'package:tmail_ui_user/features/base/base_bindings.dart';
import 'package:tmail_ui_user/features/caching/clients/state_cache_client.dart';
import 'package:tmail_ui_user/features/composer/data/datasource/composer_datasource.dart';
import 'package:tmail_ui_user/features/composer/data/datasource/contact_datasource.dart';
import 'package:tmail_ui_user/features/composer/data/datasource_impl/composer_datasource_impl.dart';
import 'package:tmail_ui_user/features/composer/data/datasource_impl/contact_datasource_impl.dart';
import 'package:tmail_ui_user/features/composer/data/repository/composer_repository_impl.dart';
import 'package:tmail_ui_user/features/composer/data/repository/contact_repository_impl.dart';
import 'package:tmail_ui_user/features/composer/domain/repository/composer_repository.dart';
import 'package:tmail_ui_user/features/composer/domain/repository/contact_repository.dart';
import 'package:tmail_ui_user/features/composer/domain/usecases/download_image_as_base64_interactor.dart';
import 'package:tmail_ui_user/features/composer/domain/usecases/save_email_as_drafts_interactor.dart';
import 'package:tmail_ui_user/features/composer/domain/usecases/update_email_drafts_interactor.dart';
import 'package:tmail_ui_user/features/composer/domain/usecases/upload_attachment_interactor.dart';
import 'package:tmail_ui_user/features/composer/presentation/composer_controller.dart';
import 'package:tmail_ui_user/features/composer/presentation/controller/rich_text_web_controller.dart';
import 'package:tmail_ui_user/features/composer/presentation/controller/rich_text_mobile_tablet_controller.dart';
import 'package:tmail_ui_user/features/email/data/datasource/email_datasource.dart';
import 'package:tmail_ui_user/features/email/data/datasource/html_datasource.dart';
import 'package:tmail_ui_user/features/email/data/datasource_impl/email_datasource_impl.dart';
import 'package:tmail_ui_user/features/email/data/datasource_impl/email_hive_cache_datasource_impl.dart';
import 'package:tmail_ui_user/features/email/data/datasource_impl/html_datasource_impl.dart';
import 'package:tmail_ui_user/features/email/data/local/html_analyzer.dart';
import 'package:tmail_ui_user/features/email/data/network/email_api.dart';
import 'package:tmail_ui_user/features/email/data/repository/email_repository_impl.dart';
import 'package:tmail_ui_user/features/email/domain/repository/email_repository.dart';
import 'package:tmail_ui_user/features/email/domain/usecases/get_email_content_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource/mailbox_datasource.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource/state_datasource.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource_impl/mailbox_cache_datasource_impl.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource_impl/mailbox_datasource_impl.dart';
import 'package:tmail_ui_user/features/mailbox/data/datasource_impl/state_datasource_impl.dart';
import 'package:tmail_ui_user/features/mailbox/data/local/mailbox_cache_manager.dart';
import 'package:tmail_ui_user/features/mailbox/data/network/mailbox_api.dart';
import 'package:tmail_ui_user/features/mailbox/data/network/mailbox_isolate_worker.dart';
import 'package:tmail_ui_user/features/mailbox/data/repository/mailbox_repository_impl.dart';
import 'package:tmail_ui_user/features/mailbox/domain/repository/mailbox_repository.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/repository/composer_cache_repository.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/remove_composer_cache_on_web_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/domain/usecases/save_composer_cache_on_web_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/domain/usecases/get_all_identities_interactor.dart';
import 'package:tmail_ui_user/features/manage_account/presentation/profiles/identities/identity_interactors_bindings.dart';
import 'package:tmail_ui_user/features/offline_mode/manager/detailed_email_cache_manager.dart';
import 'package:tmail_ui_user/features/offline_mode/manager/detailed_email_cache_worker_queue.dart';
import 'package:tmail_ui_user/features/offline_mode/manager/opened_email_cache_manager.dart';
import 'package:tmail_ui_user/features/offline_mode/manager/opened_email_cache_worker_queue.dart';
import 'package:tmail_ui_user/features/offline_mode/manager/sending_email_cache_manager.dart';
import 'package:tmail_ui_user/features/thread/data/local/email_cache_manager.dart';
import 'package:tmail_ui_user/features/upload/data/datasource/attachment_upload_datasource.dart';
import 'package:tmail_ui_user/features/upload/data/datasource_impl/attachment_upload_datasource_impl.dart';
import 'package:tmail_ui_user/features/upload/data/network/file_uploader.dart';
import 'package:tmail_ui_user/features/upload/domain/usecases/local_file_picker_interactor.dart';
import 'package:tmail_ui_user/features/upload/presentation/controller/upload_controller.dart';
import 'package:tmail_ui_user/main/bindings/network/binding_tag.dart';
import 'package:tmail_ui_user/main/exceptions/cache_exception_thrower.dart';
import 'package:tmail_ui_user/main/exceptions/remote_exception_thrower.dart';
import 'package:uuid/uuid.dart';
import 'package:worker_manager/worker_manager.dart';

class ComposerBindings extends BaseBindings {

  @override
  void dependencies() {
    _bindingsUtils();
    super.dependencies();
  }

  void _bindingsUtils() {
    Get.lazyPut(() => FileUploader(Get.find<DioClient>(tag: BindingTag.isolateTag), Get.find<Executor>()));
  }

  @override
  void bindingsDataSourceImpl() {
    Get.lazyPut(() => AttachmentUploadDataSourceImpl(
      Get.find<FileUploader>(),
      Get.find<Uuid>(),
      Get.find<RemoteExceptionThrower>()
    ));
    Get.lazyPut(() => ComposerDataSourceImpl(Get.find<DownloadClient>(), Get.find<RemoteExceptionThrower>()));
    Get.lazyPut(() => ContactDataSourceImpl(Get.find<CacheExceptionThrower>()));
    Get.lazyPut(() => MailboxDataSourceImpl(
      Get.find<MailboxAPI>(),
      Get.find<MailboxIsolateWorker>(),
      Get.find<RemoteExceptionThrower>()));
    Get.lazyPut(() => MailboxCacheDataSourceImpl(
        Get.find<MailboxCacheManager>(),
        Get.find<CacheExceptionThrower>()));
    Get.lazyPut(() => EmailDataSourceImpl(
      Get.find<EmailAPI>(),
      Get.find<RemoteExceptionThrower>()));
    Get.lazyPut(() => HtmlDataSourceImpl(
      Get.find<HtmlAnalyzer>(),
      Get.find<DioClient>(),
      Get.find<RemoteExceptionThrower>()));
    Get.lazyPut(() => StateDataSourceImpl(Get.find<StateCacheClient>(), Get.find<CacheExceptionThrower>()));
    Get.lazyPut(() => EmailHiveCacheDataSourceImpl(
      Get.find<DetailedEmailCacheManager>(),
      Get.find<OpenedEmailCacheManager>(),
      Get.find<DetailedEmailCacheWorkerQueue>(),
      Get.find<OpenedEmailCacheWorkerQueue>(),
      Get.find<EmailCacheManager>(),
      Get.find<SendingEmailCacheManager>(),
      Get.find<FileUtils>(),
      Get.find<CacheExceptionThrower>()));
  }

  @override
  void bindingsDataSource() {
    Get.lazyPut<AttachmentUploadDataSource>(() => Get.find<AttachmentUploadDataSourceImpl>());
    Get.lazyPut<ComposerDataSource>(() => Get.find<ComposerDataSourceImpl>());
    Get.lazyPut<ContactDataSource>(() => Get.find<ContactDataSourceImpl>());
    Get.lazyPut<MailboxDataSource>(() => Get.find<MailboxDataSourceImpl>());
    Get.lazyPut<EmailDataSource>(() => Get.find<EmailDataSourceImpl>());
    Get.lazyPut<HtmlDataSource>(() => Get.find<HtmlDataSourceImpl>());
    Get.lazyPut<StateDataSource>(() => Get.find<StateDataSourceImpl>());
  }

  @override
  void bindingsRepositoryImpl() {
    Get.lazyPut(() => ComposerRepositoryImpl(
        Get.find<AttachmentUploadDataSource>(),
        Get.find<ComposerDataSource>()));
    Get.lazyPut(() => ContactRepositoryImpl(Get.find<ContactDataSource>()));
    Get.lazyPut(() => MailboxRepositoryImpl(
      {
        DataSourceType.network: Get.find<MailboxDataSource>(),
        DataSourceType.local: Get.find<MailboxCacheDataSourceImpl>()
      },
      Get.find<StateDataSource>(),
    ));
    Get.lazyPut(() => EmailRepositoryImpl(
      {
        DataSourceType.network: Get.find<EmailDataSource>(),
        DataSourceType.hiveCache: Get.find<EmailHiveCacheDataSourceImpl>()
      },
      Get.find<HtmlDataSource>(),
      Get.find<StateDataSource>(),
    ));
  }

  @override
  void bindingsRepository() {
    Get.lazyPut<ComposerRepository>(() => Get.find<ComposerRepositoryImpl>());
    Get.lazyPut<ContactRepository>(() => Get.find<ContactRepositoryImpl>());
    Get.lazyPut<MailboxRepository>(() => Get.find<MailboxRepositoryImpl>());
    Get.lazyPut<EmailRepository>(() => Get.find<EmailRepositoryImpl>());
  }

  @override
  void bindingsInteractor() {
    Get.lazyPut(() => LocalFilePickerInteractor());
    Get.lazyPut(() => UploadAttachmentInteractor(Get.find<ComposerRepository>()));
    Get.lazyPut(() => SaveEmailAsDraftsInteractor(
        Get.find<EmailRepository>(),
        Get.find<MailboxRepository>()));
    Get.lazyPut(() => GetEmailContentInteractor(Get.find<EmailRepository>()));
    Get.lazyPut(() => UpdateEmailDraftsInteractor(
        Get.find<EmailRepository>(),
        Get.find<MailboxRepository>()));
    Get.lazyPut(() => RemoveComposerCacheOnWebInteractor(Get.find<ComposerCacheRepository>()));
    Get.lazyPut(() => SaveComposerCacheOnWebInteractor(Get.find<ComposerCacheRepository>()));
    Get.lazyPut(() => DownloadImageAsBase64Interactor(Get.find<ComposerRepository>()));

    IdentityInteractorsBindings().dependencies();
  }

  @override
  void bindingsController() {
    Get.lazyPut(() => RichTextMobileTabletController());
    Get.lazyPut(() => UploadController(Get.find<UploadAttachmentInteractor>()));
    Get.lazyPut(() => RichTextWebController());
    Get.lazyPut(() => ComposerController(
        Get.find<DeviceInfoPlugin>(),
        Get.find<LocalFilePickerInteractor>(),
        Get.find<SaveEmailAsDraftsInteractor>(),
        Get.find<GetEmailContentInteractor>(),
        Get.find<UpdateEmailDraftsInteractor>(),
        Get.find<GetAllIdentitiesInteractor>(),
        Get.find<UploadController>(),
        Get.find<RemoveComposerCacheOnWebInteractor>(),
        Get.find<SaveComposerCacheOnWebInteractor>(),
        Get.find<RichTextWebController>(),
        Get.find<DownloadImageAsBase64Interactor>(),
    ));
  }

  void dispose() {
    Get.delete<UploadController>();
    Get.delete<RichTextWebController>();
    Get.delete<RichTextMobileTabletController>();
    Get.delete<ComposerController>();
  }
}