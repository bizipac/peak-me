import 'package:flutter/material.dart';

class utils{
  void showSnackBar(BuildContext context,String title){
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        margin: EdgeInsets.all(15),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black,
        content: Text(title,style: TextStyle(color: Colors.white),)));
  }

}