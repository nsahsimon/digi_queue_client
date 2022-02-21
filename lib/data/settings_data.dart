import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsData extends ChangeNotifier {
  bool _ring = true;
  int _notificationInterval = 5;
  String _userName;
  String _language = 'en';

  bool get getRingState {
    return _ring;
  }

  //set the value of the ring settings
  Future<bool> setRingTo(bool newValue) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      await prefs.setBool('ring',newValue);
      _ring = newValue;
      notifyListeners();
      return true;
    }catch(e){
      print('-----could not set the ring setting to the desired value-------');
      return false;
    }
  }

  Future<bool> setNotificationIntervalTo(int newNotificationInterval) async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      await prefs.setInt('notificationInterval',newNotificationInterval);
      this._notificationInterval = newNotificationInterval;
      notifyListeners();
      return true;
    } catch(e) {
      print('-----Could not set the notification interval-------');
      return false;
    }
  }

  Future<bool> setAppLangTo(String lang) async{  //make sure lang is the country code not the entire language name
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try{
      await prefs.setString('lang',lang);
      _language = lang;
      print('------Language set to : $lang-------');
      notifyListeners();
      return true;
    }catch(e){
      print('-----could not set the notification interval-------');
      return false;
    }
  }


  String get getAppLang {
    return _language;
  }

}