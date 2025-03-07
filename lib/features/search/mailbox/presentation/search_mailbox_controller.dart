
import 'package:core/presentation/extensions/color_extension.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/state/failure.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/app_toast.dart';
import 'package:core/presentation/utils/keyboard_utils.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:core/utils/app_logger.dart';
import 'package:core/utils/build_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/account_id.dart';
import 'package:jmap_dart_client/jmap/core/session/session.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/email/presentation_email.dart';
import 'package:model/extensions/presentation_email_extension.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:tmail_ui_user/features/base/base_mailbox_controller.dart';
import 'package:debounce_throttle/debounce_throttle.dart';
import 'package:tmail_ui_user/features/base/mixin/mailbox_action_handler_mixin.dart';
import 'package:tmail_ui_user/features/email/domain/model/move_action.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_action_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/mailbox_subscribe_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/move_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/rename_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_multiple_mailbox_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/model/subscribe_request.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/delete_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/get_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/mark_as_mailbox_read_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/move_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/refresh_changes_all_mailboxes_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/rename_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/search_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/state/subscribe_multiple_mailbox_state.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/delete_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/get_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/move_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/refresh_all_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/rename_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/search_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/domain/usecases/subscribe_multiple_mailbox_interactor.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/action/mailbox_ui_action.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_tree_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/utils/mailbox_utils.dart';
import 'package:tmail_ui_user/features/mailbox_creator/domain/usecases/verify_name_interactor.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/controller/mailbox_dashboard_controller.dart';
import 'package:tmail_ui_user/features/mailbox_dashboard/presentation/model/dashboard_routes.dart';
import 'package:tmail_ui_user/features/search/mailbox/presentation/search_mailbox_bindings.dart';
import 'package:tmail_ui_user/features/thread/domain/model/search_query.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';
import 'package:jmap_dart_client/jmap/core/state.dart' as jmap;

class SearchMailboxController extends BaseMailboxController with MailboxActionHandlerMixin {

  final SearchMailboxInteractor _searchMailboxInteractor;
  final RenameMailboxInteractor _renameMailboxInteractor;
  final MoveMailboxInteractor _moveMailboxInteractor;
  final DeleteMultipleMailboxInteractor _deleteMultipleMailboxInteractor;
  final SubscribeMailboxInteractor _subscribeMailboxInteractor;
  final SubscribeMultipleMailboxInteractor _subscribeMultipleMailboxInteractor;

  final dashboardController = Get.find<MailboxDashBoardController>();
  final responsiveUtils = Get.find<ResponsiveUtils>();
  final imagePaths = Get.find<ImagePaths>();
  final _appToast = Get.find<AppToast>();

  final currentSearchQuery = RxString('');
  final listMailboxSearched = RxList<PresentationMailbox>();
  final textInputSearchController = TextEditingController();
  late Debouncer<String> _deBouncerTime;

  PresentationMailbox? get selectedMailbox => dashboardController.selectedMailbox.value;

  PresentationEmail? get selectedEmail => dashboardController.selectedEmail.value;

  SearchMailboxController(
    this._searchMailboxInteractor,
    this._renameMailboxInteractor,
    this._moveMailboxInteractor,
    this._deleteMultipleMailboxInteractor,
    this._subscribeMailboxInteractor,
    this._subscribeMultipleMailboxInteractor,
    TreeBuilder treeBuilder,
    VerifyNameInteractor verifyNameInteractor,
    GetAllMailboxInteractor getAllMailboxInteractor,
    RefreshAllMailboxInteractor refreshAllMailboxInteractor
  ) : super(
    treeBuilder,
    verifyNameInteractor,
    getAllMailboxInteractor: getAllMailboxInteractor,
    refreshAllMailboxInteractor: refreshAllMailboxInteractor
  );

  @override
  void onInit() {
    super.onInit();
    _initializeDebounceTimeTextSearchChange();
    _getAllMailboxAction();
  }

  @override
  void handleFailureViewState(Failure failure) {
    super.handleFailureViewState(failure);
    if (failure is SearchMailboxFailure) {
      _handleSearchMailboxFailure(failure);
    }
  }

  @override
  void handleSuccessViewState(Success success) async {
    super.handleSuccessViewState(success);
    if (success is GetAllMailboxSuccess) {
      currentMailboxState = success.currentMailboxState;
      buildTree(success.mailboxList);
    } else if (success is RefreshChangesAllMailboxSuccess) {
      currentMailboxState = success.currentMailboxState;
      await refreshTree(success.mailboxList);
      searchMailboxAction();
    } else if (success is SearchMailboxSuccess) {
      _handleSearchMailboxSuccess(success);
    } else if (success is MarkAsMailboxReadAllSuccess) {
      _refreshMailboxChanges(mailboxState: success.currentMailboxState);
    } else if (success is MarkAsMailboxReadHasSomeEmailFailure) {
      _refreshMailboxChanges(mailboxState: success.currentMailboxState);
    } else if (success is RenameMailboxSuccess) {
      _refreshMailboxChanges(mailboxState: success.currentMailboxState);
    } else if (success is MoveMailboxSuccess) {
      _moveMailboxSuccess(success);
    } else if (success is DeleteMultipleMailboxAllSuccess) {
      _deleteMultipleMailboxSuccess(success.listMailboxIdDeleted, success.currentMailboxState);
    } else if (success is DeleteMultipleMailboxHasSomeSuccess) {
      _deleteMultipleMailboxSuccess(success.listMailboxIdDeleted, success.currentMailboxState);
    } else if (success is SubscribeMailboxSuccess) {
      _handleSubscribeMailboxSuccess(success);
    } else if (success is SubscribeMultipleMailboxAllSuccess) {
      _handleSubscribeMultipleMailboxAllSuccess(success);
    } else if (success is SubscribeMultipleMailboxHasSomeSuccess) {
      _handleSubscribeMultipleMailboxHasSomeSuccess(success);
    }
  }

  void _initializeDebounceTimeTextSearchChange() {
    _deBouncerTime = Debouncer<String>(
      const Duration(milliseconds: 300),
      initialValue: ''
    );

    _deBouncerTime.values.listen((value) async {
      log('SearchMailboxController::_initializeDebounceTimeTextSearchChange():query: $value');
      currentSearchQuery.value = value;
      searchMailboxAction();
    });
  }

  void _getAllMailboxAction() {
    final session = dashboardController.sessionCurrent;
    final accountId = dashboardController.accountId.value;
    if (session != null && accountId != null) {
      getAllMailbox(session, accountId);
    }
  }

  void _refreshMailboxChanges({jmap.State? mailboxState}) {
    dashboardController.dispatchMailboxUIAction(RefreshChangeMailboxAction(null));
    final newMailboxState = mailboxState ?? currentMailboxState;
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;
    if (session != null && accountId != null && newMailboxState != null) {
      refreshMailboxChanges(session, accountId, newMailboxState);
    }
  }

  void searchMailboxAction() {
    if (currentSearchQuery.value.isNotEmpty) {
      consumeState(_searchMailboxInteractor.execute(
        allMailboxes,
        SearchQuery(currentSearchQuery.value)
      ));
    } else {
      listMailboxSearched.clear();
    }
  }

  void handleSearchButtonPressed(BuildContext context) {
    KeyboardUtils.hideKeyboard(context);
    searchMailboxAction();
  }

  void _handleSearchMailboxSuccess(SearchMailboxSuccess success) {
    final mailboxesSearchedWithPath = findMailboxPath(success.mailboxesSearched);
    listMailboxSearched.value = mailboxesSearchedWithPath;
  }

  void _handleSearchMailboxFailure(SearchMailboxFailure failure) {
    listMailboxSearched.clear();
  }

  void onTextSearchChange(String text) {
    _deBouncerTime.value = text;
  }

  void setTextInputSearchForm(String value) {
    textInputSearchController.text = value;
  }

  void submitSearchAction(BuildContext context, String query) {
    KeyboardUtils.hideKeyboard(context);
    currentSearchQuery.value = query;
    searchMailboxAction();
  }

  void handleMailboxAction(
    BuildContext context,
    MailboxActions actions,
    PresentationMailbox mailbox,
    {bool isFocusedMenu = false}
  ) {
    if (!isFocusedMenu) {
      popBack();
    }

    switch(actions) {
      case MailboxActions.openInNewTab:
        openMailboxInNewTabAction(mailbox);
        break;
      case MailboxActions.disableSpamReport:
      case MailboxActions.enableSpamReport:
        dashboardController.storeSpamReportStateAction();
        break;
      case MailboxActions.markAsRead:
        markAsReadMailboxAction(context, mailbox, dashboardController);
        break;
      case MailboxActions.rename:
        openDialogRenameMailboxAction(
          context,
          mailbox,
          responsiveUtils,
          onRenameMailboxAction: _renameMailboxAction
        );
        break;
      case MailboxActions.move:
        moveMailboxAction(
          context,
          mailbox,
          dashboardController,
          onMovingMailboxAction: _invokeMovingMailboxAction
        );
        break;
      case MailboxActions.delete:
        openConfirmationDialogDeleteMailboxAction(
          context,
          responsiveUtils,
          imagePaths,
          mailbox,
          onDeleteMailboxAction: _deleteMailboxAction
        );
        break;
      case MailboxActions.disableMailbox:
        _updateSubscribeStateOfMailboxAction(
          mailbox.id,
          MailboxSubscribeState.disabled,
          MailboxSubscribeAction.unSubscribe
        );
        break;
      case MailboxActions.enableMailbox:
        _updateSubscribeStateOfMailboxAction(
          mailbox.id,
          MailboxSubscribeState.enabled,
          MailboxSubscribeAction.subscribe
        );
        break;
      case MailboxActions.emptyTrash:
        emptyTrashAction(context, mailbox, dashboardController);
        break;
      default:
        break;
    }
  }

  void _renameMailboxAction(PresentationMailbox presentationMailbox, MailboxName newMailboxName) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;
    if (session != null && accountId != null) {
      consumeState(_renameMailboxInteractor.execute(
        session,
        accountId,
        RenameMailboxRequest(presentationMailbox.id, newMailboxName)
      ));
    }
  }

  void _invokeMovingMailboxAction(PresentationMailbox mailboxSelected, PresentationMailbox? destinationMailbox) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;
    if (session != null && accountId != null) {
      _handleMovingMailbox(
        session,
        accountId,
        MoveAction.moving,
        mailboxSelected,
        destinationMailbox: destinationMailbox
      );
    }
  }

  void _handleMovingMailbox(
    Session session,
    AccountId accountId,
    MoveAction moveAction,
    PresentationMailbox mailboxSelected,
    {PresentationMailbox? destinationMailbox}
  ) {
    consumeState(_moveMailboxInteractor.execute(
      session,
      accountId,
      MoveMailboxRequest(
        mailboxSelected.id,
        moveAction,
        destinationMailboxId: destinationMailbox?.id,
        destinationMailboxName: destinationMailbox?.name,
        parentId: mailboxSelected.parentId
      )
    ));
  }

  void _moveMailboxSuccess(MoveMailboxSuccess success) {
    if (success.moveAction == MoveAction.moving && currentOverlayContext != null && currentContext != null) {
      _appToast.showToastMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).moved_to_mailbox(success.destinationMailboxName?.name ?? AppLocalizations.of(currentContext!).allMailboxes),
        actionName: AppLocalizations.of(currentContext!).undo,
        onActionClick: () {
          _undoMovingMailbox(MoveMailboxRequest(
            success.mailboxIdSelected,
            MoveAction.undo,
            destinationMailboxId: success.parentId,
            parentId: success.destinationMailboxId)
          );
        },
        leadingSVGIconColor: Colors.white,
        leadingSVGIcon: imagePaths.icFolderMailbox,
        backgroundColor: AppColor.toastSuccessBackgroundColor,
        textColor: Colors.white,
        actionIcon: SvgPicture.asset(imagePaths.icUndo)
      );
    }

    _refreshMailboxChanges(mailboxState: success.currentMailboxState);
  }

  void _undoMovingMailbox(MoveMailboxRequest newMoveRequest) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;
    if (session != null && accountId != null) {
      consumeState(_moveMailboxInteractor.execute(session, accountId, newMoveRequest));
    }
  }

  void _deleteMailboxAction(PresentationMailbox presentationMailbox) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;

    if (session != null && accountId != null) {
      final tupleMap = MailboxUtils.generateMapDescendantIdsAndMailboxIdList(
        [presentationMailbox],
        defaultMailboxTree.value,
        personalMailboxTree.value
      );
      final mapDescendantIds = tupleMap.value1;
      final listMailboxId = tupleMap.value2;

      consumeState(_deleteMultipleMailboxInteractor.execute(
        session,
        accountId,
        mapDescendantIds,
        listMailboxId
      ));
    } else {
      _deleteMailboxFailure(DeleteMultipleMailboxFailure(null));
    }

    popBack();
  }

  void _deleteMultipleMailboxSuccess(List<MailboxId> listMailboxIdDeleted, jmap.State? currentMailboxState) {
    if (currentOverlayContext != null && currentContext != null) {
      _appToast.showToastSuccessMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).delete_mailboxes_successfully);
    }

    if (listMailboxIdDeleted.contains(dashboardController.selectedMailbox.value?.id)) {
      dashboardController.selectedMailbox.value = null;
      dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
    }

    _refreshMailboxChanges(mailboxState: currentMailboxState);
  }

  void _deleteMailboxFailure(DeleteMultipleMailboxFailure failure) {
    if (currentOverlayContext != null && currentContext != null) {
      _appToast.showToastErrorMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).delete_mailboxes_failure);
    }
  }

  void _updateSubscribeStateOfMailboxAction(
    MailboxId mailboxId,
    MailboxSubscribeState subscribeState,
    MailboxSubscribeAction subscribeAction
  ) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;

    if (session != null && accountId != null) {
      final subscribeRequest = generateSubscribeRequest(mailboxId, subscribeState, subscribeAction);

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor.execute(session, accountId, subscribeRequest));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor.execute(session, accountId, subscribeRequest));
      }
    }
  }

  void openMailboxAction(BuildContext context, PresentationMailbox mailbox) {
    KeyboardUtils.hideKeyboard(context);
    dashboardController.openMailboxAction(mailbox);

    if (!responsiveUtils.isWebDesktop(context)) {
      closeSearchView(context);
    }
  }

  void _handleSubscribeMailboxSuccess(SubscribeMailboxSuccess success) {
    if (success.subscribeAction != MailboxSubscribeAction.undo) {
      _showToastSubscribeMailboxSuccess(success.mailboxId, success.subscribeAction);

      if (success.mailboxId == selectedMailbox?.id) {
        dashboardController.selectedMailbox.value = null;
        dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
        _closeEmailViewIfMailboxDisabledOrNotExist([success.mailboxId]);
      }
    }

    _refreshMailboxChanges(mailboxState: success.currentMailboxState);
  }

  void _handleSubscribeMultipleMailboxAllSuccess(SubscribeMultipleMailboxAllSuccess success) {
    if(success.subscribeAction != MailboxSubscribeAction.undo) {
      _showToastSubscribeMailboxSuccess(
        success.parentMailboxId,
        success.subscribeAction,
        listDescendantMailboxIds: success.mailboxIdsSubscribe
      );

      if (success.mailboxIdsSubscribe.contains(selectedMailbox?.id)) {
        dashboardController.selectedMailbox.value = null;
        dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
        _closeEmailViewIfMailboxDisabledOrNotExist(success.mailboxIdsSubscribe);
      }
    }

    _refreshMailboxChanges(mailboxState: success.currentMailboxState);
  }

  void _handleSubscribeMultipleMailboxHasSomeSuccess(SubscribeMultipleMailboxHasSomeSuccess success) {
    if(success.subscribeAction != MailboxSubscribeAction.undo) {
      _showToastSubscribeMailboxSuccess(
        success.parentMailboxId,
        success.subscribeAction,
        listDescendantMailboxIds: success.mailboxIdsSubscribe
      );

      if (success.mailboxIdsSubscribe.contains(selectedMailbox?.id)) {
        dashboardController.selectedMailbox.value = null;
        dashboardController.dispatchMailboxUIAction(SelectMailboxDefaultAction());
        _closeEmailViewIfMailboxDisabledOrNotExist(success.mailboxIdsSubscribe);
      }
    }

    _refreshMailboxChanges(mailboxState: success.currentMailboxState);
  }

  void _showToastSubscribeMailboxSuccess(
      MailboxId mailboxIdSubscribed,
      MailboxSubscribeAction subscribeAction,
      {List<MailboxId>? listDescendantMailboxIds}
  ) {
    if (currentOverlayContext != null && currentContext != null) {
      _appToast.showToastMessage(
        currentOverlayContext!,
        subscribeAction.getToastMessageSuccess(currentContext!),
        actionName: AppLocalizations.of(currentContext!).undo,
        onActionClick: () {
          if (subscribeAction == MailboxSubscribeAction.unSubscribe) {
            _undoUnsubscribeMailboxAction(
              mailboxIdSubscribed,
              listDescendantMailboxIds: listDescendantMailboxIds
            );
          } else {
            _undoSubscribeMailboxAction(
              mailboxIdSubscribed,
              listDescendantMailboxIds: listDescendantMailboxIds
            );
          }
        },
        leadingSVGIconColor: Colors.white,
        leadingSVGIcon: imagePaths.icFolderMailbox,
        backgroundColor: AppColor.toastSuccessBackgroundColor,
        textColor: Colors.white,
        actionIcon: SvgPicture.asset(imagePaths.icUndo),
      );
    }
  }

  void _undoUnsubscribeMailboxAction(
    MailboxId mailboxIdSubscribed,
    {List<MailboxId>? listDescendantMailboxIds}
  ) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;
    if (session != null && accountId != null) {
      SubscribeRequest? subscribeRequest;

      if (listDescendantMailboxIds != null) {
        subscribeRequest = SubscribeMultipleMailboxRequest(
          mailboxIdSubscribed,
          listDescendantMailboxIds,
          MailboxSubscribeState.enabled,
          MailboxSubscribeAction.undo
        );
      } else {
        subscribeRequest = SubscribeMailboxRequest(
          mailboxIdSubscribed,
          MailboxSubscribeState.enabled,
          MailboxSubscribeAction.undo
        );
      }

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor.execute(session, accountId, subscribeRequest));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor.execute(session, accountId, subscribeRequest));
      }
    }
  }

  void _undoSubscribeMailboxAction(
    MailboxId mailboxIdSubscribed,
    {List<MailboxId>? listDescendantMailboxIds}
  ) {
    final accountId = dashboardController.accountId.value;
    final session = dashboardController.sessionCurrent;
    if (session != null && accountId != null) {
      SubscribeRequest? subscribeRequest;

      if (listDescendantMailboxIds != null) {
        subscribeRequest = SubscribeMultipleMailboxRequest(
          mailboxIdSubscribed,
          listDescendantMailboxIds,
          MailboxSubscribeState.disabled,
          MailboxSubscribeAction.undo
        );
      } else {
        subscribeRequest = SubscribeMailboxRequest(
          mailboxIdSubscribed,
          MailboxSubscribeState.disabled,
          MailboxSubscribeAction.undo
        );
      }

      if (subscribeRequest is SubscribeMultipleMailboxRequest) {
        consumeState(_subscribeMultipleMailboxInteractor.execute(session, accountId, subscribeRequest));
      } else if (subscribeRequest is SubscribeMailboxRequest) {
        consumeState(_subscribeMailboxInteractor.execute(session, accountId, subscribeRequest));
      }
    }
  }

  void _closeEmailViewIfMailboxDisabledOrNotExist(List<MailboxId> mailboxIdsDisabled) {
    if (selectedEmail == null) {
      return;
    }

    final mailboxContain = selectedEmail!.findMailboxContain(dashboardController.mapMailboxById);
    if (mailboxContain != null && mailboxIdsDisabled.contains(mailboxContain.id)) {
      dashboardController.clearSelectedEmail();
      dashboardController.dispatchRoute(DashboardRoutes.thread);
    }
  }

  void clearAllTextInputSearchForm() {
    textInputSearchController.clear();
    currentSearchQuery.value = '';
    searchMailboxAction();
  }

  void closeSearchView(BuildContext context) {
    KeyboardUtils.hideKeyboard(context);
    if (BuildUtils.isWeb) {
      dashboardController.searchMailboxActivated.value = false;
      clearAllTextInputSearchForm();
      SearchMailboxBindings().disposeBindings();
    } else {
      popBack();
    }
  }

  @override
  void onClose() {
    textInputSearchController.dispose();
    _deBouncerTime.cancel();
    super.onClose();
  }
}