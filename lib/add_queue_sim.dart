//this widget displays some useful information about any selected queue in the 'search screen'
//its going to be be displayed as a bottom sheet widget
import 'package:flutter/material.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';


class AddQueueSim {
  final Queue queue;
  AddQueueSim(this.queue);


  Future<void> addClientDetails() async{
    FirebaseFirestore db = FirebaseFirestore.instance;
    FirebaseAuth _auth = FirebaseAuth.instance;
    bool _userExists = false;
    if(!_userExists){
      print('-------user doesn\'t yet exist-------');
      try {
        await db.collection('client_details').add({
          'phone': '+237111111111',
          'name': 'sim user',
          'id': 'no_id'
        });

      } catch(e){
        print(e);
      }
    }else print('=------user already exists----------');
  }
  Future<void> joinQueue() async{
    var auth = FirebaseAuth.instance;
    var db = FirebaseFirestore.instance;

      //add this client to the list of clients subscribed to this queue;
      try {
        await db.collection('subscribers_'+ queue.id).add(
            {
              'client_id' : 'no_id',
              'timestamp' : FieldValue.serverTimestamp(),
              'initial_position' : 0
            });
        await addClientDetails();
      } catch(e) {
        debugPrint('--------failed to join queue---------');
      }
      debugPrint('-------successfully joined Queue--------');

  }

}
// add the this queue to the list of this client's queues or subscriptions
// await db.collection('my_queues_' + auth.currentUser.uid).doc(queue.id).set({
//   'queue_id' : queue.id,
// });