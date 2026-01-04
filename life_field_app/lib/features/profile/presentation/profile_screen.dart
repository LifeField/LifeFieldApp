import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../auth/application/auth_notifier.dart';
import '../../../app/router/route_paths.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profilo'),
      ),
      body: SafeArea(
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: ProfileContent(),
        ),
      ),
    );
  }
}

class ProfileContent extends ConsumerWidget {
  const ProfileContent({super.key, this.onNavigateWorkouts});

  final VoidCallback? onNavigateWorkouts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    final email = authState.user?.email ?? 'Utente';
    final role = authState.user?.role.name ?? 'Cliente';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                child: Text(
                  email.isNotEmpty ? email[0].toUpperCase() : '?',
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    email,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    role,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => ref.read(authNotifierProvider.notifier).logout(),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.fitness_center_outlined),
              title: const Text('Allenamenti'),
              subtitle: const Text('Gestisci le tue schede'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: onNavigateWorkouts ??
                  () {
                    context.pushNamed(RoutePaths.workoutName);
                  },
            ),
          ),
        ],
      ),
    );
  }
}
