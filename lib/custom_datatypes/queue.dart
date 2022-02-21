
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
//A convenient datatype to hold information about a queue
class Queue {
  final QueryDocumentSnapshot snapshot;
  final DocumentSnapshot dSnapshot;
  final bool isModified; // this variable tells us that this queue contains more information than usual e.g client index , initial position.
  String _name; //used to create a queue without using a documentSnapshot e.g from list and maps
  String _id; //used to create a queu without using a documentsnapshot e.g from list and maps
  //this initialization is so that the queue can accommodate a variety of dataTypes
  Queue({this.snapshot, this.dSnapshot, this.isModified = false});

  void setName(String newName) {
    _name = newName;
  }

  String get getName {
    return _name;
  }

  String get getId {
    return id;
  }

  void setId(String id) {
    _id = id;
  }

  String get name {
    if (_name == null) {
      return (snapshot != null) ? snapshot['name'] : dSnapshot['name'];
    }else {
      return _name;
    }

  }


  String get location {
    return (snapshot != null) ? snapshot['location'] : dSnapshot['location'];
  }


  bool get open {
    return (snapshot != null) ? snapshot['open'] : dSnapshot['open'];
  }

  String get id {
    if(_id == null) {
      return (snapshot != null) ? snapshot['id'] : dSnapshot['id'];
    }else {
      return _id;
    }
  }

  String get openingTime {
    return (snapshot != null) ? snapshot['opening_time'] : dSnapshot['opening_time'];
  }

  String get closingTime {
    return (snapshot != null) ? snapshot['closing_time'] : dSnapshot['closing_time'];
  }


  int get clientIndex {
    if(isModified){
      return (snapshot != null) ? snapshot['client_index'] : dSnapshot['client_index'];
    }else return -1;
  }

  int get initialPosition {
    if(isModified) {
      return (snapshot != null) ? snapshot['initial_position'] : dSnapshot['initial_position'];
    }else return -1 ;
  }

  // ModifiedQueue generateModQueue({Queue queue, int tclientIndex, int initialPosition}) {
  //   return ModifiedQueue(tqueue: queue, tclientIndex: tclientIndex, tinitialPosition: initialPosition, generatedFromQueue: true);
  // }
  //add more properties if necessary
}

