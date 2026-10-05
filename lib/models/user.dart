class HusseinAdvmobprogUser {
  // User details
  final int id;
  // Firebase Authentication UID (also the Firestore Users document id)
  final String uid;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String image;
  final int age;
  final String contactNo;
  final String loginType;

  // Tokens used for login
  final String? accessToken;
  final String? refreshToken;

  HusseinAdvmobprogUser({
    required this.id,
    this.uid = '',
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    required this.image,
    this.age = 0,
    this.contactNo = '',
    this.loginType = 'User',
    this.accessToken,
    this.refreshToken,
  });

  // Gets the user's complete name
  String get fullName => '$firstName $lastName'.trim();

  // Convert API data into a user object
  factory HusseinAdvmobprogUser.fromJson(Map<String,dynamic> json) {
    return HusseinAdvmobprogUser(
      id: json['id'] is num
          ? (json['id'] as num).toInt()
          : int.tryParse('${json['id'] ?? 0}') ?? 0,
      uid: json['uid']?.toString() ?? '',
      username: json['username']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      image: json['image']?.toString() ?? '',
      age: json['age'] is num
          ? (json['age'] as num).toInt()
          : int.tryParse('${json['age'] ?? 0}') ?? 0,
      contactNo: json['contactNo']?.toString() ?? json['phone']?.toString() ?? '',
      loginType: json['loginType']?.toString() ?? 'User',
      accessToken: json['accessToken']?.toString() ?? json['token']?.toString(),
      refreshToken: json['refreshToken']?.toString(),
    );
  }

  // Convert the user object back to JSON
  Map<String,dynamic> toJson() {
    return {
      'id': id,
      'uid': uid,
      'username': username,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'gender': gender,
      'image': image,
      'age': age,
      'contactNo': contactNo,
      'loginType': loginType,
      'accessToken': accessToken,
      'refreshToken': refreshToken,
    };
  }

  // Make a copy when updating user details
  HusseinAdvmobprogUser copyWith({
    int? id,
    String? uid,
    String? username,
    String? email,
    String? firstName,
    String? lastName,
    String? gender,
    String? image,
    int? age,
    String? contactNo,
    String? loginType,
    String? accessToken,
    String? refreshToken,
  }) {
    return HusseinAdvmobprogUser(
      id: id ?? this.id,
      uid: uid ?? this.uid,
      username: username ?? this.username,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      gender: gender ?? this.gender,
      image: image ?? this.image,
      age: age ?? this.age,
      contactNo: contactNo ?? this.contactNo,
      loginType: loginType ?? this.loginType,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }
}