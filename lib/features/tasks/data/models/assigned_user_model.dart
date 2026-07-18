import 'package:json_annotation/json_annotation.dart';
import 'package:team_workspace/features/tasks/domain/entities/assigned_user.dart';

part 'assigned_user_model.g.dart';

/// Persistence shape for [AssignedUser] — the domain entity itself has no
/// serialization coupling; only this data-layer model does.
@JsonSerializable()
class AssignedUserModel {
  AssignedUserModel({required this.name});

  final String name;

  factory AssignedUserModel.fromJson(Map<String, dynamic> json) =>
      _$AssignedUserModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssignedUserModelToJson(this);

  factory AssignedUserModel.fromEntity(AssignedUser entity) =>
      AssignedUserModel(name: entity.name);

  AssignedUser toEntity() => AssignedUser(name: name);
}
