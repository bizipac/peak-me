import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controller/receivedLead_controller.dart';
import '../model/new_lead_model.dart';
import '../services/ExotelService.dart';
import '../services/getCurrentLocation.dart';
import '../utils/app_constant.dart';
import 'lead_detail_screen.dart';

class ReceivedLeadScreen extends StatefulWidget {
  const ReceivedLeadScreen({super.key});

  @override
  State<ReceivedLeadScreen> createState() => _ReceivedLeadScreenState();
}

class _ReceivedLeadScreenState extends State<ReceivedLeadScreen> {
  final ReceivedLeadController receivedLeadController =
      ReceivedLeadController();

  // Future holding current list source (either full list or filtered result)
  //late Future<List<Lead>> leads;
  late Future<List<Lead>> leads = Future.value([]);

  // For user/session values
  String uid = '';
  String branchId = '';
  String appVersion = '40';
  String appType = '';

  // Search state
  String _searchQuery = '';

  // friendly visible total (kept to mimic your previous UI)
  String total = '';

  // load stored user info
  Future<void> loadUserData() async {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    // appVersion = packageInfo.version;
    appType = Platform.isIOS ? 'ios' : 'android';
    uid = prefs.getString('uid') ?? '';
    branchId = prefs.getString('branchId') ?? '';
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(
        dateString,
      ); // API से जो format आता है वो parse होगा
      return DateFormat('dd-MM-yyyy').format(date);
    } catch (e) {
      return dateString; // अगर parse fail हो जाए तो original string return
    }
  }

  // common function to fetch current leads from API (same params you already used)
  Future<List<Lead>> _fetchLeadsFromApi() {
    return receivedLeadController.fetchLeads(
      uid: uid,
      start: 0,
      end: 2000,
      branchId: branchId,
      app_version: appVersion,
      appType: appType,
    );
  }

  // search in the fetched list by leadId (substring match)
  Future<List<Lead>> _searchLeadsById(String query) async {
    final all = await _fetchLeadsFromApi();
    final q = query.trim();
    if (q.isEmpty) return all;
    final filtered = all.where((l) {
      final leadId = l.leadId?.toString() ?? '';
      final mobile = l.pincode?.toString() ?? '';

      // match agar leadId OR mobile me query contain karta hai
      return leadId.contains(q) || mobile.contains(q);
    }).toList();
    return filtered;
  }

  // opens dialog to input leadId
  void _openSearchDialog() {
    final TextEditingController controller = TextEditingController(
      text: _searchQuery,
    );
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Search',
            style: TextStyle(
              fontSize: 15,
              color: AppConstant.darkHeadingColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(
              hintText: 'Enter Lead_id/Pin code ',
              hintStyle: TextStyle(
                fontSize: 14,
                color: AppConstant.appTextColor,
              ),
            ),

            onSubmitted: (_) => _performSearchFromDialog(controller),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // cancel
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: AppConstant.darkButton),
              ),
            ),
            TextButton(
              onPressed: () => _performSearchFromDialog(controller),
              child: Text(
                'Search',
                style: TextStyle(color: AppConstant.darkButton),
              ),
            ),
          ],
        );
      },
    );
  }

  // helper used by dialog
  void _performSearchFromDialog(TextEditingController controller) {
    final q = controller.text.trim();
    Navigator.of(context).pop(); // close dialog
    if (q.isEmpty) {
      // if empty, restore full list
      setState(() {
        _searchQuery = '';
        leads = _fetchLeadsFromApi();
      });
    } else {
      setState(() {
        _searchQuery = q;
        leads = _searchLeadsById(q);
      });
    }
  }

  // clear search and restore all leads
  void _clearSearch() {
    setState(() {
      _searchQuery = '';
      leads = _fetchLeadsFromApi();
    });
  }

  //this code use to open google map from <==> to
  Future<void> openMap({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
  }) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&origin=$fromLat,$fromLng&destination=$toLat,$toLng&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      throw 'Could not launch Maps';
    }
  }

  Future<void> _callLeads(BuildContext context, String leadId) async {
    String? number = await ExotelService.getVirtualNumber(leadId);
    // check permission
    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
      if (!status.isGranted) {
        throw 'Phone call permission not granted';
      }
    }
    if (number != null) {
      await FlutterPhoneDirectCaller.callNumber(number);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Image.asset("assets/logo/cmp_logo.png", height: 24, width: 24),
              const SizedBox(width: 10),
              const Expanded(
                child: Text("No number found", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  String location_lat = '';
  String location_long = '';

  void _getLocation() async {
    try {
      Position position = await getCurrentLocation();
      setState(() {
        location_lat = '${position.latitude}';
        location_long = '${position.longitude}';
      });
    } catch (e) {
      setState(() {
        location_lat = 'Error: ${e.toString()}';
        location_long = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
    // load user data and then fetch initial leads
    loadUserData().then((_) {
      setState(() {
        leads = _fetchLeadsFromApi();
      });
    });
  }

  String _sortOrder = "Oldest First";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppConstant.appBarColor,
        title: Text(
          _searchQuery.isEmpty
              ? 'Lead Received'.toUpperCase()
              : 'Search: ${_searchQuery}'.toUpperCase(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.normal,
            color: AppConstant.appBarWhiteColor,
          ),
        ),
        iconTheme: IconThemeData(color: AppConstant.appBarWhiteColor),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: _openSearchDialog,
            tooltip: 'Search by lead id',
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.white),
              onPressed: _clearSearch,
              tooltip: 'Clear search',
            ),
        ],
      ),
      body: FutureBuilder<List<Lead>>(
        future: leads,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print("Error : ${snapshot.error}");
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // update visible total
            total = '0';
            return const Center(child: Text('No leads available...'));
          } else {
            final leadsList = snapshot.data!;
            // update visible total only when changed (avoids re-build loops)
            // 🔹 sort by date (oldest first)

            leadsList.sort((a, b) {
              final dateA =
                  DateTime.tryParse(a.leadDate ?? '') ?? DateTime(1900);
              final dateB =
                  DateTime.tryParse(b.leadDate ?? '') ?? DateTime(1900);

              if (_sortOrder == "Oldest First") {
                return dateA.compareTo(dateB); // oldest → newest
              } else {
                return dateB.compareTo(dateA); // newest → oldest
              }
            });
            if (total != leadsList.length.toString()) {
              // use setState safely inside builder - only when changed
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() {
                    total = leadsList.length.toString();
                  });
                }
              });
            }

            return Column(
              children: [
                // 🔹 Filter bar
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  color: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Leads count
                      Text(
                        "Total Leads: ${leadsList.length}",
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppConstant.darkHeadingColor,
                        ),
                      ),

                      // 🔹 Dropdown filter
                      DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortOrder,
                          dropdownColor: AppConstant.darkButton,
                          items: ["Oldest First", "Newest First"].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: const TextStyle(fontSize: 14),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _sortOrder = value!;
                              // refresh with sorting
                              leads = _searchQuery.isEmpty
                                  ? _fetchLeadsFromApi()
                                  : _searchLeadsById(_searchQuery);
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔹 Leads list
                Expanded(
                  child: ListView.builder(
                    itemCount: leadsList.length,
                    itemBuilder: (context, index) {
                      final lead = leadsList[index];

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: AppConstant.borderColor, // 🔶 Orange border
                            width: 2, // Border thickness
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      (lead.customerName ?? '').toUpperCase(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppConstant.darkHeadingColor,
                                      ),
                                    ),
                                  ),
                                  CircleAvatar(
                                    backgroundColor: AppConstant.darkButton,
                                    child: IconButton(
                                      onPressed: () async {
                                        final response = lead.leadId ?? '';
                                        _callLeads(context, response);
                                      },
                                      icon: Icon(
                                        Icons.call,
                                        color: AppConstant.whiteBackColor,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppConstant.iconColor,
                                    child: Icon(
                                      Icons.house_outlined,
                                      color: AppConstant.whiteBackColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      lead.clientname ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 2,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Text(
                                    lead.pincode ?? '',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppConstant.darkButton,
                                    child: Icon(
                                      Icons.date_range,
                                      color: AppConstant.whiteBackColor,
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  Expanded(
                                    child: Text(
                                      _formatDate(lead.leadDate),
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      lead.apptime ?? '',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppConstant.iconColor,
                                    child: InkWell(
                                      onTap: () async {
                                        try {
                                          final location =
                                              lead.location?.trim() ?? '';
                                          print("Location: $location");

                                          final offPin =
                                              lead.offPincode?.trim() ?? '';
                                          final resAddress =
                                              '${lead.resAddress?.trim() ?? ''} ${lead.pincode?.trim() ?? ''}'
                                                  .trim();

                                          final offName =
                                              lead.offName?.trim() ?? '';
                                          final offAddress =
                                              lead.offAddress?.trim() ?? '';
                                          final offFullAddress =
                                              [offName, offAddress, offPin]
                                                  .where((s) => s.isNotEmpty)
                                                  .join(', ');

                                          // Convert lat/lng to double safely
                                          final double fromLat =
                                              double.tryParse(
                                                location_lat.toString(),
                                              ) ??
                                              0.0;
                                          final double fromLng =
                                              double.tryParse(
                                                location_long.toString(),
                                              ) ??
                                              0.0;
                                          print("----------------");
                                          print(fromLng);
                                          print(fromLat);
                                          if (resAddress.isEmpty &&
                                              offFullAddress.isEmpty) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "No address available for navigation.",
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          if (location.toLowerCase() ==
                                              "office") {
                                            List<Location> locationsOffice = [];
                                            print(
                                              "Getting office address location...",
                                            );
                                            print(
                                              "Office Address: $offFullAddress",
                                            );

                                            if (offFullAddress.isNotEmpty) {
                                              try {
                                                locationsOffice =
                                                    await locationFromAddress(
                                                      offFullAddress,
                                                    );
                                              } catch (e) {
                                                print(
                                                  'Error getting office location: $e',
                                                );
                                              }
                                            }

                                            if (locationsOffice.isNotEmpty) {
                                              print("----------------");
                                              print(fromLng);
                                              print(fromLat);
                                              print(
                                                locationsOffice.first.latitude,
                                              );
                                              print(
                                                locationsOffice.first.longitude,
                                              );
                                              await openMap(
                                                fromLat: fromLat,
                                                fromLng: fromLng,
                                                toLat: locationsOffice
                                                    .first
                                                    .latitude,
                                                toLng: locationsOffice
                                                    .first
                                                    .longitude,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Office address not found on map.",
                                                  ),
                                                ),
                                              );
                                            }
                                          } else if (location.toLowerCase() ==
                                              "residence") {
                                            List<Location> locationsRes = [];
                                            print(
                                              "Getting residence address location...",
                                            );
                                            print(
                                              "Residence Address: $resAddress",
                                            );

                                            if (resAddress.isNotEmpty) {
                                              try {
                                                locationsRes =
                                                    await locationFromAddress(
                                                      resAddress,
                                                    );
                                              } catch (e) {
                                                print(
                                                  'Error getting residence location: $e',
                                                );
                                              }
                                            }

                                            if (locationsRes.isNotEmpty) {
                                              print("----------------");
                                              print(fromLng);
                                              print(fromLat);
                                              print(
                                                locationsRes.first.latitude,
                                              );
                                              print(
                                                locationsRes.first.longitude,
                                              );
                                              await openMap(
                                                fromLat: fromLat,
                                                fromLng: fromLng,
                                                toLat:
                                                    locationsRes.first.latitude,
                                                toLng: locationsRes
                                                    .first
                                                    .longitude,
                                              );
                                            } else {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    "Residence address not found on map.",
                                                  ),
                                                ),
                                              );
                                            }
                                          } else if (location.isEmpty) {
                                            // Default case: open map from and to same point
                                            List<Location> locationsRes = [];
                                            print(
                                              "Getting residence address location...",
                                            );
                                            print(
                                              "Residence Address: $resAddress",
                                            );
                                            if (resAddress.isNotEmpty) {
                                              try {
                                                locationsRes =
                                                    await locationFromAddress(
                                                      resAddress,
                                                    );
                                              } catch (e) {
                                                print(
                                                  'Error getting residence location: $e',
                                                );
                                              }
                                            }
                                            await openMap(
                                              fromLat: fromLat,
                                              fromLng: fromLng,
                                              toLat:
                                                  locationsRes.first.latitude,
                                              toLng:
                                                  locationsRes.first.longitude,
                                            );
                                          } else {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  "Could not find location for navigation.",
                                                ),
                                              ),
                                            );
                                          }
                                        } catch (e) {
                                          print("Unexpected error: $e");
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                "Unexpected error: $e",
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Icon(
                                        Icons.location_on,
                                        color: AppConstant.whiteBackColor,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      lead.resAddress ?? '',
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 10,
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              ElevatedButton(
                                onPressed: () {
                                  Get.to(() => LeadDetailScreen(lead: lead));
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstant.darkButton,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Center(
                                  child: Text(
                                    'More Details',
                                    style: TextStyle(
                                      color: AppConstant.whiteBackColor,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: AppConstant.borderColor,
        onPressed: () {
          setState(() {
            // refresh current list according to whether search is active
            leads = _searchQuery.isEmpty
                ? _fetchLeadsFromApi()
                : _searchLeadsById(_searchQuery);
          });
        },
        child: const Icon(Icons.refresh, color: AppConstant.whiteBackColor),
      ),
    );
  }
}
