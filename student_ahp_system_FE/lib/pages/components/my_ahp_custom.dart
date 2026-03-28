import 'package:flutter/material.dart';

class MyAhpCustom extends StatelessWidget {
 final String text;
   const MyAhpCustom({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return   Container(
        color: Colors.grey.shade100,
        height: 50,
        width: double.infinity,
        child: Center(
          child: Text
            (text, style: TextStyle(color:Colors.grey.shade900, fontSize: 17,fontWeight: FontWeight.bold),),
        ));
  }
}
