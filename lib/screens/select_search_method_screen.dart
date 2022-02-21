import 'package:flutter/material.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:no_queues_client/screens/queue_profile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:io';

// import 'package:no_queues_client/translation/app_localizations.dart';


class SelectSearchMethodScreen extends StatefulWidget {
  @override
  _SelectSearchMethodScreenState createState() => _SelectSearchMethodScreenState();
}

class _SelectSearchMethodScreenState extends State<SelectSearchMethodScreen> {
  bool isLoading = false;
  TextEditingController serviceCodeController = TextEditingController();
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore  db = FirebaseFirestore.instance;
  bool canGetQueue = false;

  Future<void> getQueue() async{
    try {
     var  doc =  await db.collection('manager_details').where('service_code', isEqualTo: '${serviceCodeController.text.trim()}').get();
     if(doc.docs.isEmpty) return;
     Queue newQueue = Queue(snapshot: doc.docs[0]);

     showModalBottomSheet(
         context: context,
         builder: (context) {
           return QProfile(newQueue);
         });
    }catch(e){
      print('--------couldn\'t retrieve manager details--------');
    }
}

  Future<bool> isThereConnection() async {
    try {
      final result = await InternetAddress.lookup('www.google.com');
      if(result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('------connected to the internet----');
        return true;
      }
      if (mounted) {
        final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
      return false;
    }on SocketException catch (e) {
      print('----you are not connected to the internet-----');
      if (mounted) {
        final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).noInternet), duration: Duration(seconds: 1));
        ScaffoldMessenger.of(context).showSnackBar(msg);
      }
      return false;
    }
  }



  void onServiceCodePressedCallback(BuildContext context) async{
      await showDialog(context: context,
          builder: (context){
            return AlertDialog(
                content: Container(
                    height: 100,
                    child: Column(
                        children:[
                          TextField(
                            controller: serviceCodeController ,
                            decoration: InputDecoration(
                                hintText: AppLocalizations.of(context).enterServiceCode,
                            ),
                          ),
                          FlatButton(
                            color: Colors.blue,
                            child: Text(
                                'ok'
                            ),
                            onPressed: () {
                              canGetQueue = true;
                              Navigator.pop(context);
                            },
                          )
                        ]
                    )
                )
            );
          });
      setState((){
        isLoading = true;
      });
      if(canGetQueue){
        await getQueue();
        serviceCodeController.text = '';
        canGetQueue = false;
      }

      setState((){
        isLoading = false;
      });

      print('------just popped the alertbox--------');
  }

  @override
  Widget build(BuildContext context) {
    var locale = AppLocalizations.of(context);
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(locale.findService,
          style: TextStyle(
            color: Colors.white,
          ))
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              locale.selectSearchMethod,
              style: TextStyle(
                color: Colors.black,
                fontSize: 15,
              )
            ),
            SizedBox(
              height: 15,
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FlatButton(
                  onPressed: ()async {
                    isThereConnection();
                    onServiceCodePressedCallback(context);},
                  child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(
                              Radius.circular(20)
                          )
                      ),
                      height: 40,
                      child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60.0),
                            child: Center(
                              child: Text(
                                  locale.serviceCode,
                                  style: TextStyle(
                                    color: Colors.white,
                                  )
                              ),
                            ),
                          )
                      )
                  ),
                ),
                SizedBox(
                  height: 20,
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.pushNamed((context), '/ManualSearchScreen');
                  },
                  child: Container(
                      margin: EdgeInsets.symmetric(horizontal: 50),
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.all(
                              Radius.circular(20)
                          )
                      ),
                      height: 40,
                      child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 60.0),
                            child: Center(
                              child: Text(
                                  locale.manual,
                                  style: TextStyle(
                                    color: Colors.white,
                                  )
                              ),
                            ),
                          )
                      )
                  ),
                )
              ]
            )
          ]
        )
      ),
    );
  }
}
