import 'package:flutter/material.dart';
import 'package:no_queues_client/constants.dart';
import 'package:no_queues_client/data/settings_options.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SettingsScreen extends StatelessWidget {


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: appColor,
        title: Text('Settings',
        style: TextStyle(
          color: Colors.white,
        ))
      ),
      body: ListView.builder(
          itemCount: options(context).length,
          itemBuilder: (context, index) {
            return options(context)[index];
          })
    );
  }
}



