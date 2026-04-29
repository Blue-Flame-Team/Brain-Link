class UserModel {
  final String? id;
  final String fullName;
  final String email;

  UserModel({
    this.id,
    required this.fullName,
    required this.email,
  });


  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
    };
  }


  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
    );
  }
}