import 'package:flutter/material.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';


class SelectedQueues extends ChangeNotifier {
  List<Queue> _selectedQueues = [];

  void add(Queue newQueue) {
    _selectedQueues.add(newQueue);
    notifyListeners();
  }

  bool contains(Queue queue) {
    return (_selectedQueues.isEmpty) ? false  :  _selectedQueues.contains(queue) ;
  }

  void delete(Queue queue){
    _selectedQueues.remove(queue);
    notifyListeners();
  }

  void empty() {
    _selectedQueues.clear();
  }

  Queue get(int index) {
    return _selectedQueues[index];
  }

  int get count {
    return _selectedQueues.length;
  }

}


class SelectedModifiedQueues extends ChangeNotifier {
  List<Queue> _selectedModifiedQueues = [];

  void add(Queue newQueue) {
    _selectedModifiedQueues.add(newQueue);
    notifyListeners();
  }

  void delete(Queue queue){
    _selectedModifiedQueues.remove(queue);
    notifyListeners();
  }

  void empty() {
    _selectedModifiedQueues.clear();
  }

  Queue get(int index) {
    return _selectedModifiedQueues[index];
  }

  int get count {
    return _selectedModifiedQueues.length;
  }
}