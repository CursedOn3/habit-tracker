import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/habit_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/habit_card.dart';
import '../../widgets/charts/weekly_bar_chart.dart';
import '../../widgets/charts/monthly_line_chart.dart';
import '../habit/add_edit_habit_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authStateProvider).valueOrNull;

    final pages = [
      const _DashboardTab(),
      const _AllHabitsTab(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.track_changes_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(AppConstants.appName, style: theme.textTheme.headlineMedium),
          ],
        ),
        actions: [
          if (user != null)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  user.email?.substring(0, 1).toUpperCase() ?? 'U',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Dashboard'),
            Tab(text: 'All Habits'),
          ],
          labelStyle: const TextStyle(fontWeight: FontWeight.w600),
          indicatorColor: AppTheme.primaryColor,
          labelColor: AppTheme.primaryColor,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: pages,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const AddEditHabitScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Habit'),
      ),
    );
  }
}

class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitNotifierProvider);
    final weeklyData = ref.watch(weeklyDataProvider);
    final monthlyData = ref.watch(monthlyDataProvider);
    final today = DateTime.now();
    final theme = Theme.of(context);

    if (habitState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (habitState.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppTheme.errorColor),
            const SizedBox(height: 8),
            Text('Error: ${habitState.error}'),
            TextButton(
              onPressed: () => ref.read(habitNotifierProvider.notifier).refreshHabits(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final todaysHabits = ref.watch(todaysHabitsProvider);
    final completedToday = todaysHabits.where((h) => h.isCompletedForDate(today)).length;
    final totalStreak = habitState.habits.fold<int>(
      0,
      (sum, h) => sum + h.currentStreak,
    );

    return RefreshIndicator(
      onRefresh: () => ref.read(habitNotifierProvider.notifier).refreshHabits(),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    _getGreeting(),
                    style: theme.textTheme.headlineLarge,
                  ),
                  Text(
                    DateFormat('EEEE, MMM d').format(today),
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 20),

                  // Stats row
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Done Today',
                          value: '$completedToday/${todaysHabits.length}',
                          color: AppTheme.successColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.local_fire_department_outlined,
                          label: 'Total Streak',
                          value: '$totalStreak',
                          color: AppTheme.warningColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.list_alt_outlined,
                          label: 'Habits',
                          value: '${habitState.habits.length}',
                          color: AppTheme.primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Weekly chart
                  Text("This Week", style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: WeeklyBarChart(data: weeklyData),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Monthly chart
                  Text(
                    DateFormat('MMMM').format(today),
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: MonthlyLineChart(data: monthlyData),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Today's habits
                  Text("Today's Habits", style: theme.textTheme.headlineMedium),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          if (todaysHabits.isEmpty)
            SliverToBoxAdapter(
              child: const _EmptyHabitsView(),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => HabitCard(
                  habit: todaysHabits[index],
                  date: today,
                ),
                childCount: todaysHabits.length,
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return '☀️ Good Morning!';
    if (hour < 17) return '🌤️ Good Afternoon!';
    return '🌙 Good Evening!';
  }
}

class _AllHabitsTab extends ConsumerWidget {
  const _AllHabitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitState = ref.watch(habitNotifierProvider);
    final today = DateTime.now();

    if (habitState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (habitState.habits.isEmpty) {
      return const _EmptyHabitsView();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: habitState.habits.length,
      itemBuilder: (context, index) {
        return HabitCard(habit: habitState.habits[index], date: today);
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _EmptyHabitsView extends StatelessWidget {
  const _EmptyHabitsView();
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.sentiment_satisfied_alt_outlined,
              size: 72,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 16),
            Text(
              'No habits yet!',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to create\nyour first habit.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
