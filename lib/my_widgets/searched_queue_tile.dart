// this list tile holds basic information about the searched queues,
import 'package:flutter/material.dart';
import 'package:no_queues_client/screens/queue_profile.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';

class SearchedQueueTile extends StatelessWidget {
  final Queue queue;
  SearchedQueueTile(this.queue);
  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Colors.white,
      title: Text(
        queue.name,
        style: TextStyle(
          color: Colors.black,
          fontSize: 20,
        )
      ),
      onTap: () {
        showModalBottomSheet(
            context: context,
            builder: (context) {
              return QProfile(queue);
            });
      }

    );
    }
  }
