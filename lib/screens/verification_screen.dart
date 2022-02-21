import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/my_widgets/custom_text_field.dart';

class VerificationScreen extends StatelessWidget {

  final TextEditingController smsCodeController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15.0),
        child: ListView(

            children: [
              SizedBox(
                height: 50,
              ),
              MyTextField(controller: smsCodeController, hintText: 'Enter 6 digit verification Code', labelText: 'SMS Code'),
              FlatButton(
                  color: appColor,
                  onPressed: () async{

                    Navigator.pop(context, smsCodeController.text);
                  },
                  child: Center(
                    child: Text('Confirm Code',
                        style: TextStyle(
                          color: Colors.white,
                        )),
                  ))
            ]
        ),
      ),
    );
  }
  }

