import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../utils/app_constant.dart';
import '../auth/login.dart';
import '../received_lead_screen.dart';

class AdminDrawerWidget extends StatefulWidget {
  const AdminDrawerWidget({super.key});

  @override
  State<AdminDrawerWidget> createState() => _AdminDrawerWidgetState();
}

class _AdminDrawerWidgetState extends State<AdminDrawerWidget> {
  String name = '';
  String mobile = '';
  String uid='';

  void loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? '';
      mobile = prefs.getString('mobile') ?? '';
      uid = prefs.getString('uid') ?? '';
    });
  }
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(padding: EdgeInsets.only(top: Get.height/8.5),
      child: Drawer(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(topRight: Radius.circular(10.0),
                bottomRight: Radius.circular(10.0))
        ),
        child: Wrap(
          runSpacing: 1,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0,vertical: 10.0),
              child: ListTile(
                titleAlignment: ListTileTitleAlignment.center,
                title: Text(name),
                leading: CircleAvatar(
                  child: Icon(Icons.person),
                ),
                subtitle: Text(mobile),

              ),
            ),
            Divider(
              indent: 10.0,
              endIndent: 10.0,
              thickness: 1.5,
              color: AppConstant.appTextColor,
            ),
          ListTile(
                onTap: (){
                  Get.to(()=>ReceivedLeadScreen());
                },
                titleAlignment: ListTileTitleAlignment.center,
                title: Text("Received Lead"),
                leading: Icon(Icons.dashboard),

              ),

             ListTile(
                onTap: (){
                 // Get.to(()=>LeadScreen());
                },
                titleAlignment: ListTileTitleAlignment.center,
                title: Text("Transfer Lead"),
                leading: Icon(Icons.transfer_within_a_station_outlined),

              ),

             ListTile(
                onTap: (){
                  //Get.to(()=>AllUsersScreen());
                },
                titleAlignment: ListTileTitleAlignment.center,
                title: Text("Search Lead"),
                leading: Icon(Icons.search_rounded),

              ),
            ListTile(
              onTap: (){
                //Get.to(()=>AllUsersScreen());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Onfield Prepaid Card"),
              leading: Icon(Icons.transfer_within_a_station),
            ),
            ListTile(
              onTap: (){
                //Get.to(()=>AllUsersScreen());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Today Collected Lead"),
              leading: Icon(Icons.file_copy_outlined),

            ),
            ListTile(
              onTap: (){
                //Get.to(()=>AllUsersScreen());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Today's Transfer Lead"),
              leading: Icon(Icons.transfer_within_a_station),

            ),
            ListTile(
              onTap: (){
                //Get.to(()=>AllUsersScreen());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Profile"),
              leading: Icon(Icons.person),

            ),
            ListTile(
              onTap: (){
                //Get.to(()=>AllUsersScreen());
              },
              titleAlignment: ListTileTitleAlignment.center,
              title: Text("Logout"),
              leading: Icon(Icons.logout_outlined),
            ),
          ],
        ),
        backgroundColor:Colors.white,
        width: 275,

      ),
    );
  }
}