import "package:flutter/material.dart";

Future<void> showConnectFailed(BuildContext context) async{
  await showDialog(
    builder: (context) {
      return AlertDialog(
        content: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '!',
              style: TextStyle(
                color: Colors.amber[800],
                fontSize: 40,
              )
            ),
            Text(
              'Connection Failure.',
              style: TextStyle(
                color: Colors.red,
              )
            ),
            Text(
              'Please make sure you have an active internet connection then try again',
              textAlign: TextAlign.center,
                style: TextStyle(
                color: Colors.black,
                )
              )
          ]
        ),
        actions: [
          TextButton(
            child: Text('ok'),
            onPressed: (){
              Navigator.pop(context);
            }
          )
        ]
      );
    }
  );
}
