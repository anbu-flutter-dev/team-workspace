import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'assigned_user.g.dart';

/// A mock user assigned to a task — dummyjson has no concept of this, so it's derived.
@JsonSerializable()
class AssignedUser extends Equatable {
  const AssignedUser({required this.name});

  final String name;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  factory AssignedUser.fromJson(Map<String, dynamic> json) =>
      _$AssignedUserFromJson(json);

  Map<String, dynamic> toJson() => _$AssignedUserToJson(this);

  @override
  List<Object?> get props => [name];
}
