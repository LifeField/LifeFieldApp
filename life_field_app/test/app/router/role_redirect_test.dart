import 'package:flutter_test/flutter_test.dart';

import 'package:life_field_app/app/router/role_redirect.dart';
import 'package:life_field_app/app/router/route_paths.dart';
import 'package:life_field_app/features/auth/domain/entities/role.dart';

void main() {
  group('roleToHomeRoute', () {
    test('maps client to client home', () {
      expect(roleToHomeRoute(Role.client), RoutePaths.clientHome);
    });

    test('maps admin to admin home', () {
      expect(roleToHomeRoute(Role.admin), RoutePaths.adminHome);
    });

    test('maps professional roles to pro home', () {
      final proRoles = [
        Role.ptCoach,
        Role.nutrizionista,
        Role.dietista,
        Role.biologo,
        Role.medico,
      ];

      for (final role in proRoles) {
        expect(roleToHomeRoute(role), RoutePaths.proHome);
      }
    });
  });
}
