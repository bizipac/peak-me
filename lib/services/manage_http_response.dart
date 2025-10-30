import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void manageHttpResponse({
  required http.Response response, //http res from the req
  required BuildContext context,//the context is to show snackbar
  required VoidCallback onSuccess,//the callback to excute on successful response

}){
  //switch statement to handle diffrent http status codes
  switch(response.statusCode){
    case 200://status code 200 indicates a successfull request
      onSuccess();
      break;
    case 400://status code 400 indicates bad req
      showSnackBar(context, jsonDecode(response.body)['msg']);
      break;
    case 500://status code 500 indicates a server error
      showSnackBar(context, jsonDecode(response.body)['error']);
      break;
    case 201://status code 201 indicates a resource was created successfully
      onSuccess();
      break;
  }
}

void showSnackBar(BuildContext context,String title){
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      margin: EdgeInsets.all(15),
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.grey,
      content: Text(title)));
}