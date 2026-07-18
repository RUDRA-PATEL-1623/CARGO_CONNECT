import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../../core/widgets/status_badge.dart';
import '../trips/data/driver_trip_api.dart';
import '../trips/data/driver_trip_models.dart';

class DeliveryProofScreen extends ConsumerStatefulWidget {
  const DeliveryProofScreen({super.key, required this.shipmentId});

  final String shipmentId;

  @override
  ConsumerState<DeliveryProofScreen> createState() =>
      _DeliveryProofScreenState();
}

class _DeliveryProofScreenState extends ConsumerState<DeliveryProofScreen> {
  final _formKey = GlobalKey<FormState>();
  final _receiverNameController = TextEditingController();
  final _otpController = TextEditingController();
  final _notesController = TextEditingController();

  _DeliveryProofTripInfo? _trip;
  var _selectedVerification = _ReceiverVerification.otp;
  Uint8List? _deliveryPhotoBytes;
  String? _deliveryPhotoName;
  bool _hasSignature = false;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  var _isLoading = true;
  String? _errorMessage;

  DriverTripApi get _api => ref.read(driverTripApiProvider);
  final _imagePicker = ImagePicker();

  bool get _hasReceiverProof {
    return switch (_selectedVerification) {
      _ReceiverVerification.otp => _otpController.text.trim().length == 6,
      _ReceiverVerification.signature => _hasSignature,
    };
  }

  bool get _canSubmit =>
      _deliveryPhotoBytes != null &&
      _hasReceiverProof &&
      !_isSubmitting &&
      !_isSubmitted;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  @override
  void dispose() {
    _receiverNameController.dispose();
    _otpController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String? _validateReceiverName(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter receiver name';
    }
    if (input.length < 3) {
      return 'Receiver name must be at least 3 characters';
    }
    return null;
  }

  String? _validateOtp(String? value) {
    if (_selectedVerification != _ReceiverVerification.otp) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter receiver OTP';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(input)) {
      return 'OTP must be 6 digits';
    }
    return null;
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
      final trip = _DeliveryProofTripInfo.fromApi(details.trip);
      setState(() {
        _trip = trip;
        _receiverNameController.text = trip.receiverName;
        _isSubmitted = [
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
        _deliveryPhotoBytes = bytes;
        _deliveryPhotoName = fileName;
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
      _deliveryPhotoBytes = null;
      _deliveryPhotoName = null;
    });
  }

  void _captureSignature() {
    setState(() => _hasSignature = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Receiver signature captured.')),
    );
  }

  Future<void> _submitProof() async {
    FocusScope.of(context).unfocus();
    final trip = _trip;
    final photoBytes = _deliveryPhotoBytes;
    final photoName = _deliveryPhotoName;
    if (!_formKey.currentState!.validate() ||
        !_canSubmit ||
        trip == null ||
        photoBytes == null ||
        photoName == null) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _api.uploadDeliveryProof(
        assignmentId: trip.assignmentId,
        fileBytes: photoBytes,
        fileName: photoName,
        notes: _notesController.text,
        locationText: trip.deliveryLocation,
      );
      await _api.markDeliveryCompleted(
        trip.assignmentId,
        notes:
            'Delivery proof submitted for ${_receiverNameController.text.trim()}.',
        locationText: trip.deliveryLocation,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery proof submitted.')),
      );
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

  void _openCompleteTrip() {
    final trip = _trip;
    if (trip == null) {
      return;
    }
    context.go(
      Uri(
        path: AppRoutes.completeTrip,
        queryParameters: {
          'assignmentId': trip.assignmentId.toString(),
          'shipmentId': trip.shipmentId,
        },
      ).toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trip = _trip;
    final statusLabel = _isSubmitted
        ? 'Delivery Proof Submitted'
        : 'Proof Pending';
    final statusTone = _isSubmitted
        ? StatusBadgeTone.delivered
        : StatusBadgeTone.warning;

    return CommonAppScaffold(
      title: 'Delivery proof',
      subtitle: 'Capture receiver handoff proof before completing the trip.',
      bottomNavigationIndex: 1,
      body: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isLoading)
              const LoadingWidget(message: 'Loading delivery proof trip')
            else if (_errorMessage != null)
              ErrorStateWidget(
                title: 'Could not load delivery proof',
                message: _errorMessage!,
                onRetry: _loadTrip,
              )
            else if (trip != null) ...[
              _DeliveryProofHeader(
                trip: trip,
                statusLabel: statusLabel,
                statusTone: statusTone,
              ),
              const SizedBox(height: AppSpacing.lg),
              _DeliveryPhotoCard(
                deliveryPhotoBytes: _deliveryPhotoBytes,
                deliveryPhotoName: _deliveryPhotoName,
                isLocked: _isSubmitted || _isSubmitting,
                onSelectPhoto: _selectPhoto,
                onRemovePhoto: _removePhoto,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ReceiverDetailsCard(
                receiverNameController: _receiverNameController,
                otpController: _otpController,
                selectedVerification: _selectedVerification,
                hasSignature: _hasSignature,
                isLocked: _isSubmitted || _isSubmitting,
                receiverNameValidator: _validateReceiverName,
                otpValidator: _validateOtp,
                onVerificationChanged: (value) {
                  setState(() => _selectedVerification = value);
                },
                onOtpChanged: (_) => setState(() {}),
                onCaptureSignature: _captureSignature,
              ),
              const SizedBox(height: AppSpacing.lg),
              _TimestampLocationCard(trip: trip),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _notesController,
                enabled: !_isSubmitted && !_isSubmitting,
                maxLines: 4,
                maxLength: 220,
                textInputAction: TextInputAction.newline,
                decoration: const InputDecoration(
                  labelText: 'Delivery notes',
                  hintText:
                      'Add receiver handoff, gate pass, or condition notes',
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
                        _isSubmitted
                            ? Icons.check_rounded
                            : Icons.assignment_turned_in_rounded,
                      ),
                label: Text(
                  _isSubmitted
                      ? 'Delivery proof submitted'
                      : _isSubmitting
                      ? 'Submitting proof...'
                      : _canSubmit
                      ? 'Submit delivery proof'
                      : 'Complete proof to submit',
                ),
              ),
              if (_isSubmitted) ...[
                const SizedBox(height: AppSpacing.md),
                _CompleteTripCta(
                  shipmentId: trip.shipmentId,
                  onPressed: _openCompleteTrip,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _CompleteTripCta extends StatelessWidget {
  const _CompleteTripCta({required this.shipmentId, required this.onPressed});

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
                Icons.flag_circle_outlined,
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ready to complete trip',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Review final proofs and end $shipmentId.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open trip completion',
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryProofHeader extends StatelessWidget {
  const _DeliveryProofHeader({
    required this.trip,
    required this.statusLabel,
    required this.statusTone,
  });

  final _DeliveryProofTripInfo trip;
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
              Icons.assignment_turned_in_rounded,
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
                  'Delivery handoff proof',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Delivery photo and receiver confirmation for ${trip.shipmentId}.',
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

class _DeliveryPhotoCard extends StatelessWidget {
  const _DeliveryPhotoCard({
    required this.deliveryPhotoBytes,
    required this.deliveryPhotoName,
    required this.isLocked,
    required this.onSelectPhoto,
    required this.onRemovePhoto,
  });

  final Uint8List? deliveryPhotoBytes;
  final String? deliveryPhotoName;
  final bool isLocked;
  final VoidCallback onSelectPhoto;
  final VoidCallback onRemovePhoto;

  @override
  Widget build(BuildContext context) {
    final hasDeliveryPhoto = deliveryPhotoBytes != null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Mandatory delivery photo',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                StatusBadge(
                  label: hasDeliveryPhoto ? 'Selected' : 'Required',
                  tone: hasDeliveryPhoto
                      ? StatusBadgeTone.completed
                      : StatusBadgeTone.warning,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              height: 184,
              decoration: BoxDecoration(
                color: hasDeliveryPhoto
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                border: Border.all(
                  color: hasDeliveryPhoto
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.border,
                ),
              ),
              child: hasDeliveryPhoto
                  ? _SelectedDeliveryPhotoPreview(
                      bytes: deliveryPhotoBytes!,
                      fileName: deliveryPhotoName ?? 'Selected photo',
                    )
                  : const _EmptyDeliveryPhotoPlaceholder(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLocked ? null : onSelectPhoto,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      hasDeliveryPhoto ? 'Replace photo' : 'Select photo',
                    ),
                  ),
                ),
                if (hasDeliveryPhoto) ...[
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

class _EmptyDeliveryPhotoPlaceholder extends StatelessWidget {
  const _EmptyDeliveryPhotoPlaceholder();

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
          'No delivery photo selected',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          'Receiver handoff photo is required.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SelectedDeliveryPhotoPreview extends StatelessWidget {
  const _SelectedDeliveryPhotoPreview({
    required this.bytes,
    required this.fileName,
  });

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

class _ReceiverDetailsCard extends StatelessWidget {
  const _ReceiverDetailsCard({
    required this.receiverNameController,
    required this.otpController,
    required this.selectedVerification,
    required this.hasSignature,
    required this.isLocked,
    required this.receiverNameValidator,
    required this.otpValidator,
    required this.onVerificationChanged,
    required this.onOtpChanged,
    required this.onCaptureSignature,
  });

  final TextEditingController receiverNameController;
  final TextEditingController otpController;
  final _ReceiverVerification selectedVerification;
  final bool hasSignature;
  final bool isLocked;
  final String? Function(String? value) receiverNameValidator;
  final String? Function(String? value) otpValidator;
  final ValueChanged<_ReceiverVerification> onVerificationChanged;
  final ValueChanged<String> onOtpChanged;
  final VoidCallback onCaptureSignature;

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
                  Icons.person_pin_circle_outlined,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Receiver confirmation',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: receiverNameController,
              enabled: !isLocked,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Receiver name',
                hintText: 'Enter receiver full name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: receiverNameValidator,
            ),
            const SizedBox(height: AppSpacing.md),
            SegmentedButton<_ReceiverVerification>(
              segments: const [
                ButtonSegment(
                  value: _ReceiverVerification.otp,
                  icon: Icon(Icons.pin_outlined),
                  label: Text('OTP'),
                ),
                ButtonSegment(
                  value: _ReceiverVerification.signature,
                  icon: Icon(Icons.draw_outlined),
                  label: Text('Signature'),
                ),
              ],
              selected: {selectedVerification},
              onSelectionChanged: isLocked
                  ? null
                  : (values) => onVerificationChanged(values.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (selectedVerification == _ReceiverVerification.otp)
              TextFormField(
                controller: otpController,
                enabled: !isLocked,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Receiver OTP',
                  hintText: '6 digit OTP',
                  prefixIcon: Icon(Icons.password_rounded),
                ),
                validator: otpValidator,
                onChanged: onOtpChanged,
              )
            else
              _SignaturePlaceholder(
                hasSignature: hasSignature,
                isLocked: isLocked,
                onCaptureSignature: onCaptureSignature,
              ),
          ],
        ),
      ),
    );
  }
}

class _SignaturePlaceholder extends StatelessWidget {
  const _SignaturePlaceholder({
    required this.hasSignature,
    required this.isLocked,
    required this.onCaptureSignature,
  });

  final bool hasSignature;
  final bool isLocked;
  final VoidCallback onCaptureSignature;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(
          color: hasSignature
              ? AppColors.success.withValues(alpha: 0.35)
              : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasSignature ? Icons.check_circle_rounded : Icons.draw_outlined,
                color: hasSignature ? AppColors.success : AppColors.primaryBlue,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  hasSignature
                      ? 'Receiver signature captured'
                      : 'Receiver signature placeholder',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Signature capture is stored as receiver confirmation in this local flow.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: isLocked ? null : onCaptureSignature,
            icon: const Icon(Icons.edit_outlined),
            label: Text(
              hasSignature ? 'Re-capture signature' : 'Capture signature',
            ),
          ),
        ],
      ),
    );
  }
}

class _TimestampLocationCard extends StatelessWidget {
  const _TimestampLocationCard({required this.trip});

  final _DeliveryProofTripInfo trip;

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
              label: 'Timestamp',
              value: trip.timestamp,
            );
            final location = _InfoTile(
              icon: Icons.location_on_outlined,
              label: 'Location',
              value: '${trip.deliveryLocation} - GPS pending',
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

enum _ReceiverVerification { otp, signature }

class _DeliveryProofTripInfo {
  const _DeliveryProofTripInfo({
    required this.assignmentId,
    required this.shipmentId,
    required this.receiverName,
    required this.deliveryLocation,
    required this.timestamp,
  });

  factory _DeliveryProofTripInfo.fromApi(DriverTripSummary trip) {
    return _DeliveryProofTripInfo(
      assignmentId: trip.id,
      shipmentId: trip.displayId,
      receiverName: trip.receiver.name,
      deliveryLocation: trip.deliveryAddress,
      timestamp: 'Now from driver app',
    );
  }

  final int assignmentId;
  final String shipmentId;
  final String receiverName;
  final String deliveryLocation;
  final String timestamp;
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
