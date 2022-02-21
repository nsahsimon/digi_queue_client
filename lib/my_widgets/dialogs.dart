import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Dialogs {
  BuildContext context;
  TextInputType keyboardType;
  FirebaseAuth _auth = FirebaseAuth.instance;
  FirebaseFirestore _db = FirebaseFirestore.instance;


  Dialogs({this.context, this.keyboardType = TextInputType.text});

  TextEditingController textController = TextEditingController(text: '');


  ///This method displays a widget through which the user can enter a some text
  // Future<dynamic> inputDialog(
  //     {String title = '', String hintText = '', bool obscureText = false}) async {
  //   await showDialog(
  //       context: context,
  //       builder: (context) {
  //         return AlertDialog(
  //             title: Center(
  //                 child: Text(
  //                   '$title',
  //                 )
  //             ),
  //             content: SingleChildScrollView(
  //               child: Container(
  //                 height: 150,
  //                 padding: const EdgeInsets.symmetric(horizontal: 15),
  //                 child: Column(
  //                   mainAxisAlignment: MainAxisAlignment.center,
  //                   children: [
  //                     TextField(
  //                       decoration: InputDecoration(
  //                         hintText: hintText,
  //                       ),
  //                       keyboardType: keyboardType,
  //                       controller: textController,
  //                       obscureText: obscureText,
  //                     ),
  //                     SizedBox(
  //                       height: 15,
  //                     ),
  //                     RoundedButton(name: 'Set',
  //                         context: context,
  //                         onTap: () => Navigator.pop(context))
  //                   ],
  //                 ),
  //               ),
  //             )
  //         );
  //       }
  //   );
  //   return (textController.text != '') ? textController.text.trim() : null;
  // }

  ///Dialog to confirm an operation or a task
  Future<bool> confirmationDialog({String text, Color textColor = Colors.black, String actionText1 = 'Yes', String actionText2 = 'No', }) async{
    bool result =  await showDialog(
        context: context,
        builder: (context)
        {
          return AlertDialog(
              content: Container(
                height: 100,
                child: Center(
                  child: Text(
                    '$text',
                    style: TextStyle(
                      //fontSize: 25,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                    child: Text(actionText1),
                    onPressed: (){
                      Navigator.pop(context, true);
                    }
                ),

                TextButton(
                    child: Text(actionText2),
                    onPressed: (){
                      Navigator.pop(context, false);
                    }
                )
              ]
          );
        });

    return result;
  }


  Future<void> failureDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: SingleChildScrollView(
                child: Container(
                    height: 100,
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Center(child: Text('X',
                        style: TextStyle(
                            color: Colors.red,
                            fontSize: 70
                        )))
                ),
              )
          );
        }
    );
  }

  Future<void> successDialog() async {
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: SingleChildScrollView(
                child: Container(
                  height: 100,
                  width: 100,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: const Center(
                      child: Icon(Icons.check, size: 70, color: Colors.green)),
                ),
              )
          );
        }
    );
  }

  ///checks if the user is connected to a mobile network which has access to the internet
  Future<bool> checkConnectionDialog() async {
    Future<bool> isThereConnection() async {
      try {
        final result = await InternetAddress.lookup('www.google.com');
        if(result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('------connected to the internet----');
          return true;
        }
        final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);

        return false;
      }on SocketException catch (e) {
        print('----you are not connected to the internet-----');
        final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
        return false;
      }
    }
    bool result = await isThereConnection();

  if(result) {
    return true;
  }else {
    await showDialog(
      context: context,
      builder: (context) {
      return AlertDialog(
      content: SingleChildScrollView(
      child: Container(
  height: 110,
  width: 100,
  padding: const EdgeInsets.symmetric(horizontal: 15),
  child: Column(
    children: [
      Center(child: Text('!',
      style: TextStyle(
      color: Colors.orange,
      fontSize: 70
      ))),
      Center(
          child: Text('No internet Connection',
      textAlign: TextAlign.center))
    ],
  )
  ),
  )
  );
      }
      );

  return false;
  }

  }

  ///Poor internet connection dialog
  Future<void> poorInternetConnectionDialog() async{
  await showDialog(
      context: context,
      builder: (context) {
    return AlertDialog(
        content: SingleChildScrollView(
          child: Container(
              height: 120,
              width: 100,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                children: [
                  Center(child: Text('!',
                      style: TextStyle(
                          color: Colors.orange,
                          fontSize: 70
                      ))),
                  Center(child: Text('Poor internet Connection',
                  textAlign: TextAlign.center,)) //TODO: TRANSLATE
                ],
              )
          ),
        )
    );
  }
  );
}

  ///Connection timeout  dialog
  Future<void> timeoutDialog() async{
    await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
              content: SingleChildScrollView(
                child: Container(
                    height: 120,
                    width: 100,
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    child: Column(
                      children: [
                        Center(child: Text('!',
                            style: TextStyle(
                                color: Colors.orange,
                                fontSize: 70
                            ))),
                        Center(child: Text('TIMEOUT')),
                        Center(child: Text('Pls check your internet connection')) //TODO: TRANSLATE
                      ],
                    )
                ),
              )
          );
        }
    );
  }

  ///Check app updates dialog
  ///Returns true if the app is up to date and false if the app is not updated or was unable to retrieve the latest application version from firebase
  Future<bool> appIsUpToDateDialog() async {
    String _updateLink = "";
    Future<bool> isThereConnection() async {
      try {
        final result = await InternetAddress.lookup('www.google.com');
        if(result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          print('------connected to the internet----');
          return true;
        }
        final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);

        return false;
      }on SocketException catch (e) {
        print('----you are not connected to the internet-----');
        final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
        return false;
      }
    }

    /// check if a user exists
    /// the essence of this block of code is toe allow us to check for app updates even if user hasn't yet signed In
    bool wasAlreadySignedIn = true;
    if(_auth.currentUser == null) {
      try {
        await _auth.signInAnonymously();
        wasAlreadySignedIn = false;
      } catch (e) {
        return false;
      }
    }

    ///compares the in-App version with the latest app version from  the database
    Future<bool> compareAppVersions() async {
      bool result = false;
      DocumentReference appInfoRef = _db.collection('global_info').doc('client_app_info');
      DocumentSnapshot appInfoDoc;
      String _appVersion;
      try {
        appInfoDoc = await appInfoRef.get();
        _appVersion = appInfoDoc['client_app_version'];
        _updateLink = appInfoDoc['update_link'];
      }catch(e) {
        debugPrint('$e');
        debugPrint('Could\'nt retrieve the app version from firebase');
        ///return a null if unable to retrieve the app version from firebase
        return null;
      }

      ///compare the two app versions
      if(clientAppVersion == _appVersion) {
        ///if the two app versions are identical return true
        return true;
      }

      ///Checking if the retrieved appVersion if null
      else if(_appVersion == null) {
        ///return a null if the _appVersion retrieved is false;
        return null;
      }

      ///return a false if the appVersion gotten from firebase isn't equal to the saved appVersion
      else return false;
    }

    ///if the appVersions match, exit
    if(await compareAppVersions() == true) {
      if(wasAlreadySignedIn == false ){
        await _auth.signOut();
      }
      return true;}

    ///if the appVersions don't match and the result of the comparison is false,
    ///show the alert dialog
    else if(await compareAppVersions() == false){

      if(wasAlreadySignedIn == false ){
        await _auth.signOut();
      }

      await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
                content: SingleChildScrollView(
                  child: Container(
                      height: 150,
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Column(
                        children: [
                          Center(child: Text('!',
                              style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 70
                              ))),
                          Center(child: Text('An update is required', textAlign: TextAlign.center, //todo: translate
                              )),
                          Center(child: TextButton(
                            onPressed: () async{
                              if(await canLaunch('$_updateLink')) {
                                await launch('$_updateLink');
                              }
                            },
                              child: Text('update the app here', textAlign: TextAlign.center, //todo: translate
                              style: TextStyle(
                                color: Colors.blue,
                                  decoration: TextDecoration.underline,
                              )),
                          )),

                        ],
                      )
                  ),
                )
            );
          }
      );

      return false;
    }

    ///return false if the result of the comparison is null
    else return false;
  }

}