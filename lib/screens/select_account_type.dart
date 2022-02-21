import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/screens/sign_up_screen.dart';
import 'package:no_queues_client/screens/selected_queues_screen.dart';
import 'package:no_queues_client/screens/provider_reg_page.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SelectAccountType extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
           children: [
              Text('Select An Account Type'),
              FlatButton(
                color: appColor,
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => SignUpScreen()));
                  },
                  child: Text('Customer Account',
                  style: TextStyle(
                      color: Colors.white,
                    fontSize:15 ,
                  ))),
              FlatButton(
                color: appColor,
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => ProviderRegPage()));
                  },
                child: Text('Service Provider Account',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ))
              ),

             //temporal option to access other features of the app
             FlatButton(
                 color: appColor,
                 onPressed: () {
                   Navigator.push(context, MaterialPageRoute(builder: (context) => SelectedQueuesScreen()));
                 },
                 child: Text('My Queues',
                     style: TextStyle(
                       color: Colors.white,
                       fontSize:15 ,
                     ))),
            ]
          ),
        ),
      ),
    );
  }
}
