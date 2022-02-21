import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:no_queues_client/data/settings_data.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_client/constants.dart';

class LoadPage extends StatefulWidget {
  @override
  _LoadPageState createState() => _LoadPageState();
}



class _LoadPageState extends State<LoadPage> {

  bool gotoSelectLangScr = false;
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), (){initialize();});

  }
  void initialize() {

    Future(() async{
      await loadLang();
      if (!gotoSelectLangScr) {
        if (auth.currentUser != null) {
          Navigator.pushNamed(context, '/SelectedQueuesScreen');
        } else {
          Navigator.pushNamed(context, '/LogInScreen');
        }
      } else{
        Navigator.pushNamed(context, '/SelectLangScreen');
      }
    });

  }

  Future<void> loadLang() async{
    SharedPreferences _preferences = await SharedPreferences.getInstance();
    try {
      String lang = _preferences.getString('lang') ?? 'no_lang_on_disk';
      //TODO: add code here to load the language locale
      (lang == 'no_lang_on_disk') ?
      await Provider.of<SettingsData>(context,listen: false).setAppLangTo('en') :
      await Provider.of<SettingsData>(context,listen: false).setAppLangTo(lang);
      print('-------the selected language is: $lang-------');
      gotoSelectLangScr = (lang == 'no_lang_on_disk');
    }catch(e) {
      print(e);
      print('-----could not load languages--------');
      gotoSelectLangScr = false;
    }

    }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: SafeArea(
        child: Scaffold(
            backgroundColor: appColor,
            body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                      child: Column (
                          children: [
                            Image.asset('assets/client_app_logo.png',
                            height: 100,
                            width: 100)
                          ]
                      )
                  ),

                ]
            )
        ),
      ),
    );
  }
}

