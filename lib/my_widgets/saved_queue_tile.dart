import 'package:flutter/material.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:no_queues_client/screens/queue_screen.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/screens/queue_profile.dart';
import 'package:no_queues_client/data/bigData.dart';
import 'package:provider/provider.dart';

class SavedQueueTile extends StatefulWidget {
  final Queue queue;
  final Function deleteQueueCallback;

  SavedQueueTile({this.queue, this.deleteQueueCallback});

  @override
  State<SavedQueueTile> createState() => _SavedQueueTileState();
}

class _SavedQueueTileState extends State<SavedQueueTile> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 10),
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(20)),
            border: Border.all(
                color: appColor,
                width: 2
            )
        ),
        child: ListTile(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.queue.name),
            ],
          ),
          trailing: IconButton(
            icon: Icon(Icons.delete,
              color: Colors.red,),
            onPressed: () async {
              await widget.deleteQueueCallback(widget.queue) ;
    },
    ) ,

    onTap: () {
            showModalBottomSheet(
                context: context,
                builder: (context) {
                  return QProfile(widget.queue);
                });
            // Navigator.push((context),  MaterialPageRoute(
            //     builder: (context) {
            //       return QProfile(widget.queue);
            //     }
            // ));
          },
        ),
      ),
    );
  }
}
