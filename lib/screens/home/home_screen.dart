import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/habit_provider.dart';
import '../../models/habit.dart';
import '../../utils/theme.dart';
import '../../utils/constants.dart';
import '../../utils/helpers.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/weekly_bar_chart.dart';
import '../../widgets/progress_summary.dart';
import '../habit/add_edit_habit_screen.dart';
import '../settings/settings_screen.dart';
import '../habit/habit_detail_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  final String userId;
  const HomeScreen({super.key, required this.userId});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() => _selectedTabIndex = _tabController.index);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncData();
    });
  }

  Future<void> _syncData() async {
    await ref.read(habitsProvider(widget.userId).notifier).syncFromFirestore();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final habitsAsync = ref.watch(habitsProvider(widget.userId));
    final todayHabits = ref.watch(todayHabitsProvider(widget.userId));
    final weeklyData = ref.watch(overallWeeklyDataProvider(widget.userId));

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (ctx, _) => [
            SliverAppBar(
              floating: true,
              snap: true,
              elevation: 0,
              backgroundColor: theme.scaffoldBackgroundColor,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: AppTheme.primary,
                        letterSpacing: -0.5,
                    ),
                  ),
                  Text(
                    DateTime.now().toFormattedDate(),
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                  icon: const Icon(Icons.settings_outlined),
                  tooltip: 'Settings',
                ),
              ],
            ),
          ],
          body: RefreshIndicator(
            onRefresh: _syncData,
            color: AppTheme.primary,
            child: CustomScrollView(
              slivers: [
                // Stats header
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ProgressSummary(
                      userId: widget.userId,
                      todayHabits: todayHabits,
                    ),
                  ),
                ),

                // Weekly chart section
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: WeeklyBarChart(
                      weeklyData: weeklyData,
                      userId: widget.userId,
                    ),
                  ),
                ),

                // Tab bar
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _SliverTabBarDelegate(
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: theme.colorScheme.outline,
                      indicatorColor: AppTheme.primary,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelStyle: const TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      tabs: const [
                        Tab(text: "Today"),
                        Tab(text: "All Habits"),
                      ],
                    ),
                    backgroundColor: theme.scaffoldBackgroundColor,
                  ),
                ),

                // Habit list
                habitsAsync.when(
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (e, _) => SliverFillRemaining(
                    child: Center(child: Text('Error: $e')),
                  ),
                  data: (allHabits) {
                    final habits = _selectedTabIndex == 0 ? todayHabits : allHabits;
                    if (habits.isEmpty) {
                      return SliverFillRemaining(
                        child: _EmptyState(
                          isToday: _selectedTabIndex == 0,
                          onAdd: () => _openAddHabit(context),
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (ctx, i) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: HabitCard(
                                habit: habits[i],
                                userId: widget.userId,
                                onTap: () => _openDetail(habits[i]),
                                onEdit: () => _openEditHabit(habits[i]),
                                onDelete: () => _confirmDelete(habits[i]),
                              ),
                            );
                          },
                          childCount: habits.length,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddHabit(context),
        icon: const Icon(Icons.add),
        label: const Text(
          'New Habit',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _openAddHabit(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddEditHabitScreen(userId: widget.userId),
    );
    if (result == true) {
      ref.read(habitsProvider(widget.userId).notifier).refresh();
    }
  }

  Future<void> _openEditHabit(Habit habit) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => AddEditHabitScreen(userId: widget.userId, habit: habit),
    );
    if (result == true) {
      ref.read(habitsProvider(widget.userId).notifier).refresh();
    }
  }

  void _openDetail(Habit habit) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(habit: habit, userId: widget.userId),
      ),
    );
  }

  Future<void> _confirmDelete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Habit'),
        content: Text('Delete "${habit.title}"? This cannot be undone.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(habitsProvider(widget.userId).notifier).deleteHabit(habit.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${habit.title}" deleted'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  final bool isToday;
  final VoidCallback onAdd;

  const _EmptyState({required this.isToday, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isToday ? '🌅' : '✨',
              style: const TextStyle(fontSize: 64),
            ),
            const SizedBox(height: 16),
            Text(
              isToday ? 'Rest day!' : 'No habits yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              isToday
                  ? 'No habits scheduled for today.\nAdd one to get started!'
                  : 'Create your first habit and start building better routines.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: const Text('Add First Habit'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  const _SliverTabBarDelegate(this.tabBar, {this.backgroundColor = Colors.white});

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: backgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height + 1;

  @override
  double get minExtent => tabBar.preferredSize.height + 1;

  @override
  bool shouldRebuild(covariant _SliverTabBarDelegate oldDelegate) =>
      tabBar != oldDelegate.tabBar;
}
