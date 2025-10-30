class Lead {
  final String customerName;
  final String mobile;
  final String location;
  final String leadDate;
  final String apptime;
  final String pincode;
  final String offAddress;
  final String offName;
  final String offPincode;
  final String resAddress;
  final String clientname;
  final String leadId;
  final String leadType;
  final String amzAppId;
  final String clientId;

  Lead({
    required this.customerName,
    required this.mobile,
    required this.location,
    required this.leadDate,
    required this.apptime,
    required this.pincode,
    required this.offAddress,
    required this.offName,
    required this.offPincode,
    required this.resAddress,
    required this.clientname,
    required this.leadId,
    required this.leadType,
    required this.amzAppId,
    required this.clientId,
  });

  factory Lead.fromJson(Map<String, dynamic> json) {
    return Lead(
      customerName: json['customer_name'],
      //decryptText(json['customer_name'], key),
      mobile: json['mobile'],
      //decryptText(json['mobile'], key),
      location: json['location'],
      leadDate: json['lead_date'],
      apptime: json['apptime'],
      pincode: json['pincode'],
      offAddress: json['off_address'],
      //decryptText(json['off_address'], key),
      offName: json['off_name'],
      //decryptText(json['off_address'], key),
      offPincode: json['off_pincode'],
      resAddress: json['res_address'],
      // decryptText(json['res_address'], key),
      clientname: json['clientname'],
      leadId: json['lead_id'],
      leadType: json['lead_type'],
      amzAppId: json['AMZAppId'],
      clientId: json['client_id'],
    );
  }
}
