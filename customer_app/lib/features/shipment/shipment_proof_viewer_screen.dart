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

class ShipmentProofViewerScreen extends ConsumerWidget {
  const ShipmentProofViewerScreen({
    super.key,
    required this.shipmentId,
    this.proofId,
  });

  final String shipmentId;
  final int? proofId;

  Future<_ProofViewerData> _loadProof(WidgetRef ref) async {
    final api = ref.read(customerShipmentApiProvider);
    final resolvedId = await api.resolveShipmentId(shipmentId);
    if (proofId != null) {
      final detail = await api.getShipmentProof(
        shipmentId: resolvedId,
        proofId: proofId!,
      );
      return _ProofViewerData(
        shipmentCode: detail.shipment.shipmentCode,
        proof: detail.proof,
        downloadUrl: detail.actions.downloadUrl,
      );
    }

    final data = await api.listShipmentProofs(shipmentId: resolvedId);
    final proof = data.proofs.isEmpty ? null : data.proofs.first;

    return _ProofViewerData(
      shipmentCode: data.shipment.shipmentCode,
      proof: proof,
      downloadUrl: proof?.fileUrl,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<_ProofViewerData>(
      future: _loadProof(ref),
      builder: (context, snapshot) {
        final data = snapshot.data;

        return CommonAppScaffold(
          title: 'Proof preview',
          subtitle: data?.proof == null
              ? 'Loading proof preview.'
              : '${_proofTitle(data!.proof!)} for ${data.shipmentCode}.',
          bottomNavigationIndex: 1,
          actions: [
            IconButton(
              tooltip: 'Back to proof list',
              onPressed: () => context.go(
                Uri(
                  path: AppRoutes.shipmentProof,
                  queryParameters: {'shipmentId': shipmentId},
                ).toString(),
              ),
              icon: const Icon(Icons.list_alt_rounded),
            ),
          ],
          body: Builder(
            builder: (context) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(message: 'Opening proof preview');
              }

              if (snapshot.hasError || data == null) {
                return ErrorStateWidget(
                  title: 'Proof preview unavailable',
                  message: _errorMessage(snapshot.error),
                  onRetry: () => context.go(
                    Uri(
                      path: AppRoutes.shipmentProof,
                      queryParameters: {'shipmentId': shipmentId},
                    ).toString(),
                  ),
                );
              }

              final proof = data.proof;
              if (proof == null) {
                return EmptyStateWidget(
                  icon: Icons.image_not_supported_outlined,
                  title: 'No proof file to preview',
                  message:
                      'Pickup and delivery proof previews will appear after the driver uploads them for ${data.shipmentCode}.',
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProofPreviewHero(
                    shipmentCode: data.shipmentCode,
                    proof: proof,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  AspectRatio(
                    aspectRatio: 4 / 3,
                    child: _ProofCanvas(proof: proof),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _ProofMetaCard(proof: proof),
                  const SizedBox(height: AppSpacing.lg),
                  ElevatedButton.icon(
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          data.downloadUrl?.isNotEmpty == true
                              ? 'Proof download is available from backend path ${data.downloadUrl}.'
                              : 'Proof download is not exposed by the current customer API.',
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Download proof'),
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

class _ProofPreviewHero extends StatelessWidget {
  const _ProofPreviewHero({required this.shipmentCode, required this.proof});

  final String shipmentCode;
  final ShipmentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    final color = _proofAccentColor(proof);

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
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Icon(_proofIcon(proof), color: AppColors.roadYellow),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _proofTitle(proof),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$shipmentCode - ${proof.fileName ?? proof.proofCode}',
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

class _ProofCanvas extends StatelessWidget {
  const _ProofCanvas({required this.proof});

  final ShipmentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    final color = _proofAccentColor(proof);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.18), AppColors.surfaceMuted],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_proofIcon(proof), size: 72, color: color),
            const SizedBox(height: AppSpacing.md),
            Text(
              proof.fileUrl.isEmpty
                  ? 'Preview placeholder'
                  : 'Stored proof file',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.primaryNavy,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              proof.fileUrl.isEmpty ? 'File path pending' : proof.fileUrl,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProofMetaCard extends StatelessWidget {
  const _ProofMetaCard({required this.proof});

  final ShipmentProofRecord proof;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProofMetaRow(
              icon: Icons.verified_rounded,
              label: 'Verification',
              value: _titleCase(proof.verificationStatus),
            ),
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
          ],
        ),
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
          Icon(icon, color: AppColors.primaryBlue, size: 18),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 104,
            child: Text(label, style: Theme.of(context).textTheme.labelMedium),
          ),
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

class _ProofViewerData {
  const _ProofViewerData({
    required this.shipmentCode,
    required this.proof,
    required this.downloadUrl,
  });

  final String shipmentCode;
  final ShipmentProofRecord? proof;
  final String? downloadUrl;
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
  return 'Unable to open proof preview.';
}
