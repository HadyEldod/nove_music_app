import 'package:musicc/domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.name,
    required super.displayName,
    required super.imageUrl,
    required super.creationDate,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      displayName: json['dispname'] ?? json['name'] ?? '',
      imageUrl: json['image'] ?? '',
      creationDate: json['creationdate'] ?? '',
    );
  }
}
