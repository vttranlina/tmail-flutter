import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:tmail_ui_user/features/base/base_controller.dart';
import 'package:tmail_ui_user/main/localizations/app_localizations.dart';
import 'package:tmail_ui_user/main/routes/route_navigation.dart';

class NetworkConnectionController extends BaseController {
  final connectivityResult = Rxn<ConnectivityResult>();
  final _imagePaths = Get.find<ImagePaths>();
  final Connectivity _connectivity;
  final AppToast _appToast = Get.find<AppToast>();

  bool _isEnableShowToastDisconnection = true;

  late StreamSubscription<ConnectivityResult> subscription;

  NetworkConnectionController(this._connectivity);

  @override
  void onInit() {
    super.onInit();
    log('NetworkConnectionController::onInit():');
    _listenNetworkConnectionChanged();
  }

  @override
  void onReady() {
    super.onReady();
    log('NetworkConnectionController::onReady():');
    _getCurrentNetworkConnectionState();
  }

  @override
  void onClose() {
    subscription.cancel();
    super.onClose();
  }

  void _getCurrentNetworkConnectionState() async {
    final currentConnectionResult = await _connectivity.checkConnectivity();
    log('NetworkConnectionController::onReady():_getCurrentNetworkConnectionState: $currentConnectionResult');
    _setNetworkConnectivityState(currentConnectionResult);
    if (_isEnableShowToastDisconnection && !isNetworkConnectionAvailable()) {
      _showToastLostConnection();
    } else {
      ToastView.dismiss();
    }
  }

  void _listenNetworkConnectionChanged() {
    subscription = _connectivity.onConnectivityChanged.listen(
      (result) {
        log('NetworkConnectionController::_listenNetworkConnectionChanged():onConnectivityChanged: $result');
        _setNetworkConnectivityState(result);
        if (_isEnableShowToastDisconnection && !isNetworkConnectionAvailable()) {
          _showToastLostConnection();
        } else if (isNetworkConnectionAvailable()) {
          _showToastConnectedToTheNetwork();
        } else {
          ToastView.dismiss();
        }
      },
      onError: (error, stackTrace) {
        logError('NetworkConnectionController::_listenNetworkConnectionChanged():error: $error');
        logError('NetworkConnectionController::_listenNetworkConnectionChanged():stackTrace: $stackTrace');
      }
    );
  }

  void _setNetworkConnectivityState(ConnectivityResult newConnectivityResult) {
    connectivityResult.value = newConnectivityResult;
  }

  bool isNetworkConnectionAvailable() {
    return connectivityResult.value != ConnectivityResult.none;
  }

  void _showToastLostConnection() {
    if (currentContext != null && currentOverlayContext != null) {
      _appToast.showToastMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).no_internet_connection,
        actionName: AppLocalizations.of(currentContext!).skip,
        onActionClick: () {
          _isEnableShowToastDisconnection = false;
          ToastView.dismiss();
        },
        leadingSVGIcon: _imagePaths.icNotConnection,
        backgroundColor: AppColor.textFieldErrorBorderColor,
        textColor: Colors.white,
        infinityToast: true,
      );
    }
  }

  void _showToastConnectedToTheNetwork() {
    if (currentContext != null && currentOverlayContext != null) {
      _appToast.showToastMessage(
        currentOverlayContext!,
        AppLocalizations.of(currentContext!).connectedToTheInternet,
        leadingSVGIcon: _imagePaths.icConnectedInternet,
        backgroundColor: AppColor.primaryColor,
        textColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        duration: const Duration(seconds: 5)
      );
    }
  }
}