// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert' as convert;
// import 'dart:io' show Platform;
// import 'package:flutter/material.dart';
// import 'package:no_queues_client/context.dart';
// import 'package:no_queues_client/local_notification_service.dart';
// import 'package:android_alarm_manager/android_alarm_manager.dart';
//
//
// class PushNotification {
//   static const String firebaseServerKey = 'AAAACKen0OE:APA91bFRtVLgOSvaJGwsGHRjEb9nYIIjm0VkdWO7Ft2Oie0swrSKNCuFWa2VAi_-NCHR23fBIIyoDUO8gq0RMC6tzXp2acVFkixywNE6epin_I0jH-DYjPRRV1e3F6CvZiAOOBZshISF';
//   static const String fcmSendApiUrl = 'https://fcm.googleapis.com/fcm/send';
//   final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
//
//
//   Future<void> initialize() async{
//     if (Platform.isIOS) {
//       _firebaseMessaging.requestPermission(sound: true, badge: true, alert: true, provisional: false);
//     }
//
//     // always add this line before calling the steams to avoid any errors.
//     // this callback is called when the app is in the terminated state
//     _firebaseMessaging.getInitialMessage().then((message){
//       if(message != null) {
//         print('-----you just received a message-------');
//         print('Notification title: ${message.notification.title}');
//         print('Notification body: ${message.notification.body}');
//       }
//     });
//
//
//     //display the current device token
//     print('about to print the notification token');
//     String token = await _firebaseMessaging.getToken();
//     print( token);
//
//
//     //listen to changes in the device's token
//     _firebaseMessaging.onTokenRefresh.listen((newToken) async{
//       try {
//         await FirebaseFirestore.instance.collection('client_details').doc('${FirebaseAuth.instance.currentUser.uid}').update({
//           'firebaseDeviceToken' : '$newToken'
//         });
//
//       } catch(e){
//         print(e);
//       }
//     });
//
//     //triggered when a message is received while the app is in the foreground
//     FirebaseMessaging.onMessage.listen((message) {
//       if(message != null) {
//         print('-----you just received a message-------');
//         print('Notification title: ${message.notification.title}');
//         print('Notification body: ${message.notification.body}');
//
//         LocalNotificationService.display(message.notification.body);
//
//       }
//     });
//
//     //called when the app is in the backgound and the user taps to open the app
//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       if(message != null){
//         //Navigator.push(context, MaterialPageRoute(builder: ));
//         final String dataItem = message.data['name'];
//         print('----------dataItem: $dataItem-------');
//         Navigator.of(myContext.getContext).pushNamed('/SearchScreen');
//       }
//     });
//
//   }
//
//
//   Future<bool> sendNotification(String receiverToken, String receiverName, String position, String queueName, String percentage) async {
//     var headers = {
//       'Content-Type': 'application/json',
//       'Authorization' : 'key=$firebaseServerKey'
//     };
//
//     http.Request request = http.Request(
//         'POST', Uri.parse('$fcmSendApiUrl'));
//     request.body = convert.json.encode({
//       "to": '$receiverToken',
//       "notification": {
//         "body" : "Dear ${receiverName}, \npercentage completion: $percentage % ",
//         "title": "queueName"
//       },
//     });
//
//     request.headers.addAll(headers);
//
//     try {
//       http.StreamedResponse  response = await request.send();
//       if(response.statusCode == 200){
//         var result = await response.stream.bytesToString();
//         print(result);
//         print('successfully sent notification');
//       }else {
//         print(response.statusCode);
//         print(response.reasonPhrase);
//         print('failed to send notification');
//         return false;
//       }
//     }catch(e) {
//       print(e.message);
//       print('failed to send notification');
//       return false;
//     }
//     print('the sendNotification session is over');
//     return true;
//
//   }
// }