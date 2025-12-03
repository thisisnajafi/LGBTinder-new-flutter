import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/admin_provider.dart';
import '../widgets/analytics_card.dart';

/// Admin dashboard screen
/// Main dashboard for administrators with key metrics and system status
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load dashboard data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).loadDashboardData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    final adminNotifier = ref.read(adminProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            onPressed: () => adminNotifier.refreshDashboard(),
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'users':
                  context.go('/admin/users');
                  break;
                case 'analytics':
                  context.go('/admin/analytics');
                  break;
                case 'settings':
                  context.go('/admin/settings');
                  break;
                case 'system':
                  context.go('/admin/system');
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'users',
                child: Text('Manage Users'),
              ),
              const PopupMenuItem(
                value: 'analytics',
                child: Text('Analytics'),
              ),
              const PopupMenuItem(
                value: 'settings',
                child: Text('Settings'),
              ),
              const PopupMenuItem(
                value: 'system',
                child: Text('System'),
              ),
            ],
          ),
        ],
      ),
      body: adminState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => adminNotifier.refreshDashboard(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(),

                    const SizedBox(height: 24),

                    // Analytics Cards
                    if (adminState.analytics != null) ...[
                      _buildAnalyticsSection(adminState.analytics!),
                      const SizedBox(height: 24),
                    ],

                    // System Health
                    if (adminState.systemHealth != null) ...[
                      _buildSystemHealthSection(adminState.systemHealth!),
                      const SizedBox(height: 24),
                    ],

                    // Quick Actions
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // Recent Activity (placeholder)
                    _buildRecentActivity(),
                  ],
                ),
              ),
            ),

      // Error display
      bottomSheet: adminState.error != null
          ? Container(
              padding: const EdgeInsets.all(16),
              color: Colors.red.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.error, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      adminState.error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                  IconButton(
                    onPressed: adminNotifier.clearError,
                    icon: const Icon(Icons.close, color: Colors.red),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back, Admin',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Here\'s what\'s happening with your app today',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsSection(analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        AnalyticsCardsGrid(
          cards: [
            // User metrics
            AnalyticsCard(
              title: 'Total Users',
              value: analytics.totalUsers.toString(),
              icon: Icons.people,
              iconColor: AppColors.primaryLight,
              trend: analytics.userGrowthToday,
            ),

            AnalyticsCard(
              title: 'Active Today',
              value: analytics.activeUsersToday.toString(),
              icon: Icons.access_time,
              iconColor: Colors.green,
            ),

            AnalyticsCard(
              title: 'New Users',
              value: analytics.newUsersToday.toString(),
              icon: Icons.person_add,
              iconColor: Colors.blue,
            ),

            // Engagement metrics
            AnalyticsCard(
              title: 'Total Matches',
              value: analytics.totalMatches.toString(),
              icon: Icons.favorite,
              iconColor: Colors.red,
            ),

            AnalyticsCard(
              title: 'Messages Today',
              value: analytics.messagesToday.toString(),
              icon: Icons.message,
              iconColor: Colors.orange,
            ),

            // Revenue metrics
            AnalyticsCard(
              title: 'Revenue Today',
              value: '\$${analytics.revenueToday.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              iconColor: Colors.green,
              trend: analytics.revenueGrowth,
            ),

            AnalyticsCard(
              title: 'Premium Users',
              value: analytics.premiumUsers.toString(),
              icon: Icons.star,
              iconColor: Colors.amber,
            ),

            // System metrics
            AnalyticsCard(
              title: 'Pending Reports',
              value: analytics.pendingReports.toString(),
              icon: Icons.report_problem,
              iconColor: Colors.red,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSystemHealthSection(systemHealth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getHealthColor(systemHealth.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                systemHealth.status.toUpperCase(),
                style: TextStyle(
                  color: _getHealthColor(systemHealth.status),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Uptime
                _buildHealthMetric(
                  'Uptime',
                  systemHealth.uptimeFormatted,
                  Icons.access_time,
                  Colors.blue,
                ),

                const Divider(height: 24),

                // Resources
                Row(
                  children: [
                    Expanded(
                      child: _buildHealthMetric(
                        'CPU',
                        '${systemHealth.resources.cpuUsage.toStringAsFixed(1)}%',
                        Icons.memory,
                        systemHealth.resources.isCpuHigh ? Colors.red : Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _buildHealthMetric(
                        'Memory',
                        '${systemHealth.resources.memoryUsage.toStringAsFixed(1)}%',
                        Icons.storage,
                        systemHealth.resources.isMemoryHigh ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),

                const Divider(height: 24),

                // Services status
                Row(
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Services',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: systemHealth.services.map<Widget>((service) {
                    return Chip(
                      label: Text(service.name),
                      backgroundColor: service.isRunning
                          ? Colors.green.withOpacity(0.1)
                          : Colors.red.withOpacity(0.1),
                      labelStyle: TextStyle(
                        color: service.isRunning ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthMetric(String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 2.5,
          children: [
            _buildQuickActionButton(
              'Clear Cache',
              Icons.cleaning_services,
              AppColors.primaryLight,
              () => _clearCache(),
            ),
            _buildQuickActionButton(
              'Send Notification',
              Icons.notifications,
              Colors.orange,
              () => _sendNotification(),
            ),
            _buildQuickActionButton(
              'Export Data',
              Icons.download,
              Colors.green,
              () => _exportData(),
            ),
            _buildQuickActionButton(
              'View Reports',
              Icons.report,
              Colors.red,
              () => context.go('/admin/reports'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(String title, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.1),
        foregroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),

        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Placeholder for recent activities
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(Icons.person_add, color: AppColors.primaryLight),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'New user registered',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '2 minutes ago',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => context.go('/admin/activity'),
                  child: const Text('View All Activity'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'healthy':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'critical':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _clearCache() async {
    final adminNotifier = ref.read(adminProvider.notifier);
    final success = await adminNotifier.clearSystemCache();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? 'Cache cleared successfully' : 'Failed to clear cache'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _sendNotification() {
    // Navigate to notification screen
    context.go('/admin/notifications');
  }

  void _exportData() {
    // Navigate to export screen
    context.go('/admin/export');
  }
}
