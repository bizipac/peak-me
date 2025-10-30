
import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../model/user_model.dart';

class UserProvider extends StateNotifier<UserModel?>{
  // contructore initalizing with default User Object
  ///purpose: manage the state of the user object allowing updates
  UserProvider(): super(
      UserModel(
          uid: '',
          name: '',
          mobile: '',
          address: '',
          image: '',
          imagePoliceVerification: '',
          rolename: '',
          branchId: '',
          roleId: '',
          authId: '',
        branch_name: '',
      ));

  ///Geter method to extract value from an Object

  UserModel? get user=>state;

  //method to set user from Json
  //purpose : updates he user state base on json string respresentation of user onect

  void setUser(String userJson){
    state=UserModel.fromJson(userJson as Map<String, dynamic>);
  }
  //Method to clear user state
  void signOut(){
    state=null;
  }
}
final userProvider = StateNotifierProvider<UserProvider, UserModel?>((ref)=>
    UserProvider());