import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:flutter/material.dart';


class PushNotificationService {
  String _tokenId;

  ///Get the device token id
  ///this is a unique identifier for your device
  Future<String> getTokenId() async {
    try {
      var status = await OneSignal.shared.getPermissionSubscriptionState();
      _tokenId = status.subscriptionStatus.userId;
    }catch(e) {
      debugPrint('Could not retrieve the one signal token id');
      debugPrint('$e');
    }
    return _tokenId ?? '';
  }


  void initialize() {
    OneSignal.shared.init('732561ee-1357-4eff-ae41-cad0a7bcbfa4');
  }

  String get tokenId {
    return _tokenId;
  }

  Future<void> sendNotification() async {

  }
}
