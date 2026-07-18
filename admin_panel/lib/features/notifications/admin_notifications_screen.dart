import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  List<AdminNotificationItem> _items = const <AdminNotificationItem>[];
  int _unreadCount = 0;
  bool _isLoading = true;
  bool _isMutating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref
          .read(adminApiServiceProvider)
          .fetchNotifications(limit: 80);
      if (!mounted) {
        return;
      }
      setState(() {
        _items = data.notifications;
        _unreadCount = data.unreadCount;
        _isLoading = false;
        _isMutating = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _errorMessage = error.message;
        _isLoading = false;
        _isMutating = false;
      });
    }
  }

  Future<void> _markAllRead() async {
    if (_items.isEmpty || _unreadCount == 0) {
      _showMessage('No unread notifications to mark.');
      return;
    }

    setState(() => _isMutating = true);
    try {
      final updatedCount = await ref
          .read(adminApiServiceProvider)
          .markAllNotificationsRead();
      await _loadNotifications();
      if (mounted) {
        _showMessage('$updatedCount notification(s) marked as read.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isMutating = false);
        _showMessage(error.message);
      }
    }
  }

  Future<void> _clearAll() async {
    if (_items.isEmpty) {
      _showMessage('Notification center is already empty.');
      return;
    }

    setState(() => _isMutating = true);
    try {
      final clearedCount = await ref
          .read(adminApiServiceProvider)
          .clearNotifications();
      await _loadNotifications();
      if (mounted) {
        _showMessage('$clearedCount notification(s) cleared.');
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() => _isMutating = false);
        _showMessage(error.message);
      }
    }
  }

  Future<void> _openNotification(AdminNotificationItem item) async {
    if (!item.isRead && item.id > 0) {
      try {
        final updated = await ref
            .read(adminApiServiceProvider)
            .markNotificationRead(item);
        if (mounted) {
          setState(() {
            _items = [
              for (final current in _items)
                current.id == updated.id ? updated : current,
            ];
            _unreadCount = _items.where((current) => !current.isRead).length;
          });
        }
      } on ApiException catch (error) {
        if (mounted) {
          _showMessage(error.message);
        }
      }
    }

    if (!mounted) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Text(item.message),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AdminLoadingState(message: 'Loading notifications...');
    }

    if (_errorMessage != null) {
      return AdminErrorState(
        title: 'Notifications unavailable',
        message: _errorMessage!,
        onRetry: _loadNotifications,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NotificationHeader(
          totalCount: _items.length,
          unreadCount: _unreadCount,
          isMutating: _isMutating,
          onRefresh: _loadNotifications,
          onMarkAllRead: _markAllRead,
          onClearAll: _clearAll,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_items.isEmpty)
          const AdminEmptyState(
            icon: Icons.notifications_none_rounded,
            title: 'No notifications',
            message:
                'Operational alerts, approvals, assignments, and exceptions will appear here.',
          )
        else
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  for (final item in _items) ...[
                    _NotificationTile(
                      item: item,
                      onTap: () => _openNotification(item),
                    ),
                    if (item != _items.last)
                      const Divider(height: AppSpacing.lg),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _NotificationHeader extends StatelessWidget {
  const _NotificationHeader({
    required this.totalCount,
    required this.unreadCount,
    required this.isMutating,
    required this.onRefresh,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final int totalCount;
  final int unreadCount;
  final bool isMutating;
  final VoidCallback onRefresh;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onRefresh,
                  icon: const Icon(Icons.sync_rounded),
                  label: const Text('Refresh'),
                ),
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onMarkAllRead,
                  icon: const Icon(Icons.done_all_rounded),
                  label: const Text('Mark all read'),
                ),
                OutlinedButton.icon(
                  onPressed: isMutating ? null : onClearAll,
                  icon: const Icon(Icons.clear_all_rounded),
                  label: const Text('Clear all'),
                ),
              ],
            );

            final content = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(
                          AppSpacing.cardRadius,
                        ),
                      ),
                      child: const Icon(
                        Icons.notifications_active_outlined,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Admin notifications',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '$totalCount backend alert(s), $unreadCount unread.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    if (unreadCount > 0)
                      AdminStatusBadge(
                        label: '$unreadCount unread',
                        tone: AdminStatusTone.warning,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            );

            return content;
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.item, required this.onTap});

  final AdminNotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      'booking' || 'booking_confirmed' => Icons.inventory_2_outlined,
      'assignment' || 'driver_assigned' => Icons.assignment_ind_outlined,
      'emergency' => Icons.emergency_outlined,
      'cancelled' => Icons.cancel_outlined,
      'delivered' => Icons.task_alt_rounded,
      _ => Icons.notifications_outlined,
    };
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: item.isRead
            ? AppColors.surfaceMuted
            : AppColors.primaryBlue.withValues(alpha: 0.12),
        child: Icon(icon, color: AppColors.primaryBlue),
      ),
      title: Text(
        item.title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xxs),
        child: Text('${item.message}\n${item.time}'),
      ),
      trailing: AdminStatusBadge.fromStatus(item.status),
    );
  }
}
