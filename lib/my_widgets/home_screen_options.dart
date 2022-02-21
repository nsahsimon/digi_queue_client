import 'package:flutter/material.dart';

class HomeOption extends StatelessWidget {
  final String name;
  final Icon icon;
  final Function onPressedCallback ;
  HomeOption({this.name, this.icon, this.onPressedCallback});
  @override
  Widget build(BuildContext context) {
    return Container(
      child: FlatButton(
        height: 50,
        color: Colors.blueAccent,
        onPressed: onPressedCallback,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name),
            icon
          ],
        ),
      ),
    );
  }
}

