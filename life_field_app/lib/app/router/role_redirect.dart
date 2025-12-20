import '../../features/auth/domain/entities/role.dart';
import 'route_paths.dart';

String roleToHomeRoute(Role role) {
  switch (role) {
    case Role.client:
      return RoutePaths.clientHome;
    case Role.admin:
      return RoutePaths.adminHome;
    case Role.ptCoach:
    case Role.nutrizionista:
    case Role.dietista:
    case Role.biologo:
    case Role.medico:
      return RoutePaths.proHome;
  }
}
