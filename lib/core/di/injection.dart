import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:team_workspace/core/di/injection.config.dart';

final GetIt getIt = GetIt.instance;

@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() => getIt.init();
