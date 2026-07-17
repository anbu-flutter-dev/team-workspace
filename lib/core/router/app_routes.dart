class AppRoutes {
  AppRoutes._();

  static const String splash = '/splash';
  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String dashboard = '/dashboard';
  static const String taskDetail = '/tasks/:taskId';
  static const String createTask = '/tasks/new';
  static const String editTask = '/tasks/:taskId/edit';

  static String taskDetailPath(String id) => '/tasks/$id';
  static String editTaskPath(String id) => '/tasks/$id/edit';
}
