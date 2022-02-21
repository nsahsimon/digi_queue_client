import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';

class BigData extends ChangeNotifier {
  Map<Queue, MyData> completeData = {}; // A map that holds important information about the queue which we might want to keep persistent

  void addData(Queue queue, MyData data) {
    completeData[queue] = data;
    notifyListeners();
  }

  void deleteData(Queue queue) {
    completeData.remove(queue);
    notifyListeners();
  }

  void empty() {
    completeData.clear();
    notifyListeners();
  }


  MyData getData(Queue queue) {
    if(completeData.containsKey(queue)) //first check if the map contains the key
    {
      return completeData[queue];
    }else { // if the map doesn't contain the key, create an item with the key
      completeData[queue] = MyData();
      return completeData[queue];
    }
  }

}


class MyData {

  ///You can declare new variable to hold the desired properties
  int _prevClientIndex = -1;
  int _prevInitialPosition = -1;
  int _prevFirstClientIndex = -1;
  int _prevTimePeriod = -1;
  Timestamp _prevTransitionTime; // The time at which the last client transition occurred
  bool _prevIsOpen; //tells us whether the queue is currently open or not
  Timestamp _prevPauseTime;
  int _prevPauseDuration;


  ///You can add more setters for the new desired properties
  void setClientIndex (int newClientIndex){
    _prevClientIndex = newClientIndex;
  }

  void setInitialPosition (int newInitialPosition) {
    _prevInitialPosition = newInitialPosition;
  }

  void setTimePeriod (int newTimePeriod) {
    _prevTimePeriod = newTimePeriod;
  }

  void setFirstClientIndex (int newFirstClientIndex) {
    _prevFirstClientIndex = newFirstClientIndex;
  }

  void setPrevTransitionTime (Timestamp newPrevTransitionTime) {
    _prevTransitionTime = newPrevTransitionTime;
  }

  void setIsOpen (bool newIsOpen){
    _prevIsOpen = newIsOpen;
  }

  void setPauseTime (Timestamp newPauseTime){
    _prevPauseTime = newPauseTime;
  }

  void setPauseDuration (int newPauseDuration){
    _prevPauseDuration = newPauseDuration;
  }

  ///you can add more getters for new desired properties
  int get prevInitialClientPosition => _prevInitialPosition;
  int get prevClientIndex => _prevClientIndex;
  int get prevFirstClientIndex => _prevFirstClientIndex;
  int get prevTimePeriod => _prevTimePeriod;
  Timestamp get prevTransitionTime => _prevTransitionTime ?? Timestamp.fromDate(DateTime.now());
  bool get prevIsOpen => _prevIsOpen ?? true;
  int get prevPauseDuration => _prevPauseDuration ?? 300;
  Timestamp get prevPauseTime => _prevPauseTime ?? Timestamp.fromDate(DateTime.now());

}
