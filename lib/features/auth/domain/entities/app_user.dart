import 'package:equatable/equatable.dart';

/// The authenticated user — domain layer, no Firebase types leak past here.
final class AppUser extends Equatable {
  const AppUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => [id, email];
}
