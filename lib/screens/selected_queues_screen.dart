import 'dart:io';
import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/data/selected_queues.dart';
import 'package:no_queues_client/my_widgets/selected_queue_tile.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_client/context.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/data/bigData.dart';
import 'package:no_queues_client/data/saved_queues.dart';
import 'package:no_queues_client/my_widgets/dialogs.dart';
class SelectedQueuesScreen extends StatefulWidget {

  @override
  _SelectedQueuesScreenState createState() => _SelectedQueuesScreenState();
}

class _SelectedQueuesScreenState extends State<SelectedQueuesScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool isLoading = false;
  bool isThereConnection = true;
  bool refreshButtonPressed = false;
  void startLoad() {
    setState(() {
      isLoading = true;
    });
  }

  void stopLoad() {
    setState((){
      isLoading = false;
    });
  }

  String initials(String text) {
    text = text.trim();
    List<String> words = text.split(' ');
    String initials = '';
    for(String word in words) {
      initials = initials + word.substring(0,1);
    }
    String allInitials = initials.toUpperCase(); //might need this in the future but all i need for the now is just the first initial
    String firstLetter = allInitials.substring(0,1);
    return firstLetter;
  }

  Widget profileImage() {
    return GestureDetector(
      onTap: () {
        showDialog(
            context: context,
            builder: (context) {
              return AlertDialog(
                  content: SingleChildScrollView(
                    child: Container(
                      child: Center(
                          child: Column(
                            children: [
                              CircleAvatar(
                                  backgroundColor: Colors.pink,
                                  radius: 20,
                                  child: Center(
                                      child: Text(initials(currentUsername(FirebaseAuth.instance.currentUser.email)),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 25,
                                          ))
                                  )
                              ),
                              SizedBox(
                                  height: 15,
                              ),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                    currentUsername(FirebaseAuth.instance.currentUser.email),
                                    style: TextStyle(
                                      color: Colors.black,
                                    )
                                ),
                              ),
                            ],
                          )
                      ),
                    ),
                  )
              );
            }
        );
      },
      child: Center(
          child: CircleAvatar(
              backgroundColor: Colors.pink,
              radius: 20,
              child: Center(
                  child: Text(initials(currentUsername(FirebaseAuth.instance.currentUser.email)),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                      ))
              )
          )
      ),
    );
  }

  String currentUsername(String username) {
    List<String> _usernameList = username.split('|');
    String _username = '';
    for(var name in _usernameList) {
      print('----name = ${name}----');
      if(!name.contains('@')){
        _username = _username + ' ' + name.toUpperCase();
      } //TODO:  '@' as a reserved character.
    }
    return _username.trim();
  }


  Future<void> saveQueue(queue) async{
    ///make sure there is an active internet connection
    if(await Dialogs(context: context).checkConnectionDialog() != true) return;

    ///make sure the app is up to date
    if(await Dialogs(context: context).appIsUpToDateDialog() != true) return;

    if (!Provider.of<SavedQueues>(context, listen: false).doesQueueExist(queue)) {
     try {
       await db.collection('client_details').doc(auth.currentUser.uid).set({
        'saved_queues' : FieldValue.arrayUnion([{
       'id' : queue.id,
       'name' : queue.name,
       }])},
    SetOptions(merge: true)
    );
       Provider.of<SavedQueues>(context, listen: false).add(queue);
       final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).saved));
       ScaffoldMessenger.of(context).showSnackBar(msg);
     }catch (e) {
       await Dialogs(context: context).poorInternetConnectionDialog();
     }
   }else {
     final SnackBar msg = SnackBar(content: Text(AppLocalizations.of(context).alreadySaved));
     ScaffoldMessenger.of(context).showSnackBar(msg);
   }
  }


  @override
  void initState() {
    // TODO: check on disk for queues to which the user was previously subscribed ,query the database. if the queues are still valid, update them,
    super.initState();
    // notifications.;initialize();
    Future(()async{
      startLoad();
      if(await Dialogs(context: context).checkConnectionDialog() != true) {
        refreshButtonPressed = false;
        stopLoad();
        return;}
      stopLoad();
      await loadSelectedQueuesfromCloud();
      await loadSavedQueuesfromCloud();
      refreshButtonPressed = false;
    });
    myContext.updateContext(context);
  }

  void logOut() async{
    Provider.of<BigData>(context, listen: false).empty();
    Provider.of<SavedQueues>(context, listen: false).empty();
    Provider.of<SelectedQueues>(context, listen: false).empty();
    await auth.signOut();
    //AndroidAlarmManager.cancel(1);
    // notifications.stop();
    //Navigator.popUntil(context, ModalRoute.withName('/LoadingScreen'));
    Navigator.pushReplacementNamed(context, '/LogInScreen');
  }

  Future<void> loadSelectedQueuesfromCloud() async{
    if(!isThereConnection) return;
    startLoad();
    try {
      var clientDoc = await db.collection('client_details').doc(auth.currentUser.uid).get();
      try {
        if (clientDoc.exists) {
          Provider.of<SelectedQueues>(context, listen: false).empty();
          List myQueues = clientDoc['my_queues'];
            for (Map queue in myQueues) {
              String id = queue['id'];
              String name  = queue['name'];
              debugPrint('name = $name');
              debugPrint(id);
              Queue newQueue = Queue();
              newQueue.setName(name);
              newQueue.setId(id);
              Provider.of<SelectedQueues>(context, listen: false).add(newQueue);
              debugPrint('-----${Provider.of<SelectedQueues>(context, listen: false).count} Queues loaded-----');
             // Provider.of<SelectedModifiedQueues>(context, listen: false).add(ModifiedQueue(dSnapshot: doc, generatedFromQueue: false));
            }
        }
      } catch (e) {
        debugPrint(e.toString());
      }
    }catch(e) {
      await Dialogs(context: context).poorInternetConnectionDialog();
      debugPrint('-----------Unable to load your subscriptions---------');
    }
    stopLoad();
  }


  Future<void> loadSavedQueuesfromCloud() async{
    if(!isThereConnection) return;
    startLoad();
    try {
      var savedQueueDoc = await db.collection('client_details').doc(auth.currentUser.uid).get();
      if (savedQueueDoc.exists) {
        try {
          List savedQueues = savedQueueDoc['saved_queues'];
          Provider.of<SavedQueues>(context, listen: false).empty();
          for (var savedQueue in savedQueues) {
            String id = savedQueue['id'];
            String name = savedQueue['name'];
            print('name = ${savedQueue['name']}');
            Queue newQueue = Queue();
            newQueue.setName(name);
            newQueue.setId(id);
            debugPrint(id);
            Provider.of<SavedQueues>(context, listen: false).add(newQueue);
            print('-----${Provider.of<SavedQueues>(context, listen: false).count} Queues loaded-----');
          }
        }catch (e) {
          debugPrint(e.toString());
        }
      }
    }catch(e) {
      await Dialogs(context: context).poorInternetConnectionDialog();
      debugPrint('-----------Unable to load your subscriptions---------');
    }
    stopLoad();
  }

  @override
  Widget build(BuildContext context) {
    print('----build method executed----');
    myContext.updateContext(context);
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
            appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Row(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        profileImage(),
                        SizedBox(
                          width: 10,
                        ),
                        Text( AppLocalizations.of(context).myQueues,
                            style: TextStyle(
                              color: Colors.white,
                            ) ),

                          ]
                        )
                      ],
                    ),
                actions: [
                  IconButton(
                    icon: Icon(Icons.refresh,
                    color: Colors.white, ),
                    onPressed: () async {
                      if(refreshButtonPressed) debugPrint('button already pressed');
                      if(refreshButtonPressed) return;
                      debugPrint('button no yet pressed');
                      refreshButtonPressed = true;
                      startLoad();
                      if(await Dialogs(context: context).checkConnectionDialog() != true) {
                        refreshButtonPressed = false;
                        stopLoad();
                        return;}
                      stopLoad();
                      await loadSelectedQueuesfromCloud();
                      refreshButtonPressed = false;
                    }
                  ),
                  PopupMenuButton(
                    icon: Icon(Icons.more_vert,
                    color: Colors.white),
                    initialValue: 1,
                    onSelected: (value) {

                    },
                    itemBuilder: (value) {
                      return [
                        PopupMenuItem(
                          value: 1,
                          child: ListTile(
                            leading: Icon(Icons.book,
                            color: appColor,),
                            title: Text(AppLocalizations.of(context).language,
                            style: TextStyle(
                              color: Colors.black,
                            )),
                            onTap: () {
                              Navigator.popAndPushNamed(context, '/ModifiedSelectLangScreen');
                            },),
                        ),
                        PopupMenuItem(
                          value: 2,
                          child: ListTile(
                            leading: Icon(Icons.favorite,
                            color: appColor),
                            title: Text( AppLocalizations.of(context).savedQueues,
                            style: TextStyle(
                              color: Colors.black,
                            )),
                            onTap: () {
                              Navigator.popAndPushNamed(context, '/SavedQueuesScreen');
                            },
                          ),
                        ),
                        PopupMenuItem(
                          value: 3, //todo: The value was originally 2 so I changed it 3. You can change this back if it raises any issues
                          child: ListTile(
                            leading: Icon(Icons.logout,
                      color: appColor),
                            title: Text(AppLocalizations.of(context).logout,
                            style: TextStyle(
                              color: Colors.black
                            )),
                            onTap: logOut,
                          ),
                        ),
                        PopupMenuItem(
                          value: 4,
                          child: ListTile(
                            leading: Icon(Icons.help,
                                color: appColor),
                            title: Text('Help', //todo: translate
                                style: TextStyle(
                                    color: Colors.black
                                )),
                            onTap: () {
                              Navigator.pushNamed(context, '/HelpScreen');
                            },
                          ),
                        ),
                      ];
                    },
                  )
                ]
            ),
            body: ModalProgressHUD(
              inAsyncCall: isLoading,
              child: Center(
                child: Container(
                    child: (Provider.of<SelectedQueues>(context).count == 0) ? Column(
                      children: [
                        Expanded(
                          flex: 9,
                          child: Container(
                            child: Center(child:Text(
                              AppLocalizations.of(context).nothingToShow,
                              style: TextStyle(
                                color: Colors.black,
                              )
                            )),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: FlatButton(
                            onPressed: (){
                              Navigator.pushNamed((context), '/SelectSearchMethodScreen' );
                            },
                            child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 40),
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
                                            AppLocalizations.of(context).findServiceHere,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white,
                                            )
                                        ),
                                      ),
                                    )
                                )
                            ),
                          ),
                        )
                      ]) : Column(
                      children: [
                        Expanded(
                          flex: 9,
                          child: Container(
                            child: ListView.builder(
                              itemBuilder: (context, index) {
                                Queue _queue = Provider.of<SelectedQueues>(context).get(index);
                                return SelectedQueueTile(queue: _queue, saveQueueCallback: saveQueue);
                              },
                              itemCount: Provider.of<SelectedQueues>(context).count,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Container(
                            child: FlatButton(
                              onPressed: (){
                                Navigator.pushNamed((context), '/SelectSearchMethodScreen' );
                              },
                              child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: 40),
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
                                              AppLocalizations.of(context).findServiceHere,
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white,
                                              )
                                          ),
                                        ),
                                      )
                                  )
                              ),
                            ),
                          )
                        )
                      ],
                    )
                ),
              ),
            ),
        ),
    );
  }
}



