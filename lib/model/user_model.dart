class UserModel{
  final String uid;
  final String name;
  final String mobile;
  final String address;
  final String image;
  final String imagePoliceVerification;
  final String rolename;
  final String branchId;
  final String branch_name;
  final String roleId;
  final String authId;

  UserModel({
    required this.uid,
    required this.name,
    required this.mobile,
    required this.address,
    required this.image,
    required this.imagePoliceVerification,
    required this.rolename,
    required this.branchId,
    required this.branch_name,
    required this.roleId,
    required this.authId,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      uid: json['uid'].toString(),
      name: json['name'] ?? '',
      mobile: json['mobile'] ?? '',
      address: json['address'] ?? '',
      image: json['image'] ?? '',
      imagePoliceVerification: json['ImagePoliceVerification'] ?? '',
      rolename: json['rolename'] ?? '',
      branchId: json['branch_id']?.toString() ?? '',
      branch_name: json['branch_name']?.toString() ?? '',
      roleId: json['role_id']?.toString() ?? '',
      authId: json['auth_id']?.toString() ?? '',
    );
  }
}
