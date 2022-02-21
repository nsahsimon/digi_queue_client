// import 'dart:async';
//
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:no_queues_client/local_notification_service.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
//
// Future<void> fireAlarm() async{
//
//   await Firebase.initializeApp();
//   print('-----Alarm fired------');
//   try {
//     DocumentSnapshot doc = await FirebaseFirestore.instance.collection('notifications').doc(FirebaseAuth.instance.currentUser.uid).get();
//     print('------notification from ${doc['from']}------');
//     if(doc['message'] != null) {
//       FlutterRingtonePlayer.play(
//         android: AndroidSounds.alarm,
//         ios: IosSounds.glass,
//         looping: false,
//         volume: 0.1,
//         asAlarm: false
//       );
//       //LocalNotificationService.display(doc['message']);
//       Future.delayed(Duration(seconds: 10), ()async{ await FlutterRingtonePlayer.stop(); } );
//     }
//   } catch (e) {
//     print('------something went wrong-------');
//     print('--------$e--------');
//   }
// }
//
//
// class Notifications {
//   static const expiryPeriod = Duration(minutes: 60);
//   StreamSubscription notificationSubscription;
//   Stream<DocumentSnapshot> notificationStream;
//   // ignore: cancel_subscriptions
//
//   bool notificationHasExpired(DateTime sentAt){
//     sentAt.add(expiryPeriod);
//     return true;
//   }
//
//
//
//
//
//   void initialize() async{
//     print('----stream opened------');
//     notificationStream = FirebaseFirestore.instance.collection('notifications').doc(FirebaseAuth.instance.currentUser.uid).snapshots();
//     notificationSubscription = notificationStream.listen((notification) {
//       if(notification != null){
//         print('------I just received a notification-------');
//         print('------from: ${notification['from']}-------');
//         print('-------time_stamp : ${notification['time_stamp']}-------');
//         print('-------date time: ${DateTime.now()}--------');
//         print('--------message: ${notification['message']}---------');
//
//         if (notification['time_stamp'] != null) {
//           DateTime sentAt = notification['time_stamp'].toDate();
//           DateTime now = DateTime.now();
//
//           //checking if message is expired
//           //if its
//           if(now.isBefore(sentAt.add(expiryPeriod))) {
//             if(notification['message'] != null){
//               FlutterRingtonePlayer.play(
//                   android: AndroidSounds.alarm,
//                   ios: IosSounds.glass,
//                   looping: false,
//                   volume: 0.1,
//                   asAlarm: false
//               );
//               LocalNotificationService.display(notification['message']);
//               Future.delayed(Duration(seconds: 10), ()async{ await FlutterRingtonePlayer.stop(); } );
//             }
//           }else print('-------Notification has expired----------');
//         }
//
//       }
//     });
//     //just for a demo
//     await FirebaseFirestore.instance.collection('notifications').doc(FirebaseAuth.instance.currentUser.uid).set({
//       'from' : 'simon',
//       'time_stamp' : FieldValue.serverTimestamp(),
//       'message': 'hello world from ${FirebaseAuth.instance.currentUser.phoneNumber}'
//     });
//   }
//
//   Future<void> stop() async{
//     await notificationSubscription.cancel();
//     print('----stream closed------');
//   }
//
// }
//
// Notifications notifications = Notifications();
//
