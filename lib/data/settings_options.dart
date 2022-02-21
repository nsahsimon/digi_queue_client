import 'package:flutter/cupertino.dart';
import 'package:no_queues_client/my_widgets/settings_tile.dart';
import 'package:provider/provider.dart';
import 'package:no_queues_client/data/settings_data.dart';
import 'package:no_queues_client/screens/selected_queues_screen.dart';

  List<SettingsTile> options(BuildContext context) {
    List<SettingsTile> optionsToOutput = [];
    List<int> indexesToRemove = [];
    //this list contains all the settings options including those that would not be used always,
    List<Widget> _optionList = [
      SettingsTile(
        name: 'Language',
        onTap: () {
          Navigator.pushNamed(context, '/ModifiedSelectLangScreen');
        } ,
      ),
      SettingsTile(
        name: 'Ring',
        useSwitch: true,
        switchState: Provider.of<SettingsData>(context).getRingState,
        onChanged: (bool newValue) {
          Provider.of<SettingsData>(context, listen: false).setRingTo(newValue);
        },
      ),
      SettingsTile(
        name: 'Ringing Tone',),
      SettingsTile(
        name: 'Change Name',
      ),
      SettingsTile(
        name: 'Notification Interval',
      )
    ];


    if (!Provider.of<SettingsData>(context).getRingState)
      {
        indexesToRemove.add(2); //we add 1 since 1 is the index of the widget containing the 'Ring Tone' setting option
      }

    for(var index = 0; index < _optionList.length; index++ ) {
      if(!(indexesToRemove.contains(index))) {
        optionsToOutput.add(_optionList[index]);
      }
    }

    return optionsToOutput;

  }
