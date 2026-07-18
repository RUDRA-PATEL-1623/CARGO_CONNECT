import 'dart:async';

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
import '../shipment/data/customer_shipment_api.dart';
import 'data/customer_feedback_api.dart';

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  String? _selectedShipmentKey;
  int _rating = 0;
  bool _wouldRecommend = true;
  bool _isSubmitting = false;
  bool _isSubmitted = false;
  bool _isLoading = true;
  String? _loadError;
  String? _submitError;
  String _thankYouTitle = 'Thank you for your feedback';
  String _thankYouMessage = 'Your delivery experience has been recorded.';
  final Set<String> _selectedTags = {};

  var _shipmentOptions = <_FeedbackShipmentOption>[];
  var _existingFeedback = <CustomerFeedback>[];

  static const _experienceTags = [
    'On-time updates',
    'Driver support',
    'Safe handling',
    'Easy booking',
    'Clear pricing',
    'Proof quality',
    'Support response',
    'Needs improvement',
  ];

  @override
  void initState() {
    super.initState();
    unawaited(_loadFeedbackData());
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  Future<void> _loadFeedbackData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final history = await ref
          .read(customerShipmentApiProvider)
          .listShipmentHistory(limit: 50);
      final feedbackList = await ref
          .read(customerFeedbackApiProvider)
          .listFeedback(limit: 5);

      if (!mounted) {
        return;
      }

      final shipmentOptions = history.shipments
          .map(
            (shipment) => _FeedbackShipmentOption(
              key: shipment.id.toString(),
              shipmentId: shipment.id,
              label:
                  '${shipment.shipmentCode} - ${_shortAddress(shipment.pickupAddress)} to ${_shortAddress(shipment.deliveryAddress)}',
            ),
          )
          .toList(growable: false);

      setState(() {
        _shipmentOptions = shipmentOptions;
        _existingFeedback = feedbackList.feedback;
        _selectedShipmentKey ??= shipmentOptions.isEmpty
            ? null
            : shipmentOptions.first.key;
        _isLoading = false;
      });
    } on ApiException catch (error) {
      _setLoadError(error.message);
    } catch (_) {
      _setLoadError('Unable to load feedback data.');
    }
  }

  void _setLoadError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _loadError = message;
    });
  }

  String? _validateShipment(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Select shipment';
    }
    return null;
  }

  String? _validateComments(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter comments';
    }
    if (input.length < 10) {
      return 'Comments must be at least 10 characters';
    }
    if (input.length > 400) {
      return 'Keep comments under 400 characters';
    }
    return null;
  }

  Future<void> _submitFeedback() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a rating to continue.')),
      );
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one experience tag.')),
      );
      return;
    }

    final selectedShipment = _shipmentOptions.firstWhere(
      (option) => option.key == _selectedShipmentKey,
      orElse: () => throw const ApiException(message: 'Select shipment'),
    );

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      final result = await ref
          .read(customerFeedbackApiProvider)
          .submitFeedback(
            CustomerFeedbackRequest(
              shipmentId: selectedShipment.shipmentId,
              rating: _rating,
              experienceTags: _selectedTags.map(_tagValue).toList(),
              comments: _commentsController.text,
              wouldRecommend: _wouldRecommend,
            ),
          );

      if (!mounted) {
        return;
      }

      setState(() {
        _isSubmitting = false;
        _isSubmitted = true;
        _thankYouTitle = result.thankYouTitle;
        _thankYouMessage = result.thankYouMessage;
        _existingFeedback = [
          result.feedback,
          ..._existingFeedback.where((item) => item.id != result.feedback.id),
        ];
      });
    } on ApiException catch (error) {
      _setSubmitError(error.message);
    } catch (_) {
      _setSubmitError('Unable to submit feedback.');
    }
  }

  void _setSubmitError(String message) {
    if (!mounted) {
      return;
    }
    setState(() {
      _isSubmitting = false;
      _submitError = message;
    });
  }

  void _resetFeedback() {
    setState(() {
      _selectedShipmentKey = _shipmentOptions.isEmpty
          ? null
          : _shipmentOptions.first.key;
      _rating = 0;
      _wouldRecommend = true;
      _isSubmitted = false;
      _submitError = null;
      _selectedTags.clear();
      _commentsController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Feedback',
      subtitle: 'Share feedback for a completed shipment experience.',
      body: _isLoading
          ? const LoadingWidget(message: 'Loading feedback form')
          : _loadError != null
          ? ErrorStateWidget(
              title: 'Feedback unavailable',
              message: _loadError!,
              onRetry: _loadFeedbackData,
            )
          : AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _isSubmitted
                  ? _ThankYouState(
                      key: const ValueKey('thank-you'),
                      title: _thankYouTitle,
                      message: _thankYouMessage,
                      rating: _rating,
                      selectedShipment: _selectedShipmentLabel,
                      onSubmitAnother: _resetFeedback,
                    )
                  : _FeedbackContent(
                      key: const ValueKey('form'),
                      formKey: _formKey,
                      selectedShipmentKey: _selectedShipmentKey,
                      shipments: _shipmentOptions,
                      rating: _rating,
                      selectedTags: _selectedTags,
                      experienceTags: _experienceTags,
                      commentsController: _commentsController,
                      wouldRecommend: _wouldRecommend,
                      isSubmitting: _isSubmitting,
                      submitError: _submitError,
                      existingFeedback: _existingFeedback,
                      onShipmentChanged: (value) =>
                          setState(() => _selectedShipmentKey = value),
                      onRatingChanged: (value) =>
                          setState(() => _rating = value),
                      onTagToggled: (tag) {
                        setState(() {
                          if (_selectedTags.contains(tag)) {
                            _selectedTags.remove(tag);
                          } else {
                            _selectedTags.add(tag);
                          }
                        });
                      },
                      onRecommendChanged: (value) =>
                          setState(() => _wouldRecommend = value ?? false),
                      onSubmit: _submitFeedback,
                      shipmentValidator: _validateShipment,
                      commentsValidator: _validateComments,
                    ),
            ),
    );
  }

  String get _selectedShipmentLabel {
    return _shipmentOptions
        .firstWhere(
          (option) => option.key == _selectedShipmentKey,
          orElse: () => const _FeedbackShipmentOption(
            key: '',
            shipmentId: 0,
            label: 'Selected shipment',
          ),
        )
        .label;
  }
}

class _FeedbackContent extends StatelessWidget {
  const _FeedbackContent({
    super.key,
    required this.formKey,
    required this.selectedShipmentKey,
    required this.shipments,
    required this.rating,
    required this.selectedTags,
    required this.experienceTags,
    required this.commentsController,
    required this.wouldRecommend,
    required this.isSubmitting,
    required this.submitError,
    required this.existingFeedback,
    required this.onShipmentChanged,
    required this.onRatingChanged,
    required this.onTagToggled,
    required this.onRecommendChanged,
    required this.onSubmit,
    required this.shipmentValidator,
    required this.commentsValidator,
  });

  final GlobalKey<FormState> formKey;
  final String? selectedShipmentKey;
  final List<_FeedbackShipmentOption> shipments;
  final int rating;
  final Set<String> selectedTags;
  final List<String> experienceTags;
  final TextEditingController commentsController;
  final bool wouldRecommend;
  final bool isSubmitting;
  final String? submitError;
  final List<CustomerFeedback> existingFeedback;
  final ValueChanged<String?> onShipmentChanged;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onTagToggled;
  final ValueChanged<bool?> onRecommendChanged;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> shipmentValidator;
  final FormFieldValidator<String> commentsValidator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _FeedbackHeader(),
        const SizedBox(height: AppSpacing.lg),
        if (shipments.isEmpty)
          const EmptyStateWidget(
            icon: Icons.local_shipping_outlined,
            title: 'No shipments available',
            message:
                'Create and complete a shipment before submitting delivery feedback.',
          )
        else
          _FeedbackForm(
            formKey: formKey,
            selectedShipmentKey: selectedShipmentKey,
            shipments: shipments,
            rating: rating,
            selectedTags: selectedTags,
            experienceTags: experienceTags,
            commentsController: commentsController,
            wouldRecommend: wouldRecommend,
            isSubmitting: isSubmitting,
            submitError: submitError,
            onShipmentChanged: onShipmentChanged,
            onRatingChanged: onRatingChanged,
            onTagToggled: onTagToggled,
            onRecommendChanged: onRecommendChanged,
            onSubmit: onSubmit,
            shipmentValidator: shipmentValidator,
            commentsValidator: commentsValidator,
          ),
        const SizedBox(height: AppSpacing.lg),
        _FeedbackHistory(feedback: existingFeedback),
      ],
    );
  }
}

class _FeedbackForm extends StatelessWidget {
  const _FeedbackForm({
    required this.formKey,
    required this.selectedShipmentKey,
    required this.shipments,
    required this.rating,
    required this.selectedTags,
    required this.experienceTags,
    required this.commentsController,
    required this.wouldRecommend,
    required this.isSubmitting,
    required this.submitError,
    required this.onShipmentChanged,
    required this.onRatingChanged,
    required this.onTagToggled,
    required this.onRecommendChanged,
    required this.onSubmit,
    required this.shipmentValidator,
    required this.commentsValidator,
  });

  final GlobalKey<FormState> formKey;
  final String? selectedShipmentKey;
  final List<_FeedbackShipmentOption> shipments;
  final int rating;
  final Set<String> selectedTags;
  final List<String> experienceTags;
  final TextEditingController commentsController;
  final bool wouldRecommend;
  final bool isSubmitting;
  final String? submitError;
  final ValueChanged<String?> onShipmentChanged;
  final ValueChanged<int> onRatingChanged;
  final ValueChanged<String> onTagToggled;
  final ValueChanged<bool?> onRecommendChanged;
  final VoidCallback onSubmit;
  final FormFieldValidator<String> shipmentValidator;
  final FormFieldValidator<String> commentsValidator;

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (submitError != null) ...[
                _InlineError(message: submitError!),
                const SizedBox(height: AppSpacing.md),
              ],
              DropdownButtonFormField<String>(
                initialValue: selectedShipmentKey,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Shipment',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
                items: [
                  for (final shipment in shipments)
                    DropdownMenuItem(
                      value: shipment.key,
                      child: Text(shipment.label),
                    ),
                ],
                onChanged: isSubmitting ? null : onShipmentChanged,
                validator: shipmentValidator,
              ),
              const SizedBox(height: AppSpacing.lg),
              _RatingSelector(
                rating: rating,
                isEnabled: !isSubmitting,
                onChanged: onRatingChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
              _ExperienceTags(
                tags: experienceTags,
                selectedTags: selectedTags,
                isEnabled: !isSubmitting,
                onTagToggled: onTagToggled,
              ),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: commentsController,
                enabled: !isSubmitting,
                minLines: 4,
                maxLines: 6,
                maxLength: 400,
                decoration: const InputDecoration(
                  labelText: 'Comments',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.rate_review_outlined),
                  hintText:
                      'Tell us what worked well or what could be improved.',
                ),
                validator: commentsValidator,
              ),
              const SizedBox(height: AppSpacing.sm),
              CheckboxListTile(
                value: wouldRecommend,
                onChanged: isSubmitting ? null : onRecommendChanged,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text(
                  'I would recommend CargoConnect to another business.',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: isSubmitting ? null : onSubmit,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: AppColors.textInverse,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(isSubmitting ? 'Submitting...' : 'Submit feedback'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackHeader extends StatelessWidget {
  const _FeedbackHeader();

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
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.star_rate_rounded,
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
                  'Rate your shipment',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Feedback is saved to your customer account and visible to admins.',
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

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({
    required this.rating,
    required this.isEnabled,
    required this.onChanged,
  });

  final int rating;
  final bool isEnabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Rating', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            for (var index = 1; index <= 5; index++)
              IconButton(
                tooltip: '$index star rating',
                onPressed: isEnabled ? () => onChanged(index) : null,
                icon: Icon(
                  index <= rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: index <= rating
                      ? AppColors.roadYellow
                      : AppColors.textSecondary,
                  size: 34,
                ),
              ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              rating == 0 ? 'Select rating' : '$rating / 5',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: rating == 0
                    ? AppColors.textSecondary
                    : AppColors.primaryNavy,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ExperienceTags extends StatelessWidget {
  const _ExperienceTags({
    required this.tags,
    required this.selectedTags,
    required this.isEnabled,
    required this.onTagToggled,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final bool isEnabled;
  final ValueChanged<String> onTagToggled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Experience tags', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final tag in tags)
              ChoiceChip(
                label: Text(tag),
                selected: selectedTags.contains(tag),
                onSelected: isEnabled ? (_) => onTagToggled(tag) : null,
                selectedColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                checkmarkColor: AppColors.primaryBlue,
              ),
          ],
        ),
      ],
    );
  }
}

class _FeedbackHistory extends StatelessWidget {
  const _FeedbackHistory({required this.feedback});

  final List<CustomerFeedback> feedback;

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
                const Icon(Icons.history_rounded, color: AppColors.primaryBlue),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Recent feedback',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            if (feedback.isEmpty)
              const EmptyStateWidget(
                icon: Icons.rate_review_outlined,
                title: 'No feedback submitted',
                message: 'Your shipment feedback history will appear here.',
              )
            else
              for (final item in feedback) ...[
                _FeedbackTile(feedback: item),
                if (item != feedback.last) const Divider(height: AppSpacing.lg),
              ],
          ],
        ),
      ),
    );
  }
}

class _FeedbackTile extends StatelessWidget {
  const _FeedbackTile({required this.feedback});

  final CustomerFeedback feedback;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.roadYellow.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          ),
          child: const Icon(Icons.star_rounded, color: AppColors.warning),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${feedback.rating}/5 for ${feedback.shipmentCode ?? 'shipment #${feedback.shipmentId}'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                feedback.comments?.isNotEmpty == true
                    ? feedback.comments!
                    : 'No comments provided.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (feedback.experienceTags.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  feedback.experienceTags.map(_titleCase).join(', '),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ThankYouState extends StatelessWidget {
  const _ThankYouState({
    super.key,
    required this.title,
    required this.message,
    required this.rating,
    required this.selectedShipment,
    required this.onSubmitAnother,
  });

  final String title;
  final String message;
  final int rating;
  final String selectedShipment;
  final VoidCallback onSubmitAnother;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: AppColors.success,
              size: 44,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$message\n\nRating: $rating / 5\nShipment: $selectedShipment',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: onSubmitAnother,
            icon: const Icon(Icons.rate_review_outlined),
            label: const Text('Submit another feedback'),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.danger.withValues(alpha: 0.24)),
      ),
      child: Text(
        message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.danger,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeedbackShipmentOption {
  const _FeedbackShipmentOption({
    required this.key,
    required this.shipmentId,
    required this.label,
  });

  final String key;
  final int shipmentId;
  final String label;
}

String _shortAddress(String value) {
  final firstPart = value.split(',').first.trim();
  return firstPart.isEmpty ? 'Address pending' : firstPart;
}

String _tagValue(String tag) {
  return tag
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_|_$'), '');
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
