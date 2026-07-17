import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/di/injection.dart';
import 'package:team_workspace/core/router/app_routes.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/auth/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_bloc.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_event.dart';
import 'package:team_workspace/features/tasks/presentation/bloc/task_list_state.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/task_card.dart';
import 'package:team_workspace/features/tasks/presentation/widgets/task_search_filter_bar.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthSignOutRequested()),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.createTask),
        child: const Icon(Icons.add),
      ),
      body: BlocBuilder<TaskListBloc, TaskListState>(
        builder: (context, state) {
          return switch (state) {
            TaskListLoading() => const Center(
              child: CircularProgressIndicator(),
            ),
            TaskListLoadFailure(:final message) => _ErrorView(
              message: message,
              onRetry: () =>
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

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
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

  @override
  Widget build(BuildContext context) {
    if (state.tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.checklist,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 12),
              const Text('No tasks yet'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.push(AppRoutes.createTask),
                child: const Text('Create a task'),
              ),
            ],
          ),
        ),
      );
    }

    final filteredTasks = state.filteredTasks;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<TaskListBloc>().add(const TaskListRefreshRequested());
        await context.read<TaskListBloc>().stream.firstWhere(
          (s) => s is! TaskListLoading,
        );
      },
      child: Column(
        children: [
          if (state.isFromCache) const _CachedDataBanner(),
          TaskSearchFilterBar(state: state),
          if (filteredTasks.isEmpty)
            const Expanded(child: _NoResultsView())
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
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

class _NoResultsView extends StatelessWidget {
  const _NoResultsView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 48,
              color: Theme.of(context).colorScheme.outline,
            ),
            const SizedBox(height: 12),
            const Text('No tasks match your search or filters'),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<TaskListBloc>().add(
                const TaskListFiltersCleared(),
              ),
              child: const Text('Clear all filters'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CachedDataBanner extends StatelessWidget {
  const _CachedDataBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(
            Icons.cloud_off,
            size: 16,
            color: Theme.of(context).colorScheme.outline,
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
