import 'package:flutter/material.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';


class SavedQueues extends ChangeNotifier {
  List<Queue> _savedQueues = [];
  List<String> _savedQueuesId = [];//used to hold just the ids of the saved queues since the queue itself contains more information than the saved queue might require

  void add(Queue newQueue) {
    _savedQueues.add(newQueue);
    _savedQueuesId.add(newQueue.id);
    notifyListeners();
  }

  void delete(Queue queue){
    _savedQueues.remove(queue);
    _savedQueuesId.remove(queue.id);
    notifyListeners();
  }

  void empty() {
    _savedQueues.clear();
    _savedQueuesId.clear();
  }

  bool doesQueueExist(queue) {
    return _savedQueuesId.contains(queue.id);
  }

  Queue get(int index) {
    return _savedQueues[index];
  }

  int get count {
    return _savedQueues.length;
  }

}

