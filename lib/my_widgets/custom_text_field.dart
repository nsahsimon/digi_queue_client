import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {

  final TextEditingController controller;
  final String hintText;
  final String labelText;
  final bool obscureText;
  final Function validator;
  // final Future<Function> asyncValidator;

  MyTextField({this.hintText = '', this.controller, this.labelText = '', this.obscureText = false, this.validator,});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          obscureText: obscureText,
          cursorColor: Colors.black,
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            labelText: labelText,
          ),
          validator: validator,
        ),
        SizedBox(
          height: 20,
        ),
      ],
    );
  }

}


