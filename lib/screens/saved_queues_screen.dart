import 'dart:io';

import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/my_widgets/selected_queue_tile.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:modal_progress_hud/modal_progress_hud.dart';
import 'package:no_queues_client/context.dart';
import 'package:no_queues_client/data/saved_queues.dart';
import 'package:no_queues_client/my_widgets/saved_queue_tile.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:no_queues_client/my_widgets/dialogs.dart';




class SavedQueuesScreen extends StatefulWidget {

  @override
  _SavedQueuesScreenState createState() => _SavedQueuesScreenState();
}

class _SavedQueuesScreenState extends State<SavedQueuesScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore db = FirebaseFirestore.instance;
  bool isLoading = false;
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

  @override
  void initState() {
    // TODO: check on disk for queues to which the user was previously subscribed ,query the database. if the queues are still valid, update them,
    super.initState();
    // notifications.initialize();
    Future(() async{
      // if(await Dialogs(context: context).checkConnectionDialog() != true) {return;}
      loadSavedQueuesfromCloud();
    });
    myContext.updateContext(context);
  }

  Future<void> deleteQueueCallback(queue) async {
    startLoad();
    if(await Dialogs(context: context).checkConnectionDialog() != true) {
      stopLoad();
      return;}
    stopLoad();
    try {
      await db.collection('client_details').doc(auth.currentUser.uid).set({
        'saved_queues' : FieldValue.arrayRemove([{
          'id' : queue.id,
          'name' : queue.name,
        }])
      }, SetOptions(merge: true));
      Provider.of<SavedQueues>(context, listen: false).delete(queue);
      await loadSavedQueuesfromCloud();
    } catch (e) {
      await Dialogs(context: context).poorInternetConnectionDialog();
      debugPrint('$e');
    }
  }

  Future<void> loadSavedQueuesfromCloud() async{
    startLoad();
    if(await Dialogs(context: context).checkConnectionDialog() != true) {
      stopLoad();
      return;}
    Provider.of<SavedQueues>(context, listen: false).empty();

      try {
        var savedQueueDoc = await db.collection('client_details').doc('${auth.currentUser.uid}').get();
        try {
          if (savedQueueDoc.exists) {
            List savedQueues = savedQueueDoc['saved_queues'];
            if (savedQueues.isNotEmpty) {
              for (var savedQueue in savedQueues) {
                String id = savedQueue['id'];
                String name = savedQueue['name'];
                debugPrint('name = ${savedQueue['name']}');
                Queue newQueue = Queue();
                newQueue.setName(name);
                newQueue.setId(id);
                debugPrint(id);
                Provider.of<SavedQueues>(context, listen: false).add(newQueue);
                debugPrint('-----${Provider.of<SavedQueues>(context, listen: false).count} Queues loaded-----');
              }
            }
          }
        }catch (e) {
          debugPrint(e.toString());
        }
      }catch(e) {
        debugPrint(e);
        await Dialogs(context: context).poorInternetConnectionDialog();
        debugPrint('-----------Unable to load your subscriptions---------');
      }

    stopLoad();
  }


  @override
  Widget build(BuildContext context) {
    print('----build method executed----');
    myContext.updateContext(context);
    return ModalProgressHUD(
      inAsyncCall: isLoading,
      child: Scaffold(
          appBar: AppBar(
              title: Text(
                AppLocalizations.of(context).savedQueues,
              ),
          ),
          body: Center(
            child: Container(
                child: (Provider.of<SavedQueues>(context).count == 0) ? Center(child:Text(
                    AppLocalizations.of(context).nothingToShow,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black,
                    )
                )) : ListView.builder(
                  itemBuilder: (context, index) {
                    Queue _queue = Provider.of<SavedQueues>(context).get(index);
                    return SavedQueueTile(queue: _queue, deleteQueueCallback: deleteQueueCallback);
                  },
                  itemCount: Provider.of<SavedQueues>(context).count,
                )
            ),
          )
      ),

    );
  }
}



