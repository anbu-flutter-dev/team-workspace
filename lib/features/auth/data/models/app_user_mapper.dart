import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:team_workspace/features/auth/domain/entities/app_user.dart';

extension AppUserMapper on firebase.User {
  AppUser toEntity() => AppUser(id: uid, email: email ?? '');
}
