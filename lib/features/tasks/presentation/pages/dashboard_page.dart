import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/router/app_routes.dart';
import 'package:team_workspace/core/theme/theme_cubit.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/task_card.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/task_search_filter_bar.dart';

enum _DashboardMenuAction { themeLight, themeDark, themeSystem, logout }

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<TaskListBloc>()..add(const TaskListStarted()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatefulWidget {
  const _DashboardView();

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 200;
    if (_scrollController.position.pixels >= threshold) {
      context.read<TaskListBloc>().add(const TaskListNextPageRequested());
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleMenuAction(BuildContext context, _DashboardMenuAction action) {
    switch (action) {
      case _DashboardMenuAction.themeLight:
        context.read<ThemeCubit>().setThemeMode(ThemeMode.light);
      case _DashboardMenuAction.themeDark:
        context.read<ThemeCubit>().setThemeMode(ThemeMode.dark);
      case _DashboardMenuAction.themeSystem:
        context.read<ThemeCubit>().setThemeMode(ThemeMode.system);
      case _DashboardMenuAction.logout:
        _confirmLogout(context);
    }
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          "You'll need to sign in again to access your tasks.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(
              'Log out',
              style: TextStyle(
                color: Theme.of(dialogContext).colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const AuthSignOutRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (context, themeMode) {
              return PopupMenuButton<_DashboardMenuAction>(
                icon: const Icon(Icons.more_vert_rounded),
                tooltip: 'More options',
                onSelected: (action) => _handleMenuAction(context, action),
                itemBuilder: (context) => [
                  const PopupMenuItem(enabled: false, child: Text('Theme')),
                  CheckedPopupMenuItem(
                    value: _DashboardMenuAction.themeLight,
                    checked: themeMode == ThemeMode.light,
                    child: const Text('Light'),
                  ),
                  CheckedPopupMenuItem(
                    value: _DashboardMenuAction.themeDark,
                    checked: themeMode == ThemeMode.dark,
                    child: const Text('Dark'),
                  ),
                  CheckedPopupMenuItem(
                    value: _DashboardMenuAction.themeSystem,
                    checked: themeMode == ThemeMode.system,
                    child: const Text('System'),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: _DashboardMenuAction.logout,
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.logout_rounded,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      title: Text(
                        'Log out',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.createTask),
        icon: const Icon(Icons.add),
        label: const Text('New task'),
      ),
      body: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          return switch (state) {
            TaskListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TaskListLoadFailure(:final message) => _StateMessage(
              icon: Icons.error_outline_rounded,
              iconColor: Theme.of(context).colorScheme.error,
              message: message,
              actionLabel: 'Retry',
              onAction: () =>
                  context.read<TaskListBloc>().add(const TaskListStarted()),
            ),
            TaskListLoadSuccess() => _TaskListView(
              state: state,
              scrollController: _scrollController,
            ),
          };
        },
      ),
    );
  }
}

/// Shared centered icon-badge layout for empty/error/no-results states.
/// The action (when there is one) is always the primary CTA for that state,
/// so it's always a filled button, never a text link.
class _StateMessage extends StatelessWidget {
  const _StateMessage({
    required this.icon,
    required this.message,
    this.iconColor,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final Color? iconColor;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: (iconColor ?? colorScheme.outline).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 30,
                color: iconColor ?? colorScheme.outline,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskListView extends StatelessWidget {
  const _TaskListView({required this.state, required this.scrollController});

  final TaskListLoadSuccess state;
  final ScrollController scrollController;

  Future<void> _onRefresh(BuildContext context) {
    return context.read<TaskListBloc>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    if (state.tasks.isEmpty) {
      return RefreshIndicator(
        onRefresh: () => _onRefresh(context),
        child: _PullableEmptyState(
          child: _StateMessage(
            icon: Icons.checklist_rounded,
            message: 'No tasks yet',
            actionLabel: 'Create a task',
            onAction: () => context.push(AppRoutes.createTask),
          ),
        ),
      );
    }

    final filteredTasks = state.filteredTasks;

    return RefreshIndicator(
      onRefresh: () => _onRefresh(context),
      child: Column(
        children: [
          if (state.isFromCache) const _CachedDataBanner(),
          TaskSearchFilterBar(state: state),
          if (filteredTasks.isEmpty)
            Expanded(
              child: _PullableEmptyState(
                child: _StateMessage(
                  icon: Icons.search_off_rounded,
                  message: 'No tasks match your search or filters',
                  actionLabel: 'Clear all filters',
                  onAction: () => context.read<TaskListBloc>().add(
                    const TaskListFiltersCleared(),
                  ),
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 88),
                itemCount:
                    filteredTasks.length +
                    (state.hasMore || state.paginationError != null ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filteredTasks.length) {
                    return _PaginationFooter(state: state);
                  }
                  final task = filteredTasks[index];
                  return TaskCard(
                    task: task,
                    onTap: () =>
                        context.push(AppRoutes.taskDetailPath(task.id)),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

/// Makes a non-scrolling empty/error message pullable: RefreshIndicator only
/// fires from a Scrollable's overscroll, and a message that fits on screen
/// with no ListView underneath it never produces one on its own.
class _PullableEmptyState extends StatelessWidget {
  const _PullableEmptyState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _CachedDataBanner extends StatelessWidget {
  const _CachedDataBanner();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: colorScheme.tertiaryContainer.withValues(alpha: 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Showing cached data',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({required this.state});

  final TaskListLoadSuccess state;

  @override
  Widget build(BuildContext context) {
    if (state.paginationError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Text(state.paginationError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.read<TaskListBloc>().add(
                const TaskListNextPageRequested(),
              ),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
    );
  }
}
