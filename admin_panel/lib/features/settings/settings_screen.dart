import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/admin_api_service.dart';
import '../../core/network/api_exception.dart';
import '../../core/widgets/admin_state_widgets.dart';
import '../../core/widgets/admin_status_badge.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  static const _shipmentStatuses = [
    'Pending',
    'Approved',
    'Assigned',
    'In Transit',
    'Delivered',
    'Completed',
  ];
  static const _paymentStatuses = ['Pending', 'Processing', 'Paid', 'Refunded'];
  static const _driverStatuses = ['Available', 'Busy', 'On Leave', 'Offline'];
  static const _timezones = [
    'Asia/Kolkata',
    'UTC',
    'Asia/Dubai',
    'Europe/London',
  ];
  static const _currencies = ['INR', 'USD', 'AED', 'GBP'];
  static const _priorityPolicies = [
    'Admin review required',
    'Auto approve under limit',
    'Always auto assign',
  ];

  final _formKey = GlobalKey<FormState>();
  final _supportEmailController = TextEditingController(
    text: 'support@cargoconnect.in',
  );
  final _invoicePrefixController = TextEditingController(text: 'CC-INV');
  final _dispatchWindowController = TextEditingController(text: '45');
  final _cancellationGraceController = TextEditingController(text: '20');
  final _serviceRadiusController = TextEditingController(text: '80');
  final _baseFareController = TextEditingController(text: '250');
  final _fuelSurchargeController = TextEditingController(text: '8');
  final _weightLimitController = TextEditingController(text: '1200');

  String _defaultShipmentStatus = _shipmentStatuses.first;
  String _defaultPaymentStatus = _paymentStatuses.first;
  String _driverStatusAfterAssignment = 'Busy';
  String _timezone = _timezones.first;
  String _currency = _currencies.first;
  String _priorityPolicy = _priorityPolicies.first;
  bool _customerPushEnabled = true;
  bool _driverPushEnabled = true;
  bool _adminEmailDigestEnabled = true;
  bool _supportReplyAlertsEnabled = true;
  bool _autoAssignEnabled = false;
  bool _proofRequired = true;
  bool _codAllowed = true;
  bool _maintenanceBlocksAssignment = true;
  bool _isLoading = true;
  bool _hasLoadError = false;
  bool _isSaving = false;
  bool _hasSaved = false;
  String? _loadErrorMessage;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _supportEmailController.dispose();
    _invoicePrefixController.dispose();
    _dispatchWindowController.dispose();
    _cancellationGraceController.dispose();
    _serviceRadiusController.dispose();
    _baseFareController.dispose();
    _fuelSurchargeController.dispose();
    _weightLimitController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _hasLoadError = false;
      _loadErrorMessage = null;
    });

    try {
      final settings = await ref.read(adminApiServiceProvider).fetchSettings();

      if (!mounted) {
        return;
      }

      _applySettings(settings);

      setState(() {
        _isLoading = false;
        _hasLoadError = false;
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isLoading = false;
        _hasLoadError = true;
        _loadErrorMessage = error.message;
      });
    }
  }

  Future<void> _saveSettings() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _hasSaved = false;
    });

    try {
      await ref.read(adminApiServiceProvider).saveSettings({
        'settings': {
          'status_master': {
            'default_shipment_status': _defaultShipmentStatus,
            'default_payment_status': _defaultPaymentStatus,
            'driver_status_after_assignment': _driverStatusAfterAssignment,
            'auto_assign_enabled': _autoAssignEnabled,
          },
          'notification_settings': {
            'support_email': _supportEmailController.text.trim(),
            'customer_push_enabled': _customerPushEnabled,
            'driver_push_enabled': _driverPushEnabled,
            'admin_email_digest_enabled': _adminEmailDigestEnabled,
            'support_reply_alerts_enabled': _supportReplyAlertsEnabled,
          },
          'app_settings': {
            'timezone': _timezone,
            'currency': _currency,
            'invoice_prefix': _invoicePrefixController.text.trim(),
            'dispatch_window_minutes': _dispatchWindowController.text.trim(),
          },
          'business_rules': {
            'priority_policy': _priorityPolicy,
            'cancellation_grace_minutes': _cancellationGraceController.text
                .trim(),
            'service_radius_km': _serviceRadiusController.text.trim(),
            'base_fare': _baseFareController.text.trim(),
            'fuel_surcharge_percent': _fuelSurchargeController.text.trim(),
            'manual_review_weight_kg': _weightLimitController.text.trim(),
            'proof_required': _proofRequired,
            'cod_allowed': _codAllowed,
            'maintenance_blocks_assignment': _maintenanceBlocksAssignment,
          },
        },
      });

      if (!mounted) {
        return;
      }

      setState(() {
        _isSaving = false;
        _hasSaved = true;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Admin settings saved.')));
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  void _resetDefaults() {
    setState(() {
      _defaultShipmentStatus = _shipmentStatuses.first;
      _defaultPaymentStatus = _paymentStatuses.first;
      _driverStatusAfterAssignment = 'Busy';
      _timezone = _timezones.first;
      _currency = _currencies.first;
      _priorityPolicy = _priorityPolicies.first;
      _customerPushEnabled = true;
      _driverPushEnabled = true;
      _adminEmailDigestEnabled = true;
      _supportReplyAlertsEnabled = true;
      _autoAssignEnabled = false;
      _proofRequired = true;
      _codAllowed = true;
      _maintenanceBlocksAssignment = true;
      _supportEmailController.text = 'support@cargoconnect.in';
      _invoicePrefixController.text = 'CC-INV';
      _dispatchWindowController.text = '45';
      _cancellationGraceController.text = '20';
      _serviceRadiusController.text = '80';
      _baseFareController.text = '250';
      _fuelSurchargeController.text = '8';
      _weightLimitController.text = '1200';
      _hasSaved = false;
    });
  }

  void _applySettings(AdminSettingsData settings) {
    String stringValue(String group, String key, String fallback) {
      final value = settings.value(group, key)?.toString().trim();
      return value == null || value.isEmpty ? fallback : value;
    }

    bool boolValue(String group, String key, bool fallback) {
      final value = settings.value(group, key);
      if (value is bool) {
        return value;
      }
      return switch (value?.toString().toLowerCase()) {
        'true' || '1' || 'yes' => true,
        'false' || '0' || 'no' => false,
        _ => fallback,
      };
    }

    _defaultShipmentStatus = _coerceOption(
      stringValue(
        'status_master',
        'default_shipment_status',
        _defaultShipmentStatus,
      ),
      _shipmentStatuses,
      _defaultShipmentStatus,
    );
    _defaultPaymentStatus = _coerceOption(
      stringValue(
        'status_master',
        'default_payment_status',
        _defaultPaymentStatus,
      ),
      _paymentStatuses,
      _defaultPaymentStatus,
    );
    _driverStatusAfterAssignment = _coerceOption(
      stringValue(
        'status_master',
        'driver_status_after_assignment',
        _driverStatusAfterAssignment,
      ),
      _driverStatuses,
      _driverStatusAfterAssignment,
    );
    _autoAssignEnabled = boolValue(
      'status_master',
      'auto_assign_enabled',
      _autoAssignEnabled,
    );
    _supportEmailController.text = stringValue(
      'notification_settings',
      'support_email',
      _supportEmailController.text,
    );
    _customerPushEnabled = boolValue(
      'notification_settings',
      'customer_push_enabled',
      _customerPushEnabled,
    );
    _driverPushEnabled = boolValue(
      'notification_settings',
      'driver_push_enabled',
      _driverPushEnabled,
    );
    _adminEmailDigestEnabled = boolValue(
      'notification_settings',
      'admin_email_digest_enabled',
      _adminEmailDigestEnabled,
    );
    _supportReplyAlertsEnabled = boolValue(
      'notification_settings',
      'support_reply_alerts_enabled',
      _supportReplyAlertsEnabled,
    );
    _timezone = _coerceOption(
      stringValue('app_settings', 'timezone', _timezone),
      _timezones,
      _timezone,
    );
    _currency = _coerceOption(
      stringValue('app_settings', 'currency', _currency),
      _currencies,
      _currency,
    );
    _invoicePrefixController.text = stringValue(
      'app_settings',
      'invoice_prefix',
      _invoicePrefixController.text,
    );
    _dispatchWindowController.text = stringValue(
      'app_settings',
      'dispatch_window_minutes',
      _dispatchWindowController.text,
    );
    _priorityPolicy = _coerceOption(
      stringValue('business_rules', 'priority_policy', _priorityPolicy),
      _priorityPolicies,
      _priorityPolicy,
    );
    _cancellationGraceController.text = stringValue(
      'business_rules',
      'cancellation_grace_minutes',
      _cancellationGraceController.text,
    );
    _serviceRadiusController.text = stringValue(
      'business_rules',
      'service_radius_km',
      _serviceRadiusController.text,
    );
    _baseFareController.text = stringValue(
      'business_rules',
      'base_fare',
      _baseFareController.text,
    );
    _fuelSurchargeController.text = stringValue(
      'business_rules',
      'fuel_surcharge_percent',
      _fuelSurchargeController.text,
    );
    _weightLimitController.text = stringValue(
      'business_rules',
      'manual_review_weight_kg',
      _weightLimitController.text,
    );
    _proofRequired = boolValue(
      'business_rules',
      'proof_required',
      _proofRequired,
    );
    _codAllowed = boolValue('business_rules', 'cod_allowed', _codAllowed);
    _maintenanceBlocksAssignment = boolValue(
      'business_rules',
      'maintenance_blocks_assignment',
      _maintenanceBlocksAssignment,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SettingsHeader(
          isSaving: _isSaving,
          hasSaved: _hasSaved,
          onSave: _saveSettings,
          onReset: _resetDefaults,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_isLoading)
          const AdminLoadingState(message: 'Loading admin settings...')
        else if (_hasLoadError)
          AdminErrorState(
            title: 'Settings unavailable',
            message:
                _loadErrorMessage ??
                'Settings could not be loaded. Retry to restore configurable admin options.',
            onRetry: _loadSettings,
          )
        else
          Form(
            key: _formKey,
            child: Column(
              children: [
                _ResponsiveSettingsGrid(
                  children: [
                    _StatusMasterSection(
                      shipmentStatuses: _shipmentStatuses,
                      selectedShipmentStatus: _defaultShipmentStatus,
                      onShipmentStatusChanged: (value) =>
                          setState(() => _defaultShipmentStatus = value),
                      paymentStatuses: _paymentStatuses,
                      selectedPaymentStatus: _defaultPaymentStatus,
                      onPaymentStatusChanged: (value) =>
                          setState(() => _defaultPaymentStatus = value),
                      driverStatuses: _driverStatuses,
                      selectedDriverStatus: _driverStatusAfterAssignment,
                      onDriverStatusChanged: (value) =>
                          setState(() => _driverStatusAfterAssignment = value),
                      autoAssignEnabled: _autoAssignEnabled,
                      onAutoAssignChanged: (value) =>
                          setState(() => _autoAssignEnabled = value),
                    ),
                    _NotificationSettingsSection(
                      supportEmailController: _supportEmailController,
                      customerPushEnabled: _customerPushEnabled,
                      onCustomerPushChanged: (value) =>
                          setState(() => _customerPushEnabled = value),
                      driverPushEnabled: _driverPushEnabled,
                      onDriverPushChanged: (value) =>
                          setState(() => _driverPushEnabled = value),
                      adminEmailDigestEnabled: _adminEmailDigestEnabled,
                      onAdminEmailDigestChanged: (value) =>
                          setState(() => _adminEmailDigestEnabled = value),
                      supportReplyAlertsEnabled: _supportReplyAlertsEnabled,
                      onSupportReplyAlertsChanged: (value) =>
                          setState(() => _supportReplyAlertsEnabled = value),
                    ),
                    _AppSettingsSection(
                      timezones: _timezones,
                      selectedTimezone: _timezone,
                      onTimezoneChanged: (value) =>
                          setState(() => _timezone = value),
                      currencies: _currencies,
                      selectedCurrency: _currency,
                      onCurrencyChanged: (value) =>
                          setState(() => _currency = value),
                      invoicePrefixController: _invoicePrefixController,
                      dispatchWindowController: _dispatchWindowController,
                    ),
                    _BusinessRulesSection(
                      priorityPolicies: _priorityPolicies,
                      selectedPriorityPolicy: _priorityPolicy,
                      onPriorityPolicyChanged: (value) =>
                          setState(() => _priorityPolicy = value),
                      cancellationGraceController: _cancellationGraceController,
                      serviceRadiusController: _serviceRadiusController,
                      baseFareController: _baseFareController,
                      fuelSurchargeController: _fuelSurchargeController,
                      weightLimitController: _weightLimitController,
                      proofRequired: _proofRequired,
                      onProofRequiredChanged: (value) =>
                          setState(() => _proofRequired = value),
                      codAllowed: _codAllowed,
                      onCodAllowedChanged: (value) =>
                          setState(() => _codAllowed = value),
                      maintenanceBlocksAssignment: _maintenanceBlocksAssignment,
                      onMaintenanceBlocksAssignmentChanged: (value) =>
                          setState(() => _maintenanceBlocksAssignment = value),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSaveBar(
                  isSaving: _isSaving,
                  hasSaved: _hasSaved,
                  onSave: _saveSettings,
                  onReset: _resetDefaults,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _SettingsHeader extends StatelessWidget {
  const _SettingsHeader({
    required this.isSaving,
    required this.hasSaved,
    required this.onSave,
    required this.onReset,
  });

  final bool isSaving;
  final bool hasSaved;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AdminStatusBadge(
                  label: hasSaved ? 'Saved' : 'Backend configuration',
                  tone: hasSaved
                      ? AdminStatusTone.success
                      : AdminStatusTone.info,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Settings',
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Configure admin status masters, notifications, app defaults, and business rules through the backend.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
            );

            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton.icon(
                  onPressed: isSaving ? null : onReset,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Reset defaults'),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Saving...' : 'Save settings'),
                ),
              ],
            );

            if (constraints.maxWidth >= 920) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  Flexible(child: actions),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.lg),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ResponsiveSettingsGrid extends StatelessWidget {
  const _ResponsiveSettingsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 1180) {
          return Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.lg,
            children: [
              for (final child in children)
                SizedBox(
                  width: (constraints.maxWidth - AppSpacing.lg) / 2,
                  child: child,
                ),
            ],
          );
        }

        return Column(
          children: [
            for (final child in children) ...[
              child,
              if (child != children.last) const SizedBox(height: AppSpacing.lg),
            ],
          ],
        );
      },
    );
  }
}

class _StatusMasterSection extends StatelessWidget {
  const _StatusMasterSection({
    required this.shipmentStatuses,
    required this.selectedShipmentStatus,
    required this.onShipmentStatusChanged,
    required this.paymentStatuses,
    required this.selectedPaymentStatus,
    required this.onPaymentStatusChanged,
    required this.driverStatuses,
    required this.selectedDriverStatus,
    required this.onDriverStatusChanged,
    required this.autoAssignEnabled,
    required this.onAutoAssignChanged,
  });

  final List<String> shipmentStatuses;
  final String selectedShipmentStatus;
  final ValueChanged<String> onShipmentStatusChanged;
  final List<String> paymentStatuses;
  final String selectedPaymentStatus;
  final ValueChanged<String> onPaymentStatusChanged;
  final List<String> driverStatuses;
  final String selectedDriverStatus;
  final ValueChanged<String> onDriverStatusChanged;
  final bool autoAssignEnabled;
  final ValueChanged<bool> onAutoAssignChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      title: 'Status master',
      subtitle:
          'Default statuses used by shipment, payment, and driver workflows.',
      icon: Icons.rule_folder_outlined,
      children: [
        _SettingsDropdown(
          label: 'Default shipment status',
          value: selectedShipmentStatus,
          options: shipmentStatuses,
          onChanged: onShipmentStatusChanged,
        ),
        _SettingsDropdown(
          label: 'Default payment status',
          value: selectedPaymentStatus,
          options: paymentStatuses,
          onChanged: onPaymentStatusChanged,
        ),
        _SettingsDropdown(
          label: 'Driver status after assignment',
          value: selectedDriverStatus,
          options: driverStatuses,
          onChanged: onDriverStatusChanged,
        ),
        _SettingsSwitchTile(
          title: 'Auto assign approved shipments',
          subtitle:
              'Control whether approved shipments can enter the assignment queue automatically.',
          value: autoAssignEnabled,
          onChanged: onAutoAssignChanged,
        ),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final status in shipmentStatuses)
              AdminStatusBadge.fromStatus(status),
          ],
        ),
      ],
    );
  }
}

class _NotificationSettingsSection extends StatelessWidget {
  const _NotificationSettingsSection({
    required this.supportEmailController,
    required this.customerPushEnabled,
    required this.onCustomerPushChanged,
    required this.driverPushEnabled,
    required this.onDriverPushChanged,
    required this.adminEmailDigestEnabled,
    required this.onAdminEmailDigestChanged,
    required this.supportReplyAlertsEnabled,
    required this.onSupportReplyAlertsChanged,
  });

  final TextEditingController supportEmailController;
  final bool customerPushEnabled;
  final ValueChanged<bool> onCustomerPushChanged;
  final bool driverPushEnabled;
  final ValueChanged<bool> onDriverPushChanged;
  final bool adminEmailDigestEnabled;
  final ValueChanged<bool> onAdminEmailDigestChanged;
  final bool supportReplyAlertsEnabled;
  final ValueChanged<bool> onSupportReplyAlertsChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      title: 'Notification settings',
      subtitle: 'Control customer, driver, support, and admin alerts.',
      icon: Icons.notifications_active_outlined,
      children: [
        _SettingsTextField(
          controller: supportEmailController,
          label: 'Support email',
          icon: Icons.alternate_email_outlined,
          keyboardType: TextInputType.emailAddress,
          validator: _emailValidator,
        ),
        _SettingsSwitchTile(
          title: 'Customer push notifications',
          subtitle: 'Booking, driver assigned, in transit, and delivered.',
          value: customerPushEnabled,
          onChanged: onCustomerPushChanged,
        ),
        _SettingsSwitchTile(
          title: 'Driver push notifications',
          subtitle: 'Trip assignment, delay reminders, and proof prompts.',
          value: driverPushEnabled,
          onChanged: onDriverPushChanged,
        ),
        _SettingsSwitchTile(
          title: 'Admin email digest',
          subtitle: 'Daily operations snapshot to configured admins.',
          value: adminEmailDigestEnabled,
          onChanged: onAdminEmailDigestChanged,
        ),
        _SettingsSwitchTile(
          title: 'Support reply alerts',
          subtitle: 'Notify customers when admin replies to a ticket.',
          value: supportReplyAlertsEnabled,
          onChanged: onSupportReplyAlertsChanged,
        ),
      ],
    );
  }
}

class _AppSettingsSection extends StatelessWidget {
  const _AppSettingsSection({
    required this.timezones,
    required this.selectedTimezone,
    required this.onTimezoneChanged,
    required this.currencies,
    required this.selectedCurrency,
    required this.onCurrencyChanged,
    required this.invoicePrefixController,
    required this.dispatchWindowController,
  });

  final List<String> timezones;
  final String selectedTimezone;
  final ValueChanged<String> onTimezoneChanged;
  final List<String> currencies;
  final String selectedCurrency;
  final ValueChanged<String> onCurrencyChanged;
  final TextEditingController invoicePrefixController;
  final TextEditingController dispatchWindowController;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      title: 'App settings',
      subtitle:
          'Global formatting and operations defaults for the admin panel.',
      icon: Icons.tune_outlined,
      children: [
        _SettingsDropdown(
          label: 'Default timezone',
          value: selectedTimezone,
          options: timezones,
          onChanged: onTimezoneChanged,
        ),
        _SettingsDropdown(
          label: 'Billing currency',
          value: selectedCurrency,
          options: currencies,
          onChanged: onCurrencyChanged,
        ),
        _SettingsTextField(
          controller: invoicePrefixController,
          label: 'Invoice prefix',
          icon: Icons.receipt_long_outlined,
          textCapitalization: TextCapitalization.characters,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Enter the invoice prefix';
            }
            if (value.trim().length < 3) {
              return 'Use at least 3 characters';
            }
            return null;
          },
        ),
        _SettingsTextField(
          controller: dispatchWindowController,
          label: 'Dispatch window minutes',
          icon: Icons.schedule_outlined,
          keyboardType: TextInputType.number,
          validator: (value) => _positiveNumberValidator(
            value,
            emptyMessage: 'Enter dispatch window minutes',
            max: 240,
          ),
        ),
      ],
    );
  }
}

class _BusinessRulesSection extends StatelessWidget {
  const _BusinessRulesSection({
    required this.priorityPolicies,
    required this.selectedPriorityPolicy,
    required this.onPriorityPolicyChanged,
    required this.cancellationGraceController,
    required this.serviceRadiusController,
    required this.baseFareController,
    required this.fuelSurchargeController,
    required this.weightLimitController,
    required this.proofRequired,
    required this.onProofRequiredChanged,
    required this.codAllowed,
    required this.onCodAllowedChanged,
    required this.maintenanceBlocksAssignment,
    required this.onMaintenanceBlocksAssignmentChanged,
  });

  final List<String> priorityPolicies;
  final String selectedPriorityPolicy;
  final ValueChanged<String> onPriorityPolicyChanged;
  final TextEditingController cancellationGraceController;
  final TextEditingController serviceRadiusController;
  final TextEditingController baseFareController;
  final TextEditingController fuelSurchargeController;
  final TextEditingController weightLimitController;
  final bool proofRequired;
  final ValueChanged<bool> onProofRequiredChanged;
  final bool codAllowed;
  final ValueChanged<bool> onCodAllowedChanged;
  final bool maintenanceBlocksAssignment;
  final ValueChanged<bool> onMaintenanceBlocksAssignmentChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingsSectionCard(
      title: 'Business rules',
      subtitle: 'Logistics policies for pricing, proof, COD, and dispatch.',
      icon: Icons.account_tree_outlined,
      children: [
        _SettingsDropdown(
          label: 'Urgent shipment policy',
          value: selectedPriorityPolicy,
          options: priorityPolicies,
          onChanged: onPriorityPolicyChanged,
        ),
        _TwoColumnFields(
          children: [
            _SettingsTextField(
              controller: cancellationGraceController,
              label: 'Cancellation grace minutes',
              icon: Icons.cancel_schedule_send_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => _positiveNumberValidator(
                value,
                emptyMessage: 'Enter cancellation grace minutes',
                max: 180,
              ),
            ),
            _SettingsTextField(
              controller: serviceRadiusController,
              label: 'Service radius km',
              icon: Icons.social_distance_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => _positiveNumberValidator(
                value,
                emptyMessage: 'Enter service radius',
                max: 500,
              ),
            ),
            _SettingsTextField(
              controller: baseFareController,
              label: 'Base fare',
              icon: Icons.currency_rupee_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => _positiveNumberValidator(
                value,
                emptyMessage: 'Enter base fare',
                max: 100000,
              ),
            ),
            _SettingsTextField(
              controller: fuelSurchargeController,
              label: 'Fuel surcharge percent',
              icon: Icons.local_gas_station_outlined,
              keyboardType: TextInputType.number,
              validator: (value) => _positiveNumberValidator(
                value,
                emptyMessage: 'Enter fuel surcharge',
                max: 40,
              ),
            ),
          ],
        ),
        _SettingsTextField(
          controller: weightLimitController,
          label: 'Manual review weight kg',
          icon: Icons.scale_outlined,
          keyboardType: TextInputType.number,
          validator: (value) => _positiveNumberValidator(
            value,
            emptyMessage: 'Enter weight review limit',
            max: 50000,
          ),
        ),
        _SettingsSwitchTile(
          title: 'Require pickup and delivery proof',
          subtitle: 'Drivers must upload proof for both critical trip stages.',
          value: proofRequired,
          onChanged: onProofRequiredChanged,
        ),
        _SettingsSwitchTile(
          title: 'Allow cash on delivery',
          subtitle: 'Enable COD as a payment option for eligible shipments.',
          value: codAllowed,
          onChanged: onCodAllowedChanged,
        ),
        _SettingsSwitchTile(
          title: 'Block assignment during maintenance',
          subtitle: 'Prevent vehicles under maintenance from assignment lists.',
          value: maintenanceBlocksAssignment,
          onChanged: onMaintenanceBlocksAssignmentChanged,
        ),
      ],
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.children,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final child in children) ...[
              child,
              if (child != children.last) const SizedBox(height: AppSpacing.md),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsDropdown extends StatelessWidget {
  const _SettingsDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.arrow_drop_down_circle_outlined),
      ),
      items: [
        for (final option in options)
          DropdownMenuItem(value: option, child: Text(option)),
      ],
      onChanged: (value) {
        if (value != null) {
          onChanged(value);
        }
      },
    );
  }
}

class _SettingsTextField extends StatelessWidget {
  const _SettingsTextField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.validator,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final FormFieldValidator<String> validator;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }
}

class _SettingsSwitchTile extends StatelessWidget {
  const _SettingsSwitchTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: AppSpacing.xxs),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _TwoColumnFields extends StatelessWidget {
  const _TwoColumnFields({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 620) {
          return Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.md,
            children: [
              for (final child in children)
                SizedBox(
                  width: (constraints.maxWidth - AppSpacing.md) / 2,
                  child: child,
                ),
            ],
          );
        }

        return Column(
          children: [
            for (final child in children) ...[
              child,
              if (child != children.last) const SizedBox(height: AppSpacing.md),
            ],
          ],
        );
      },
    );
  }
}

class _SettingsSaveBar extends StatelessWidget {
  const _SettingsSaveBar({
    required this.isSaving,
    required this.hasSaved,
    required this.onSave,
    required this.onReset,
  });

  final bool isSaving;
  final bool hasSaved;
  final VoidCallback onSave;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final copy = Row(
              children: [
                Icon(
                  hasSaved ? Icons.verified_outlined : Icons.info_outline,
                  color: hasSaved ? AppColors.success : AppColors.info,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    hasSaved
                        ? 'Settings are saved through the backend API.'
                        : 'Review settings and save to update the backend configuration.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            );

            final actions = Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                OutlinedButton(
                  onPressed: isSaving ? null : onReset,
                  child: const Text('Reset'),
                ),
                FilledButton.icon(
                  onPressed: isSaving ? null : onSave,
                  icon: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(isSaving ? 'Saving...' : 'Save settings'),
                ),
              ],
            );

            if (constraints.maxWidth >= 880) {
              return Row(
                children: [
                  Expanded(child: copy),
                  const SizedBox(width: AppSpacing.lg),
                  actions,
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                copy,
                const SizedBox(height: AppSpacing.md),
                actions,
              ],
            );
          },
        ),
      ),
    );
  }
}

String? _emailValidator(String? value) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return 'Enter the support email';
  }
  final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  if (!emailPattern.hasMatch(text)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? _positiveNumberValidator(
  String? value, {
  required String emptyMessage,
  required num max,
}) {
  final text = value?.trim() ?? '';
  if (text.isEmpty) {
    return emptyMessage;
  }
  final number = num.tryParse(text);
  if (number == null) {
    return 'Enter a valid number';
  }
  if (number <= 0) {
    return 'Value must be greater than 0';
  }
  if (number > max) {
    return 'Value must be $max or less';
  }
  return null;
}

String _coerceOption(String value, List<String> options, String fallback) {
  final normalized = value
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .trim()
      .toLowerCase();
  for (final option in options) {
    if (option.toLowerCase() == normalized) {
      return option;
    }
  }
  return fallback;
}
