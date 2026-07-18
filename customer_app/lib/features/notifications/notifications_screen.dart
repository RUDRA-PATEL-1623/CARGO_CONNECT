import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import 'data/customer_notifications_api.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  var _notifications = <CustomerNotification>[];
  int _unreadCount = 0;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isMutating = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_loadNotifications);
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await ref
          .read(customerNotificationsApiProvider)
          .listNotifications();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = data.notifications;
        _unreadCount = data.unreadCount;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setError(error.message);
    } catch (_) {
      _setError('Unable to load notifications.');
    }
  }

  Future<void> _clearAll() async {
    if (_isMutating || _notifications.isEmpty) {
      return;
    }

    setState(() => _isMutating = true);
    try {
      await ref.read(customerNotificationsApiProvider).clearAll();
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = const [];
        _unreadCount = 0;
        _isMutating = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Notifications cleared.')));
    } on ApiException catch (error) {
      _showMutationError(error.message);
    } catch (_) {
      _showMutationError('Unable to clear notifications.');
    }
  }

  Future<void> _markRead(CustomerNotification notification) async {
    if (notification.isRead) {
      return;
    }

    try {
      final updated = await ref
          .read(customerNotificationsApiProvider)
          .markRead(notification.id);
      if (!mounted) {
        return;
      }
      setState(() {
        _notifications = [
          for (final item in _notifications)
            if (item.id == updated.id) updated else item,
        ];
        _unreadCount = (_unreadCount - 1).clamp(0, _notifications.length);
      });
    } on ApiException catch (error) {
      _showMutationError(error.message);
    } catch (_) {
      _showMutationError('Unable to mark notification as read.');
    }
  }

  void _setError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _isMutating = false;
      _errorMessage = message;
    });
  }

  void _showMutationError(String message) {
    if (!mounted) {
      return;
    }
    setState(() => _isMutating = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Notifications',
      subtitle: 'Alerts for bookings, shipments, and support updates.',
      actions: [
        TextButton(
          onPressed: _notifications.isEmpty || _isMutating ? null : _clearAll,
          child: Text(_isMutating ? 'Clearing...' : 'Clear all'),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _NotificationSummary(
            totalCount: _notifications.length,
            unreadCount: _unreadCount,
            onClearAll: _notifications.isEmpty || _isMutating
                ? null
                : _clearAll,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (_isLoading)
            const LoadingWidget(message: 'Loading notifications')
          else if (_errorMessage != null)
            ErrorStateWidget(
              title: 'Notifications unavailable',
              message: _errorMessage!,
              onRetry: _loadNotifications,
            )
          else if (_notifications.isEmpty)
            EmptyStateWidget(
              icon: Icons.notifications_off_outlined,
              title: 'No notifications',
              message:
                  'Booking, assignment, delivery, and support alerts will appear here.',
              action: OutlinedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            )
          else
            for (final notification in _notifications) ...[
              _NotificationCard(
                notification: notification,
                onTap: () => _markRead(notification),
              ),
              if (notification != _notifications.last)
                const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({
    required this.totalCount,
    required this.unreadCount,
    required this.onClearAll,
  });

  final int totalCount;
  final int unreadCount;
  final VoidCallback? onClearAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.roadYellow,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$unreadCount unread alerts',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$totalCount total notifications',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Clear all',
            onPressed: onClearAll,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.textInverse.withValues(alpha: 0.1),
              foregroundColor: AppColors.textInverse,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
            ),
            icon: const Icon(Icons.clear_all_rounded),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.notification, required this.onTap});

  final CustomerNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = _colorForType(notification.notificationType);
    final background = !notification.isRead
        ? color.withValues(alpha: 0.08)
        : AppColors.surface;
    final borderColor = !notification.isRead
        ? color.withValues(alpha: 0.28)
        : AppColors.border;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: borderColor,
          width: !notification.isRead ? 1.4 : 1,
        ),
        boxShadow: !notification.isRead ? AppShadows.focused : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.cardRadius,
                      ),
                    ),
                    child: Icon(
                      _iconForType(notification.notificationType),
                      color: color,
                    ),
                  ),
                  if (!notification.isRead)
                    Positioned(
                      right: -2,
                      top: -2,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: AppColors.surface,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: !notification.isRead
                                      ? FontWeight.w900
                                      : FontWeight.w700,
                                ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          _formatDateTime(
                            notification.sentAt ?? notification.createdAt,
                          ),
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _CategoryBadge(
                      label: _categoryForType(notification.notificationType),
                      color: color,
                      isUnread: !notification.isRead,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      notification.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: !notification.isRead
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: !notification.isRead
                            ? FontWeight.w600
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Icon(
                          !notification.isRead
                              ? Icons.markunread_rounded
                              : Icons.drafts_outlined,
                          size: 16,
                          color: !notification.isRead
                              ? color
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          !notification.isRead ? 'Unread' : 'Read',
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: !notification.isRead
                                    ? color
                                    : AppColors.textSecondary,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        if (notification.shipmentCode != null) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            notification.shipmentCode!,
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBadge extends StatelessWidget {
  const _CategoryBadge({
    required this.label,
    required this.color,
    required this.isUnread,
  });

  final String label;
  final Color color;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUnread ? 0.12 : 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

IconData _iconForType(String type) {
  return switch (type) {
    'booking_confirmed' => Icons.assignment_turned_in_outlined,
    'driver_assigned' => Icons.person_pin_circle_outlined,
    'shipment_started' || 'in_transit' => Icons.local_shipping_outlined,
    'delivered' => Icons.done_all_rounded,
    'cancelled' => Icons.cancel_outlined,
    'emergency_reported' => Icons.warning_amber_rounded,
    _ => Icons.notifications_none_rounded,
  };
}

Color _colorForType(String type) {
  return switch (type) {
    'booking_confirmed' || 'delivered' => AppColors.success,
    'driver_assigned' => AppColors.primaryBlue,
    'shipment_started' || 'in_transit' => AppColors.info,
    'cancelled' || 'driver_rejected' => AppColors.danger,
    'emergency_reported' => AppColors.warning,
    _ => AppColors.accentOrange,
  };
}

String _categoryForType(String type) {
  return type
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) {
    return '';
  }

  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inMinutes >= 0 && difference.inMinutes < 60) {
    return '${difference.inMinutes.clamp(1, 59)} min ago';
  }
  if (difference.inHours >= 0 && difference.inHours < 24) {
    return '${difference.inHours} hr ago';
  }
  return '${date.day}/${date.month}/${date.year}';
}
