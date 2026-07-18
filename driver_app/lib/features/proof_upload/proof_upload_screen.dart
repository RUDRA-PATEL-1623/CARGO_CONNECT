import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/utils/mock_driver_data.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/trip_card.dart';
import '../trips/data/driver_trip_api.dart';

class ProofUploadScreen extends ConsumerStatefulWidget {
  const ProofUploadScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<ProofUploadScreen> createState() => _ProofUploadScreenState();
}

class _ProofUploadScreenState extends ConsumerState<ProofUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();
  final Set<_PickupConditionItem> _checkedConditions = {};

  DriverTripMock? _trip;
  int? _assignmentId;
  Uint8List? _selectedPhotoBytes;
  String? _selectedPhotoName;
  bool _isSubmitting = false;
  bool _isPickupCompleted = false;
  var _isLoading = true;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);
  final _imagePicker = ImagePicker();

  bool get _isChecklistComplete {
    return _checkedConditions.length == _pickupConditions.length;
  }

  bool get _canSubmit {
    return _selectedPhotoBytes != null &&
        _isChecklistComplete &&
        !_isSubmitting &&
        !_isPickupCompleted;
  }

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  String? _validateNotes(String? value) {
    final input = value?.trim() ?? '';
    if (input.length > 220) {
      return 'Notes must be 220 characters or fewer';
    }
    return null;
  }

  Future<void> _loadTrip() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final details = await _api.resolveTripDetails(widget.shipmentId);
      if (!mounted) {
        return;
      }
      setState(() {
        _trip = details.trip.toTripCardModel();
        _assignmentId = details.trip.id;
        _isPickupCompleted = [
          'pickup_completed',
          'in_transit',
          'delivered',
          'completed',
        ].contains(details.trip.assignmentStatus);
        _isLoading = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _errorMessage = error.message;
      });
    }
  }

  Future<void> _selectPhoto() async {
    try {
      final photo = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 82,
      );
      if (photo == null || !mounted) {
        return;
      }
      final bytes = await photo.readAsBytes();
      if (!mounted) {
        return;
      }
      final fileName = _xFileName(photo);
      setState(() {
        _selectedPhotoBytes = bytes;
        _selectedPhotoName = fileName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$fileName selected.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open image picker. Check app permissions.'),
        ),
      );
    }
  }

  void _removePhoto() {
    setState(() {
      _selectedPhotoBytes = null;
      _selectedPhotoName = null;
    });
  }

  void _toggleCondition(_PickupConditionItem item, bool? value) {
    setState(() {
      if (value ?? false) {
        _checkedConditions.add(item);
      } else {
        _checkedConditions.remove(item);
      }
    });
  }

  Future<void> _submitProof() async {
    FocusScope.of(context).unfocus();
    final assignmentId = _assignmentId;
    final trip = _trip;
    final photoBytes = _selectedPhotoBytes;
    final photoName = _selectedPhotoName;
    if (!_canSubmit ||
        !_formKey.currentState!.validate() ||
        assignmentId == null ||
        trip == null ||
        photoBytes == null ||
        photoName == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.uploadPickupProof(
        assignmentId: assignmentId,
        fileBytes: photoBytes,
        fileName: photoName,
        notes: _notesController.text,
        locationText: trip.pickup,
      );
      await _api.markPickupCompleted(
        assignmentId,
        notes: 'Pickup proof submitted from driver app.',
        locationText: trip.pickup,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isPickupCompleted = true;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Pickup proof submitted.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _openInTransitUpdate() {
    final trip = _trip;
    final assignmentId = _assignmentId;
    if (trip == null || assignmentId == null) {
      return;
    }
    context.go(
      Uri(
        path: AppRoutes.inTransitUpdate,
        queryParameters: {
          'assignmentId': assignmentId.toString(),
          'shipmentId': trip.id,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final statusLabel = _isPickupCompleted
        ? 'Pickup Completed'
        : 'Proof Pending';
    final statusTone = _isPickupCompleted
        ? StatusBadgeTone.pickup
        : StatusBadgeTone.warning;

    return CommonAppScaffold(
      title: 'Pickup proof',
      subtitle: 'Submit mandatory pickup proof before continuing the trip.',
      bottomNavigationIndex: 1,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const LoadingWidget(message: 'Loading pickup proof trip')
            else if (_errorMessage != null)
              ErrorStateWidget(
                title: 'Could not load pickup proof',
                message: _errorMessage!,
                onRetry: _loadTrip,
              )
            else if (trip != null) ...[
              _ProofHeader(statusLabel: statusLabel, statusTone: statusTone),
              const SizedBox(height: AppSpacing.lg),
              TripCard(trip: trip),
              const SizedBox(height: AppSpacing.lg),
              _PhotoUploadCard(
                selectedPhotoBytes: _selectedPhotoBytes,
                selectedPhotoName: _selectedPhotoName,
                isLocked: _isPickupCompleted || _isSubmitting,
                onSelectPhoto: _selectPhoto,
                onRemovePhoto: _removePhoto,
              ),
              const SizedBox(height: AppSpacing.lg),
              _PickupConditionChecklist(
                checkedConditions: _checkedConditions,
                isLocked: _isPickupCompleted || _isSubmitting,
                onChanged: _toggleCondition,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TimestampLocationCard(
                trip: trip,
                isPickupCompleted: _isPickupCompleted,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _notesController,
                enabled: !_isPickupCompleted && !_isSubmitting,
                maxLines: 4,
                maxLength: 220,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Pickup notes',
                  hintText:
                      'Add package condition, gate pass, or loading notes',
                  prefixIcon: Icon(Icons.notes_rounded),
                  alignLabelWithHint: true,
                ),
                validator: _validateNotes,
              ),
              const SizedBox(height: AppSpacing.md),
              ElevatedButton.icon(
                onPressed: _canSubmit ? _submitProof : null,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textInverse,
                        ),
                      )
                    : Icon(
                        _isPickupCompleted
                            ? Icons.check_rounded
                            : Icons.cloud_upload_rounded,
                      ),
                label: Text(
                  _isPickupCompleted
                      ? 'Pickup completed'
                      : _isSubmitting
                      ? 'Submitting proof...'
                      : _canSubmit
                      ? 'Submit pickup proof'
                      : 'Complete mandatory proof',
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _isPickupCompleted
                    ? Padding(
                        key: const ValueKey('continue-in-transit'),
                        padding: const EdgeInsets.only(top: AppSpacing.md),
                        child: _ContinueTripCta(
                          shipmentId: trip.id,
                          onPressed: _openInTransitUpdate,
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-continue')),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProofHeader extends StatelessWidget {
  const _ProofHeader({required this.statusLabel, required this.statusTone});

  final String statusLabel;
  final StatusBadgeTone statusTone;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.add_photo_alternate_rounded,
              color: AppColors.roadYellow,
              size: 34,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pickup proof upload',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Photo, checklist, timestamp, and location metadata are sent to dispatch.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.surfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: statusLabel, tone: statusTone),
        ],
      ),
    );
  }
}

class _ContinueTripCta extends StatelessWidget {
  const _ContinueTripCta({required this.shipmentId, required this.onPressed});

  final String shipmentId;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              ),
              child: const Icon(
                Icons.near_me_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Move to in-transit updates',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Pickup proof is complete for $shipmentId.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Continue trip',
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoUploadCard extends StatelessWidget {
  const _PhotoUploadCard({
    required this.selectedPhotoBytes,
    required this.selectedPhotoName,
    required this.isLocked,
    required this.onSelectPhoto,
    required this.onRemovePhoto,
  });

  final Uint8List? selectedPhotoBytes;
  final String? selectedPhotoName;
  final bool isLocked;
  final VoidCallback onSelectPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final hasSelectedPhoto = selectedPhotoBytes != null;
                return Row(
                  children: [
                    const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.primaryBlue,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Mandatory pickup photo',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    StatusBadge(
                      label: hasSelectedPhoto ? 'Selected' : 'Required',
                      tone: hasSelectedPhoto
                          ? StatusBadgeTone.completed
                          : StatusBadgeTone.warning,
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Builder(
              builder: (context) {
                final hasSelectedPhoto = selectedPhotoBytes != null;
                return Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: hasSelectedPhoto
                        ? AppColors.primaryBlue.withValues(alpha: 0.08)
                        : AppColors.surfaceMuted,
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                    border: Border.all(
                      color: hasSelectedPhoto
                          ? AppColors.primaryBlue.withValues(alpha: 0.35)
                          : AppColors.border,
                    ),
                  ),
                  child: hasSelectedPhoto
                      ? _SelectedPhotoPreview(
                          bytes: selectedPhotoBytes!,
                          fileName: selectedPhotoName ?? 'Selected photo',
                        )
                      : const _EmptyPhotoPlaceholder(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final hasSelectedPhoto = selectedPhotoBytes != null;
                      return ElevatedButton.icon(
                        onPressed: isLocked ? null : onSelectPhoto,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: Text(
                          hasSelectedPhoto ? 'Replace photo' : 'Select photo',
                        ),
                      );
                    },
                  ),
                ),
                if (selectedPhotoBytes != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  IconButton(
                    tooltip: 'Remove photo',
                    onPressed: isLocked ? null : onRemovePhoto,
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPhotoPlaceholder extends StatelessWidget {
  const _EmptyPhotoPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.add_a_photo_outlined,
          size: 42,
          color: AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'No pickup photo selected',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Choose a JPG, PNG, or WEBP image.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SelectedPhotoPreview extends StatelessWidget {
  const _SelectedPhotoPreview({required this.bytes, required this.fileName});

  final Uint8List bytes;
  final String fileName;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            child: Image.memory(bytes, fit: BoxFit.cover),
          ),
        ),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.success,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  fileName,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _fileName(String path) {
  final parts = path.split(RegExp(r'[\\/]+'));
  return parts.isEmpty || parts.last.isEmpty ? 'Selected photo' : parts.last;
}

String _xFileName(XFile file) {
  final name = file.name.trim();
  if (name.isNotEmpty) {
    return name;
  }
  return _fileName(file.path);
}

class _PickupConditionChecklist extends StatelessWidget {
  const _PickupConditionChecklist({
    required this.checkedConditions,
    required this.isLocked,
    required this.onChanged,
  });

  final Set<_PickupConditionItem> checkedConditions;
  final bool isLocked;
  final void Function(_PickupConditionItem item, bool? value) onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.fact_check_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Pickup condition checklist',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${checkedConditions.length}/${_pickupConditions.length}',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Confirm every mandatory condition before pickup completion.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final item in _pickupConditions)
              CheckboxListTile(
                value: checkedConditions.contains(item),
                onChanged: isLocked ? null : (value) => onChanged(item, value),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(item.title),
                subtitle: Text(item.subtitle),
              ),
          ],
        ),
      ),
    );
  }
}

class _TimestampLocationCard extends StatelessWidget {
  const _TimestampLocationCard({
    required this.trip,
    required this.isPickupCompleted,
  });

  final DriverTripMock trip;
  final bool isPickupCompleted;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 560;
            final timestamp = _InfoTile(
              icon: Icons.schedule_rounded,
              label: isPickupCompleted ? 'Submitted timestamp' : 'Timestamp',
              value: 'Apr 28, 2026, 11:45 AM IST',
            );
            final location = _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: '${trip.pickup} - GPS pending',
            );

            if (isWide) {
              return Row(
                children: [
                  Expanded(child: timestamp),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: location),
                ],
              );
            }

            return Column(
              children: [
                timestamp,
                const SizedBox(height: AppSpacing.md),
                location,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primaryBlue),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: AppSpacing.xxs),
              Text(value, style: Theme.of(context).textTheme.bodyLarge),
            ],
          ),
        ),
      ],
    );
  }
}

class _PickupConditionItem {
  const _PickupConditionItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}

const _pickupConditions = [
  _PickupConditionItem(
    title: 'Package count matches manifest',
    subtitle: 'Cartons and labels match the assigned shipment.',
  ),
  _PickupConditionItem(
    title: 'Packaging is intact',
    subtitle: 'No visible tears, leakage, or crushed edges at pickup.',
  ),
  _PickupConditionItem(
    title: 'Loading area verified',
    subtitle: 'Pickup dock and vehicle loading position are confirmed.',
  ),
  _PickupConditionItem(
    title: 'Sender handover acknowledged',
    subtitle: 'Warehouse or sender contact has released the shipment.',
  ),
];
