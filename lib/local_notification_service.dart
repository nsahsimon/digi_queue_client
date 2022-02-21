// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:firebase_messaging/firebase_messaging.dart';
//
// class LocalNotificationService {
//   static final FlutterLocalNotificationsPlugin _notificationPlugin = FlutterLocalNotificationsPlugin();
// static void initialize(){
//   print('----initializing local notification service -----');
//   try{
//   final InitializationSettings initializationSettings = InitializationSettings(android: AndroidInitializationSettings("@mipmap/ic_launcher"));
//     _notificationPlugin.initialize(initializationSettings);
//   }catch(e){
//
//   }
//
// }
//
// static void display (String message) async{
//   try {
//     final randomNumber = DateTime.now().millisecondsSinceEpoch;
//     final id = (randomNumber / 1000).round();
//     final NotificationDetails notificationDetails = NotificationDetails(
//       android: AndroidNotificationDetails(
//         'noqueues',
//         "noqueues channel",
//         "my first channel",
//         importance: Importance.max,
//         priority: Priority.high,
//       )//AndroidNotificationDetails
//     ); // NotificationDetails
//     await _notificationPlugin.show(
//       id,
//       'Hello',
//       message,
//       notificationDetails
//     );
//   } catch (e) {
//     print('-----failed to display the hats up notification-----');
//     print(e);
//   }
// }
//
// }
