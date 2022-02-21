import 'package:flutter/material.dart';
import 'package:no_queues_client/custom_datatypes/queue.dart';
import 'package:no_queues_client/screens/queue_screen.dart';
import 'package:no_queues_client/constants.dart';


class SelectedQueueTile extends StatefulWidget {
  final Queue queue;
  final Function saveQueueCallback;

  SelectedQueueTile({this.queue, this.saveQueueCallback});

  @override
  State<SelectedQueueTile> createState() => _SelectedQueueTileState();
}

class _SelectedQueueTileState extends State<SelectedQueueTile> {
  bool isFavorite = false;
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
            icon: Icon(Icons.favorite_border,
            color: Colors.red,),
            onPressed: () async{
              await widget.saveQueueCallback(widget.queue); },
          ) ,
          onTap: () {
            Navigator.push((context),  MaterialPageRoute(
              builder: (context) {
                return QueueScreen(widget.queue);
              }
            ));
          },
        ),
      ),
    );
  }
}
