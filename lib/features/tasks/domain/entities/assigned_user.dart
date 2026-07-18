import 'package:equatable/equatable.dart';

/// A mock user assigned to a task — dummyjson has no concept of this, so it's derived.
class AssignedUser extends Equatable {
  const AssignedUser({required this.name});

  final String name;

  String get initial => name.isNotEmpty ? name[0].toUpperCase() : '?';

  @override
  List<Object?> get props => [name];
}
