import 'package:core/presentation/extensions/color_extension.dart';
import 'package:core/presentation/resources/image_paths.dart';
import 'package:core/presentation/state/success.dart';
import 'package:core/presentation/utils/responsive_utils.dart';
import 'package:core/presentation/utils/style_utils.dart';
import 'package:core/presentation/views/button/icon_button_web.dart';
import 'package:core/presentation/views/list/tree_view.dart';
import 'package:core/presentation/views/search/search_bar_view.dart';
import 'package:core/presentation/views/text/text_field_builder.dart';
import 'package:core/utils/build_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:jmap_dart_client/jmap/mail/mailbox/mailbox.dart';
import 'package:model/extensions/presentation_mailbox_extension.dart';
import 'package:model/mailbox/expand_mode.dart';
import 'package:model/mailbox/presentation_mailbox.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:tmail_ui_user/features/base/mixin/app_loader_mixin.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/destination_picker_controller.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_picker_arguments.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/model/destination_screen_type.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/widgets/destination_picker_search_mailbox_item_builder.dart';
import 'package:tmail_ui_user/features/destination_picker/presentation/widgets/top_bar_destination_picker_builder.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/mixin/mailbox_widget_mixin.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_actions.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_categories.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_displayed.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/model/mailbox_node.dart';
import 'package:tmail_ui_user/features/mailbox/presentation/widgets/mailbox_folder_tile_builder.dart';
import 'package:tmail_ui_user/features/mailbox_creator/presentation/widgets/create_mailbox_name_input_decoration_builder.dart';
import 'package:tmail_ui_user/features/thread/presentation/widgets/search_app_bar_widget.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/utils/app_utils.dart';

class DestinationPickerView extends GetWidget<DestinationPickerController>
  with AppLoaderMixin,
    MailboxWidgetMixin {

  final _maxHeight = 656.0;
  final _imagePaths = Get.find<ImagePaths>();
  final _responsiveUtils = Get.find<ResponsiveUtils>();

  @override
  final controller = Get.find<DestinationPickerController>();

  DestinationPickerView({Key? key}) : super(key: key) {
    controller.arguments = Get.arguments;
  }

  DestinationPickerView.fromArguments(
      DestinationPickerArguments arguments, {
      Key? key,
      OnSelectedMailboxCallback? onSelectedMailboxCallback,
      VoidCallback? onDismissCallback
  }) : super(key: key) {
    controller.arguments = arguments;
    controller.onSelectedMailboxCallback = onSelectedMailboxCallback;
    controller.onDismissDestinationPicker = onDismissCallback;
  }

  @override
  Widget build(BuildContext context) {
    MailboxActions? actions = controller.arguments?.mailboxAction;
    MailboxId? mailboxIdSelected = controller.arguments?.mailboxIdSelected;

    return PointerInterceptor(
      child: GestureDetector(
        onTap: () => controller.closeDestinationPicker(context),
        child: Card(
          margin: EdgeInsets.zero,
          borderOnForeground: false,
          color: Colors.transparent,
          child: SafeArea(
            top: !BuildUtils.isWeb && _responsiveUtils.isPortraitMobile(context),
            bottom: false,
            left: false,
            right: false,
            child: Center(
                child: Container(
                    margin: _getMarginDestinationPicker(context),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: _getRadiusDestinationPicker(context),
                        boxShadow: const [
                          BoxShadow(
                              color: AppColor.colorShadowLayerBottom,
                              blurRadius: 96,
                              spreadRadius: 96,
                              offset: Offset.zero),
                          BoxShadow(
                              color: AppColor.colorShadowLayerTop,
                              blurRadius: 2,
                              spreadRadius: 2,
                              offset: Offset.zero),
                        ]),
                    width: _getWidthDestinationPicker(context),
                    height: _getHeightDestinationPicker(context),
                    child: ClipRRect(
                        borderRadius: _getRadiusDestinationPicker(context),
                        child: GestureDetector(
                            onTap: () => {},
                            child: SafeArea(
                              top: false,
                              bottom: false,
                              left: !BuildUtils.isWeb && _responsiveUtils.isLandscapeMobile(context),
                              right: !BuildUtils.isWeb && _responsiveUtils.isLandscapeMobile(context),
                              child: Column(children: [
                                Obx(() => TopBarDestinationPickerBuilder(
                                  controller.mailboxAction.value,
                                  controller.destinationScreenType.value,
                                  mailboxIdDestination: controller.mailboxDestination.value?.id,
                                  isCreateMailboxValidated: controller.isCreateMailboxValidated(context),
                                  onCloseAction: () =>
                                    controller.closeDestinationPicker(context),
                                  onBackToAction: () =>
                                    controller.backToDestinationScreen(context),
                                  onSelectedMailboxDestinationAction: () =>
                                    controller.dispatchSelectMailboxDestination(context),
                                  onCreateNewMailboxAction: () =>
                                    controller.createNewMailboxAction(context),
                                  onOpenCreateNewMailboxScreenAction: () =>
                                    controller.openCreateNewMailboxView(context))),
                                const Divider(
                                  color: AppColor.colorDividerDestinationPicker,
                                  height: 1),
                                Obx(() {
                                  if (controller.destinationScreenType.value == DestinationScreenType.destinationPicker) {
                                    return controller.isSearchActive()
                                      ? _buildInputSearchFormWidget(context)
                                      : const SizedBox.shrink();
                                  } else {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildCreateMailboxNameInput(context),
                                        Padding(
                                          padding: const EdgeInsets.only(left: 24, right: 24, bottom: 12),
                                          child: Text(
                                            AppLocalizations.of(context).selectParentFolder,
                                            textAlign: TextAlign.left,
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: AppColor.colorHintSearchBar,
                                              fontWeight: FontWeight.normal)),
                                        )
                                    ]);
                                  }
                                }),
                                Expanded(child: Container(
                                    color: Colors.white,
                                    child: RefreshIndicator(
                                        color: AppColor.primaryColor,
                                        onRefresh: () async => controller.getAllMailboxAction(),
                                        child: Obx(() => controller.isSearchActive()
                                            ? _buildListMailboxSearched(context, actions, mailboxIdSelected)
                                            : _buildListMailbox(context, actions, mailboxIdSelected)))
                                ))
                              ]),
                            ))
                    )
                )
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateMailboxNameInput(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Obx(() => (TextFieldBuilder()
        ..key(const Key('create_mailbox_name_input'))
        ..onChange((value) => controller.setNewNameMailbox(value))
        ..keyboardType(TextInputType.visiblePassword)
        ..cursorColor(AppColor.colorTextButton)
        ..addController(controller.nameInputController)
        ..maxLines(1)
        ..textStyle(const TextStyle(
            color: AppColor.colorNameEmail,
            fontSize: 16,
            overflow: CommonTextStyle.defaultTextOverFlow))
        ..addFocusNode(controller.nameInputFocusNode)
        ..textDecoration((CreateMailboxNameInputDecorationBuilder()
            ..setHintText(AppLocalizations.of(context).hint_input_create_new_mailbox)
            ..setErrorText(controller.getErrorInputNameString(context)))
          .build()))
      .build())
    );
  }

  Widget _buildLoadingView() {
    return Obx(() => controller.viewState.value.fold(
      (failure) => const SizedBox.shrink(),
      (success) => success is LoadingState
        ? Padding(
            padding: const EdgeInsets.only(top: 16),
            child: loadingWidget)
        : const SizedBox.shrink()));
  }

  Widget _buildListMailbox(
      BuildContext context,
      MailboxActions? actions,
      MailboxId? mailboxIdSelected
  ) {
    return SingleChildScrollView(
        physics: const ClampingScrollPhysics(),
        controller: controller.destinationListScrollController,
        child: Column(children: [
          if (actions?.canSearch() == true &&
            controller.destinationScreenType.value == DestinationScreenType.destinationPicker)
              SearchBarView(
                _imagePaths,
                margin: const EdgeInsets.all(16),
                hintTextSearch: AppLocalizations.of(context).hint_search_mailboxes,
                onOpenSearchViewAction: controller.enableSearch
              ),
          _buildLoadingView(),
          if (actions?.hasAllMailboxDefault() == true)
            _buildAllMailboxes(context, actions, mailboxIdSelected),
          Obx(() => controller.defaultMailboxIsNotEmpty
            ? _buildMailboxCategory(
                context,
                MailboxCategories.exchange,
                controller.defaultRootNode,
                actions,
                mailboxIdSelected)
            : const SizedBox.shrink()),
          Obx(() {
            if (controller.personalMailboxIsNotEmpty) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(
                    color: AppColor.colorDividerMailbox,
                    height: 0.5,
                    thickness: 0.2
                  ),
                  const SizedBox(height: 8),
                  _buildMailboxCategory(
                    context,
                    MailboxCategories.personalMailboxes,
                    controller.personalRootNode,
                    actions,
                    mailboxIdSelected
                  )
                ]
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
          Obx(() {
            if (controller.teamMailboxesIsNotEmpty
                && controller.mailboxAction.value == MailboxActions.moveEmail) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Divider(
                    color: AppColor.colorDividerMailbox,
                    height: 0.5,
                    thickness: 0.2
                  ),
                  const SizedBox(height: 8),
                  _buildMailboxCategory(
                    context,
                    MailboxCategories.teamMailboxes,
                    controller.teamMailboxesRootNode,
                    actions,
                    mailboxIdSelected
                  )
                ]
              );
            } else {
              return const SizedBox.shrink();
            }
          }),
          const SizedBox(height: 12)
        ])
    );
  }

  Widget _buildMailboxCategory(
      BuildContext context,
      MailboxCategories categories,
      MailboxNode mailboxNode,
      MailboxActions? actions,
      MailboxId? mailboxIdSelected
  ) {
    if (categories == MailboxCategories.exchange) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildBodyMailboxCategory(
          context,
          categories,
          mailboxNode,
          actions,
          mailboxIdSelected
        ),
      );
    } else {
      return Column(
        children: [
          buildHeaderMailboxCategory(
            context,
            _responsiveUtils,
            _imagePaths,
            categories,
            controller,
            toggleMailboxCategories: controller.toggleMailboxCategories,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)
          ),
          AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            child: categories.getExpandMode(controller.mailboxCategoriesExpandMode.value) == ExpandMode.EXPAND
              ? _buildBodyMailboxCategory(
                  context,
                  categories,
                  mailboxNode,
                  actions,
                  mailboxIdSelected
                )
              : const Offstage()
          ),
          const SizedBox(height: 8)
        ],
      );
    }
  }

  Widget _buildBodyMailboxCategory(
    BuildContext context,
    MailboxCategories categories,
    MailboxNode mailboxNode,
    MailboxActions? actions,
    MailboxId? mailboxIdSelected
  ) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TreeView(
        key: Key('${categories.keyValue}_mailbox_list'),
        children: _buildListChildTileWidget(
          context,
          mailboxNode,
          mailboxIdSelected,
          lastNode: mailboxNode.childrenItems?.last,
          actions: actions
        )
      )
    );
  }

  List<Widget> _buildListChildTileWidget(
      BuildContext context,
      MailboxNode parentNode,
      MailboxId? mailboxIdSelected,
      {
        MailboxNode? lastNode,
        MailboxActions? actions
      }
  ) {
    return parentNode.childrenItems
      ?.map((mailboxNode) {
        if (mailboxNode.hasChildren()) {
          return TreeViewChild(
            context,
            key: const Key('children_tree_mailbox_child'),
            isDirectionRTL: AppUtils.isDirectionRTL(context),
            isExpanded: mailboxNode.expandMode == ExpandMode.EXPAND,
            paddingChild: EdgeInsets.only(
              left: AppUtils.isDirectionRTL(context) ? 0 : 14,
              right: AppUtils.isDirectionRTL(context) ? 14 : 0,
            ),
            parent: (MailBoxFolderTileBuilder(
                    context,
                    _imagePaths,
                    mailboxNode,
                    lastNode: lastNode,
                    mailboxActions: actions,
                    mailboxIdAlreadySelected: mailboxIdSelected,
                    mailboxDisplayed: MailboxDisplayed.destinationPicker)
                ..addOnClickOpenMailboxNodeAction((node) => _pickMailboxNode(context, node))
                ..addOnClickExpandMailboxNodeAction((mailboxNode) =>
                  controller.toggleMailboxFolder(mailboxNode, controller.destinationListScrollController))
              ).build(),
            children: _buildListChildTileWidget(
                context,
                mailboxNode,
                mailboxIdSelected,
                actions: actions)
          ).build();
        } else {
          return (MailBoxFolderTileBuilder(
                context,
                _imagePaths,
                mailboxNode,
                lastNode: lastNode,
                mailboxDisplayed: MailboxDisplayed.destinationPicker,
                mailboxIdAlreadySelected: mailboxIdSelected,
                mailboxActions: actions)
            ..addOnClickOpenMailboxNodeAction((node) => _pickMailboxNode(context, node))
          ).build();
        }})
      .toList() ?? <Widget>[];
  }

  void _pickMailboxNode(BuildContext context, MailboxNode mailboxNode) {
    _handleOpenMailboxNodeClick(mailboxNode);
    controller.dispatchSelectMailboxDestination(context);
  }

  Widget _buildListMailboxSearched(
      BuildContext context,
      MailboxActions? actions,
      MailboxId? mailboxIdSelected
  ) {
    return Obx(() => ListView.builder(
        key: const Key('list_mailbox_searched'),
        itemCount: controller.listMailboxSearched.length,
        shrinkWrap: true,
        primary: false,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          return Obx(() => DestinationPickerSearchMailboxItemBuilder(
            _imagePaths,
            _responsiveUtils,
            controller.listMailboxSearched[index],
            mailboxActions: actions,
            mailboxIdAlreadySelected: mailboxIdSelected,
            onClickOpenMailboxAction: (mailbox) => _pickPresentationMailbox(context, mailbox),
          ));
        }
    ));
  }

  void _pickPresentationMailbox(BuildContext context, PresentationMailbox mailbox) {
    _handleOpenPresentationMailboxClick(context, mailbox);
    controller.dispatchSelectMailboxDestination(context);
  }

  Widget _buildAllMailboxes(
      BuildContext context,
      MailboxActions? actions,
      MailboxId? mailboxIdSelected
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.selectMailboxAction(PresentationMailbox.unifiedMailbox);
            controller.dispatchSelectMailboxDestination(context);
          },
          customBorder: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
          hoverColor: AppColor.colorMailboxHovered,
          child: Obx(() => Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
            color: controller.mailboxDestination.value == PresentationMailbox.unifiedMailbox
              ? AppColor.colorItemSelected
              : Colors.transparent,
            child: Row(children: [
              SvgPicture.asset(
                _imagePaths.icFolderMailbox,
                width: BuildUtils.isWeb ? 20 : 24,
                height: BuildUtils.isWeb ? 20 : 24,
                fit: BoxFit.fill
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(
                AppLocalizations.of(context).allMailboxes,
                maxLines: 1,
                softWrap: CommonTextStyle.defaultSoftWrap,
                overflow: CommonTextStyle.defaultTextOverFlow,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColor.colorNameEmail,
                  fontWeight: FontWeight.normal
                ),
              )),
              const SizedBox(width: 8),
              if (actions == MailboxActions.select && (mailboxIdSelected == null ||
                  mailboxIdSelected == PresentationMailbox.unifiedMailbox.id))
                Padding(
                  padding: EdgeInsets.only(
                    right: AppUtils.isDirectionRTL(context) ? 0 : 30.0,
                    left: AppUtils.isDirectionRTL(context) ? 30 : 0.0,
                  ),
                  child: SvgPicture.asset(
                    _imagePaths.icFilterSelected,
                    width: 20,
                    height: 20,
                    fit: BoxFit.fill
                  ),
                )
            ])
          )),
        ),
      ),
    );
  }

  void _handleOpenMailboxNodeClick(MailboxNode mailboxNode) {
    PresentationMailbox presentationMailbox;
    final path = controller.findNodePath(mailboxNode.item.id)
        ?? mailboxNode.item.name?.name;
    if (path != null) {
      presentationMailbox = mailboxNode.item
          .toPresentationMailboxWithMailboxPath(path);
    } else {
      presentationMailbox = mailboxNode.item;
    }
    controller.selectMailboxAction(presentationMailbox, mailboxNode: mailboxNode);
  }

  void _handleOpenPresentationMailboxClick(
      BuildContext context,
      PresentationMailbox presentationMailbox
  ) {
    PresentationMailbox newPresentationMailbox;
    if (presentationMailbox.id == PresentationMailbox.unifiedMailbox.id) {
      newPresentationMailbox = presentationMailbox
          .toPresentationMailboxWithMailboxPath(AppLocalizations.of(context).allMailboxes);
    } else {
      final path = controller.findNodePath(presentationMailbox.id)
          ?? presentationMailbox.name?.name;
      if (path != null) {
        newPresentationMailbox = presentationMailbox.toPresentationMailboxWithMailboxPath(path);
      } else {
        newPresentationMailbox = presentationMailbox;
      }
    }

    controller.selectMailboxAction(newPresentationMailbox);
  }

  Widget _buildInputSearchFormWidget(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
            children: [
              Padding(
                padding: EdgeInsets.only(
                  left: AppUtils.isDirectionRTL(context) ? 0 : 5,
                  right: AppUtils.isDirectionRTL(context) ? 5 : 0,
                ),
                child: buildIconWeb(
                  icon: SvgPicture.asset(
                    _imagePaths.icBack,
                    colorFilter: AppColor.colorTextButton.asFilter(),
                    fit: BoxFit.fill),
                  onTap: () => controller.disableSearch(context))),
              Expanded(child: (SearchAppBarWidget(
                      _imagePaths,
                      controller.searchQuery.value,
                      controller.searchFocus,
                      controller.searchInputController,
                      hasBackButton: false,
                      hasSearchButton: true)
                  ..addPadding(EdgeInsets.zero)
                  ..setMargin(EdgeInsets.only(
                      right: AppUtils.isDirectionRTL(context) ? 0 : 16,
                      left: AppUtils.isDirectionRTL(context) ? 16 : 0,
                  ))
                  ..addDecoration(BoxDecoration(borderRadius: BorderRadius.circular(12), color: AppColor.colorBgSearchBar))
                  ..addIconClearText(SvgPicture.asset(_imagePaths.icClearTextSearch, width: 18, height: 18, fit: BoxFit.fill))
                  ..setHintText(AppLocalizations.of(context).hint_search_mailboxes)
                  ..addOnClearTextSearchAction(() => controller.clearSearchText())
                  ..addOnTextChangeSearchAction((query) => controller.searchMailbox(query))
                  ..addOnSearchTextAction((query) => controller.searchMailbox(query)))
                .build())
            ]
        )
    );
  }

  BorderRadius _getRadiusDestinationPicker(BuildContext context) {
    if (!BuildUtils.isWeb && _responsiveUtils.isLandscapeMobile(context)) {
      return BorderRadius.zero;
    } else if (_responsiveUtils.isMobile(context)) {
      return const BorderRadius.only(
          topRight: Radius.circular(16),
          topLeft: Radius.circular(16));
    } else {
      return const BorderRadius.all(Radius.circular(16));
    }
  }

  double _getWidthDestinationPicker(BuildContext context) {
    if (BuildUtils.isWeb) {
      if (_responsiveUtils.isMobile(context)) {
        return double.infinity;
      } else {
        return 556;
      }
    } else {
      if (_responsiveUtils.isLandscapeMobile(context) ||
          _responsiveUtils.isPortraitMobile(context)) {
        return double.infinity;
      } else {
        return 556;
      }
    }
  }

  double _getHeightDestinationPicker(BuildContext context) {
    if (BuildUtils.isWeb) {
      if (_responsiveUtils.isMobile(context)) {
        return double.infinity;
      } else {
        if (_responsiveUtils.getSizeScreenHeight(context) > _maxHeight) {
          return _maxHeight;
        } else {
          return double.infinity;
        }
      }
    } else {
      if (_responsiveUtils.isLandscapeMobile(context) ||
          _responsiveUtils.isPortraitMobile(context)) {
        return double.infinity;
      } else {
        if (_responsiveUtils.getSizeScreenHeight(context) > _maxHeight) {
          return _maxHeight;
        } else {
          return double.infinity;
        }
      }
    }

  }

  EdgeInsets _getMarginDestinationPicker(BuildContext context) {
    if (BuildUtils.isWeb) {
      if (_responsiveUtils.isMobile(context)) {
        return EdgeInsets.zero;
      } else {
        if (_responsiveUtils.getSizeScreenHeight(context) > _maxHeight) {
          return const EdgeInsets.symmetric(vertical: 12);
        } else {
          return const EdgeInsets.symmetric(vertical: 50);
        }
      }
    } else {
      if (_responsiveUtils.isLandscapeMobile(context) ||
          _responsiveUtils.isPortraitMobile(context)) {
        return EdgeInsets.zero;
      } else {
        if (_responsiveUtils.getSizeScreenHeight(context) > _maxHeight) {
          return const EdgeInsets.symmetric(vertical: 12);
        } else {
          return const EdgeInsets.symmetric(vertical: 50);
        }
      }
    }
  }
}