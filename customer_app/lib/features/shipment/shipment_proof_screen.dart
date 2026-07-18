import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/empty_state_widget.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import 'data/customer_shipment_api.dart';

class ShipmentProofScreen extends ConsumerWidget {
  const ShipmentProofScreen({super.key, required this.shipmentId});

  final String shipmentId;

  Future<ShipmentProofListData> _loadProofs(WidgetRef ref) async {
    final api = ref.read(customerShipmentApiProvider);
    final resolvedId = await api.resolveShipmentId(shipmentId);
    return api.listShipmentProofs(shipmentId: resolvedId);
  }

  void _showPlaceholder(BuildContext context, String action, String title) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action is not exposed by the current customer proof API for $title.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<ShipmentProofListData>(
      future: _loadProofs(ref),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return CommonAppScaffold(
          title: 'Proof view',
          subtitle: data == null
              ? 'Loading pickup and delivery proof records.'
              : 'Driver-uploaded proof records for ${data.shipment.shipmentCode}.',
          bottomNavigationIndex: 1,
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Loading shipment proofs');
              }

              if (snapshot.hasError || data == null) {
                return ErrorStateWidget(
                  title: 'Proofs unavailable',
                  message: _errorMessage(snapshot.error),
                );
              }

              if (data.proofs.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _ProofHeader(shipmentCode: data.shipment.shipmentCode),
                    const SizedBox(height: AppSpacing.lg),
                    EmptyStateWidget(
                      icon: Icons.verified_user_outlined,
                      title: data.emptyState?.title ?? 'No proofs uploaded yet',
                      message:
                          data.emptyState?.message ??
                          'Pickup and delivery proofs will appear after driver upload.',
                    ),
                  ],
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProofHeader(shipmentCode: data.shipment.shipmentCode),
                  const SizedBox(height: AppSpacing.lg),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final useTwoColumns = constraints.maxWidth >= 680;

                      if (!useTwoColumns) {
                        return Column(
                          children: [
                            for (final proof in data.proofs) ...[
                              _ProofCard(
                                proof: proof,
                                onDownload: () => _showPlaceholder(
                                  context,
                                  'Download',
                                  _proofTitle(proof),
                                ),
                                onFullScreen: () => context.go(
                                  Uri(
                                    path: AppRoutes.shipmentProofViewer,
                                    queryParameters: {
                                      'shipmentId': shipmentId,
                                      'proofId': proof.id.toString(),
                                    },
                                  ).toString(),
                                ),
                              ),
                              if (proof != data.proofs.last)
                                const SizedBox(height: AppSpacing.md),
                            ],
                          ],
                        );
                      }

                      return Wrap(
                        spacing: AppSpacing.md,
                        runSpacing: AppSpacing.md,
                        children: [
                          for (final proof in data.proofs)
                            SizedBox(
                              width: (constraints.maxWidth - AppSpacing.md) / 2,
                              child: _ProofCard(
                                proof: proof,
                                onDownload: () => _showPlaceholder(
                                  context,
                                  'Download',
                                  _proofTitle(proof),
                                ),
                                onFullScreen: () => context.go(
                                  Uri(
                                    path: AppRoutes.shipmentProofViewer,
                                    queryParameters: {
                                      'shipmentId': shipmentId,
                                      'proofId': proof.id.toString(),
                                    },
                                  ).toString(),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _ProofHeader extends StatelessWidget {
  const _ProofHeader({required this.shipmentCode});

  final String shipmentCode;

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
              Icons.verified_user_rounded,
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
                  shipmentCode,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Driver-uploaded proof documents are shown with verification status.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofCard extends StatelessWidget {
  const _ProofCard({
    required this.proof,
    required this.onDownload,
    required this.onFullScreen,
  });

  final ShipmentProofRecord proof;
  final VoidCallback onDownload;
  final VoidCallback onFullScreen;

  @override
  Widget build(BuildContext context) {
    final accentColor = _proofAccentColor(proof);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(_proofIcon(proof), color: accentColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _proofTitle(proof),
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        proof.fileName ?? proof.proofCode,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                _VerificationBadge(
                  label: _titleCase(proof.verificationStatus),
                  color: proof.verificationStatus == 'verified'
                      ? AppColors.success
                      : AppColors.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            AspectRatio(
              aspectRatio: 16 / 10,
              child: _ProofImagePlaceholder(proof: proof),
            ),
            const SizedBox(height: AppSpacing.md),
            _ProofMetaRow(
              icon: Icons.person_outline_rounded,
              label: 'Uploaded by',
              value: proof.uploadedByDriverName ?? 'Assigned driver',
            ),
            _ProofMetaRow(
              icon: Icons.schedule_rounded,
              label: 'Timestamp',
              value: _formatDateTime(proof.capturedAt ?? proof.createdAt),
            ),
            _ProofMetaRow(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: proof.locationText ?? 'Location not captured',
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              proof.notes?.isNotEmpty ?? false
                  ? proof.notes!
                  : 'Proof metadata is stored by CargoConnect.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onFullScreen,
                    icon: const Icon(Icons.fullscreen_rounded),
                    label: const Text('View full screen'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onDownload,
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofImagePlaceholder extends StatelessWidget {
  const _ProofImagePlaceholder({required this.proof});

  final ShipmentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    final accentColor = _proofAccentColor(proof);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withValues(alpha: 0.16), AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -18,
            child: Icon(
              Icons.image_rounded,
              color: AppColors.textInverse.withValues(alpha: 0.9),
              size: 132,
            ),
          ),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    color: AppColors.surface.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    boxShadow: AppShadows.card,
                  ),
                  child: Icon(_proofIcon(proof), color: accentColor, size: 34),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '${_proofTitle(proof)} image',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.primaryNavy,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  proof.fileUrl.isEmpty
                      ? 'File path pending'
                      : 'Backend file metadata',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofMetaRow extends StatelessWidget {
  const _ProofMetaRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 18),
          const SizedBox(width: AppSpacing.xs),
          SizedBox(
            width: 88,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationBadge extends StatelessWidget {
  const _VerificationBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, color: color, size: 14),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _proofTitle(ShipmentProofRecord proof) {
  return '${_titleCase(proof.proofType)} proof';
}

IconData _proofIcon(ShipmentProofRecord proof) {
  return proof.proofType == 'delivery'
      ? Icons.assignment_turned_in_rounded
      : Icons.inventory_2_rounded;
}

Color _proofAccentColor(ShipmentProofRecord proof) {
  return proof.proofType == 'delivery'
      ? AppColors.accentOrange
      : AppColors.primaryBlue;
}

String _formatDateTime(String? value) {
  final date = DateTime.tryParse(value ?? '');
  if (date == null) {
    return 'Timestamp pending';
  }

  final hour = date.hour > 12 ? date.hour - 12 : date.hour;
  final displayHour = hour == 0 ? 12 : hour;
  final minute = date.minute.toString().padLeft(2, '0');
  final period = date.hour >= 12 ? 'PM' : 'AM';
  return '${date.day}/${date.month}/${date.year}, $displayHour:$minute $period';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _errorMessage(Object? error) {
  if (error is ApiException) {
    return error.message;
  }
  return 'Unable to load proof records.';
}
