// import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_client/screens/signup_screen.dart';
import 'package:no_queues_client/data/settings_data.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/screens/selected_queues_screen.dart';
import 'package:no_queues_client/data/selected_queues.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:no_queues_client/screens/loading_page.dart';
import 'package:no_queues_client/screens/login_page.dart';
import 'package:no_queues_client/screens/select_search_method_screen.dart';
import 'package:no_queues_client/screens/manual_search_screen.dart';
import 'package:no_queues_client/screens/select_language_screen.dart';
import 'package:no_queues_client/l10n/l10n.dart';
// import 'package:no_queues_client/translation/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:no_queues_client/data/bigData.dart';
import 'package:no_queues_client/screens/saved_queues_screen.dart';
import 'package:no_queues_client/data/saved_queues.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:universal_io/io.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:no_queues_client/onesignal.dart';
import 'package:no_queues_client/screens/help_screen.dart';
///Declaration and initialization of the one signal callbacks
//Remove this method to stop OneSignal Debugging






//this allows us to receive messages when he app is in the bakcground
//this must be a top level function
//this is so as to allow it work on its own isolate.
Future<void> backgroundHandler(RemoteMessage message) async{
  print('-------backgroundHandlerCallback was called------');
  if(message != null) {
    if (message.data.isNotEmpty) print(message.data.toString());
    print(
        '-----message title: ${message.notification.title.toString()}-------');
    print('-----message body: ${message.notification.body.toString()}--------');
  }
}




class MyHttpOverrides extends HttpOverrides{
  @override
  HttpClient createHttpClient(SecurityContext context){
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port)=> true;
  }
}



const bool isProduction = bool.fromEnvironment('dart.vm.product');

void main() async{

  ///this block is to disable debugPrint logs
  if(isProduction) {
    debugPrint = (String message, {int wrapWidth}) {};
  }

  HttpOverrides.global = new MyHttpOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //LocalNotificationService.initialize();
  // this allows to execute code when a firebase notification is received while the app  is in the background
  // the background handler provided in this function should be a top level function
  //FirebaseMessaging.onBackgroundMessage(backgroundHandler);
  runApp(MyApp());
  //await AndroidAlarmManager.initialize();
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
///Onesignal variables
  String _debugLabelString = "";
  bool _enableConsentButton = false;
  bool _requireConsent = false;

  ///notification checker variables
  Future<String> permissionStatusFuture;
  var permGranted = "granted";
  var permDenied = "denied";
  var permUnknown = "unknown";
  var permProvisional = "provisional";

  /// When the application has a resumed status, check for the permission
  /// status
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        permissionStatusFuture = getCheckNotificationPermStatus();
      });
    }
  }

  /// Checks the notification permission status
  Future<String> getCheckNotificationPermStatus() {
    return NotificationPermissions.getNotificationPermissionStatus()
        .then((status) {
      switch (status) {
        case PermissionStatus.denied:
          return permDenied;
        case PermissionStatus.granted:
          return permGranted;
        case PermissionStatus.unknown:
          return permUnknown;
        case PermissionStatus.provisional:
          return permProvisional;
        default:
          return null;
      }
    });
  }


  @override
  void initState() {
    super.initState();
    print('-------MyApp initialised-------');
    FirebaseFirestore.instance.settings = Settings(persistenceEnabled: false);
    // set up the notification permissions class
    // set up the future to fetch the notification data
    Future(() async{
      permissionStatusFuture = getCheckNotificationPermStatus();
      if( await permissionStatusFuture == permUnknown || await permissionStatusFuture == permDenied) {
        /// If notification permission is unknown or Denied,
        /// request for notification permission
        // show the dialog/open settings screen
        await NotificationPermissions.requestNotificationPermissions(
            iosSettings: const NotificationSettingsIos(
                sound: true, badge: true, alert: true))
            .then((_) {
          // when finished, check the permission status
          setState(() {
            permissionStatusFuture =
                getCheckNotificationPermStatus();
          });
        });
      }
    });
    // With this, we will be able to check if the permission is granted or not
    // when returning to the application
    //WidgetsBinding.instance.addObserver(this);

    ///Initialize the one_signal pluggin
    Future(()async {
    PushNotificationService().initialize();

    ///get the current device token
    String tokenId = await PushNotificationService().getTokenId();
    print('Your device token Id is: $tokenId');
    ///might need to uncomment these lines of code later
      //await initPlatformState();
    });

    ///initilializing the one signal plugin

  }

  ///initialise onesignal
  Future<void> initPlatformState() async {
    if (!mounted) return;

    // NOTE: Replace with your own app ID from https://www.onesignal.com
    ///this line of code initilizes the onesignal pluggin
    await OneSignal.shared.init("732561ee-1357-4eff-ae41-cad0a7bcbfa4");

    OneSignal.shared.setLogLevel(OSLogLevel.verbose, OSLogLevel.none);

    OneSignal.shared.setRequiresUserPrivacyConsent(_requireConsent);

    OneSignal.shared
        .setNotificationOpenedHandler((OSNotificationOpenedResult result) {
      print('NOTIFICATION OPENED HANDLER CALLED WITH: ${result}');
      this.setState(() {
        _debugLabelString =
        "Opened notification: \n${result.notification.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared
        .setInAppMessageClickedHandler((OSInAppMessageAction action) {
      this.setState(() {
        _debugLabelString =
        "In App Message Clicked: \n${action.jsonRepresentation().replaceAll("\\n", "\n")}";
      });
    });

    OneSignal.shared
        .setSubscriptionObserver((OSSubscriptionStateChanges changes) {
      print("SUBSCRIPTION STATE CHANGED: ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setPermissionObserver((OSPermissionStateChanges changes) {
      print("PERMISSION STATE CHANGED: ${changes.jsonRepresentation()}");
    });

    OneSignal.shared.setEmailSubscriptionObserver(
            (OSEmailSubscriptionStateChanges changes) {
          print("EMAIL SUBSCRIPTION STATE CHANGED ${changes.jsonRepresentation()}");
        });



    bool requiresConsent = await OneSignal.shared.requiresUserPrivacyConsent();

    this.setState(() {
      _enableConsentButton = requiresConsent;
    });

  }

  @override
  void dispose() {
    super.dispose();
    print('-----MyApp was disposed------');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SelectedQueues>(
      create: (context) => SelectedQueues(),
      child: ChangeNotifierProvider<SavedQueues>(
        create: (context) => SavedQueues(),
            child: ChangeNotifierProvider<BigData>(
          create: (context) => BigData(),
          child: ChangeNotifierProvider<SettingsData>(
            create: (context) => SettingsData(),
            builder: (context, child) => MaterialApp(
              title: 'Digi-Q Client',
              theme: ThemeData(
                primaryColor: appColor,
                backgroundColor: appColor,
              ),
              locale: Locale(Provider.of<SettingsData>(context).getAppLang),
              supportedLocales: L10n.all,
              localizationsDelegates: [
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
              ],
              routes: {
                '/SignUpScreen' : (context) => SignUpScreen(),
                '/SelectedQueuesScreen' : (context) => SelectedQueuesScreen(),
                '/LoadingScreen' : (context) => LoadPage(),
                '/LogInScreen' : (context) => LogInScreen(),
                '/ManualSearchScreen': (context) => ManualSearchScreen(),
                '/SelectSearchMethodScreen' : (context) => SelectSearchMethodScreen(),
                '/SelectLangScreen' : (context) => SelectLangScr(),
                '/ModifiedSelectLangScreen' : (context) => ModSelectLangScr(),
                '/SavedQueuesScreen' : (context) => SavedQueuesScreen(),
                '/HelpScreen' : (context) => HelpScreen()
              },
              initialRoute: '/LoadingScreen', //_initialized ? LogInScreen() : LoadPage(),
            ),
          ),
        ),
      ),
    );
  }
}
