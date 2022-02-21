import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';

class ProviderRegPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Service Registration',
        style: TextStyle(
            color: Colors.white,
        ))
      ),
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: ListView(
            children: [
              SizedBox(
                height: 70,
              ),

              Card(
                //margin: EdgeInsets.all(15),
                child: TextField(
                    cursorColor: appColor,
                    enabled: true,
                    decoration: InputDecoration(
                      hintText: ' Name of Service',
                    )
                ),
              ),
              SizedBox(
                height: 20,
              ),

              FlatButton(
                  minWidth: 400,
                  color: appColor,
                  onPressed: () {
                   //
                  },
                  child: Text('Register',
                      style: TextStyle(
                          color: Colors.white
                      )))
            ]
        ),
      ),
    );
  }
}
