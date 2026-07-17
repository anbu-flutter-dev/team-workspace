import 'package:freezed_annotation/freezed_annotation.dart';

part 'assigned_user.freezed.dart';
part 'assigned_user.g.dart';

/// A mock user assigned to a task — dummyjson has no concept of this, so it's derived.
@freezed
abstract class AssignedUser with _$AssignedUser {
  const AssignedUser._();

  const factory AssignedUser({required String name}) = _AssignedUser;

  factory AssignedUser.fromJson(Map<String, dynamic> json) =>
      _$AssignedUserFromJson(json);

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';
}
