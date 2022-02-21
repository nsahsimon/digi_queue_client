import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/my_widgets/custom_text_field.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_client/screens/verification_screen.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:no_queues_client/background_services.dart';
import 'package:android_alarm_manager/android_alarm_manager.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SignUpScreen extends StatefulWidget {

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool isCodeSent = false;
  String phoneNum;
  TextEditingController phoneController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  String _verificationId;
  bool isLoading = false;
  bool isButtonActive = false;
  PhoneAuthCredential _phoneAuthCredential;
  FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    if(FirebaseAuth.instance.currentUser != null){
      print('-----already logged in as ${FirebaseAuth.instance.currentUser.phoneNumber}-----');
      Future((){
        Navigator.pushNamed(context, '/SelectedQueuesScreen');
      });
    }
  }

  //update the client details table if the user doesn't exist
  Future<void> addClientDetails() async{
    String token = await FirebaseMessaging.instance.getToken();
    FirebaseFirestore db = FirebaseFirestore.instance;
    FirebaseAuth _auth = FirebaseAuth.instance;
    bool _userExists = await userExists(_auth);
    if(!_userExists){
      print('-------user doesn\'t yet exist-------');
    try {
      await db.collection('client_details').doc('${_auth.currentUser.uid}').set({
        'phone': _auth.currentUser.phoneNumber,
        'name': nameController.text,
        'id': '${_auth.currentUser.uid}',
        'firebaseDeviceToken' : '$token'
      });

    } catch(e){
      print(e);
    }
    }else print('=------user already exists----------');
  }

    //check if account exist already and returns a boolean
  Future<bool> userExists(FirebaseAuth auth) async{
    try {
      var clientDetails = await FirebaseFirestore.instance.collection(
          'client_details').get();
      List docs = clientDetails.docs;
      for (var doc in docs) {
        if((doc['phone'] == auth.currentUser.phoneNumber) && (doc['id'] == auth.currentUser.uid)) return true;
      }
    }catch(e) {
      print('could not access the client_details database');
      Navigator.pushNamed(context, '/SignUpScreen');
    }
    return false;
  }



  @override
  Widget build(BuildContext context) {
    return  ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.1,
            ),
            Center(
              child: Text(
                'Sign In',
                style: TextStyle(
                  color: appColor,
                  fontSize: 40
                ),
              ),
            ),
            MyTextField(controller: phoneController, labelText: 'Phone Number', hintText: '+2376XXXXXXXX' ),
            MyTextField(controller: nameController, labelText: 'Username' , hintText: 'Enter your name'),

            FlatButton(
                color: appColor,
                onPressed: () async{
                  if(phoneController.text != null){
                    setState(() {isLoading = true;});

                    await _auth.verifyPhoneNumber(

                        phoneNumber: phoneController.text,
                        verificationCompleted: (phoneAuthCredential) async{
                          setState(() {isLoading = false;});
                          try{await signInWithCredentials(phoneAuthCredential);}catch(e) {print(e);}
                        },

                        verificationFailed: (firebaseAuthException) async{
                          print(firebaseAuthException.message);
                          setState(() {isLoading = false;});
                        },


                        codeSent: (verificationId , resendingToken) async{
                          setState(() {isLoading = false;});
                          this._verificationId = verificationId;
                          print('message sent');
                          var userCode = await Navigator.push(context, MaterialPageRoute(builder: (context) => VerificationScreen()));
                          _phoneAuthCredential = PhoneAuthProvider.credential(verificationId: _verificationId, smsCode: userCode);
                          await signInWithCredentials(_phoneAuthCredential);
                        },

                        codeAutoRetrievalTimeout: (verificationId) async {}

                        );}
                },
                child: Center(
                  child: Text('Send Verification Code',
                      style: TextStyle(
                        color: Colors.white,
                      )),
                ))
          ]
      ),
    )
      ),
    );
  }

  Future<void> signInWithCredentials(PhoneAuthCredential credential)async{
    setState(() {
      isLoading = true;
    });
    try {
      final authCredential = await _auth.signInWithCredential(credential);
      await addClientDetails();
      if(authCredential.user != null) {
        setState(() {
          isCodeSent = false;
        });
        //AndroidAlarmManager.periodic(Duration(seconds: 60), 1, fireAlarm, wakeup: true, rescheduleOnReboot: true);
        Navigator.pushNamed(context, '/SelectedQueuesScreen');
      }
    }catch(e) {
      print(e);
    }
    setState(() {
      isLoading = false;
    });

  }
}

