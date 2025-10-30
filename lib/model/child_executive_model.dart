class ChildExecutiveModel {
  final String cid;
  final String fname;
  final String mobile;
  final String address;
  final String branchName;
  final String avatar;

  ChildExecutiveModel({
    required this.cid,
    required this.fname,
    required this.mobile,
    required this.address,
    required this.branchName,
    required this.avatar,
  });

  factory ChildExecutiveModel.fromJson(Map<String, dynamic> json) {
    return ChildExecutiveModel(
      cid: json['cid'] ?? '',
      fname: json['fname'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'] ?? '',
      branchName: json['branch_name'] ?? '',
      avatar: json['avatar'] ?? '',
    );
  }
}