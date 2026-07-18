import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/router/app_routes.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../shipment/data/customer_shipment_api.dart';

enum _PaymentMethod { upi, card, cash, wallet }

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key, required this.shipmentId});

  final String? shipmentId;

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _couponController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  late Future<CheckoutData> _checkoutFuture;
  CheckoutData? _checkout;
  _PaymentMethod _selectedMethod = _PaymentMethod.upi;
  bool _acceptedTerms = false;
  bool _isPaying = false;
  int _couponDiscount = 0;

  @override
  void initState() {
    super.initState();
    _checkoutFuture = _loadCheckout();
  }

  @override
  void dispose() {
    _couponController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<CheckoutData> _loadCheckout() async {
    final api = ref.read(customerShipmentApiProvider);
    final shipmentId = await api.resolveShipmentId(widget.shipmentId ?? '');
    return api.getCheckout(shipmentId);
  }

  void _retryCheckout() {
    setState(() => _checkoutFuture = _loadCheckout());
  }

  PriceBreakdownData? get _breakdown => _checkout?.priceEstimate.breakdown;

  int get _baseFare => _breakdown?.basePrice.round() ?? 0;
  int get _distanceCharge => _breakdown?.distanceCharge.round() ?? 0;
  int get _handlingFee => _breakdown?.handlingAmount.round() ?? 0;
  int get _insuranceFee => _breakdown?.feeAmount.round() ?? 0;
  int get _taxes => _breakdown?.taxAmount.round() ?? 0;
  int get _total => (_breakdown?.totalAmount.round() ?? 0) - _couponDiscount;

  String? _validateCoupon(String? value) {
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return null;
    }
    if (!RegExp(r'^[A-Za-z0-9_-]{2,40}$').hasMatch(input)) {
      return 'Use 2-40 letters, numbers, underscores, or dashes';
    }
    return null;
  }

  String? _validateCardNumber(String? value) {
    if (_selectedMethod != _PaymentMethod.card) {
      return null;
    }
    final digits = (value ?? '').replaceAll(' ', '');
    if (digits.isEmpty) {
      return 'Enter card number';
    }
    if (!RegExp(r'^[0-9]{16}$').hasMatch(digits)) {
      return 'Enter a valid 16 digit card number';
    }
    return null;
  }

  String? _validateCardName(String? value) {
    if (_selectedMethod != _PaymentMethod.card) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter cardholder name';
    }
    if (input.length < 3) {
      return 'Name must be at least 3 characters';
    }
    return null;
  }

  String? _validateExpiry(String? value) {
    if (_selectedMethod != _PaymentMethod.card) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter expiry';
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])\/[0-9]{2}$').hasMatch(input)) {
      return 'Use MM/YY format';
    }
    return null;
  }

  String? _validateCvv(String? value) {
    if (_selectedMethod != _PaymentMethod.card) {
      return null;
    }
    final input = value?.trim() ?? '';
    if (input.isEmpty) {
      return 'Enter CVV';
    }
    if (!RegExp(r'^[0-9]{3,4}$').hasMatch(input)) {
      return 'Enter valid CVV';
    }
    return null;
  }

  void _applyCoupon() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final coupon = _couponController.text.trim().toUpperCase();
    setState(() => _couponDiscount = 0);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          coupon.isEmpty
              ? 'Enter a coupon code to validate.'
              : 'Coupon will be sent for backend validation at payment.',
        ),
      ),
    );
  }

  Future<void> _payNow() async {
    final checkout = _checkout;
    if (checkout == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Accept payment terms to continue.')),
      );
      return;
    }

    setState(() => _isPaying = true);
    _showProcessingModal();

    try {
      final result = await ref
          .read(customerShipmentApiProvider)
          .confirmMockPayment(
            shipmentId: checkout.shipment.id,
            paymentMethod: _methodValue(_selectedMethod),
            acceptTerms: _acceptedTerms,
            couponCode: _couponController.text,
          );

      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isPaying = false);
      _showPaymentResultModal(success: true, result: result);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isPaying = false);
      _showPaymentResultModal(success: false, failureMessage: error.message);
    } catch (_) {
      if (!mounted) {
        return;
      }

      Navigator.of(context, rootNavigator: true).pop();
      setState(() => _isPaying = false);
      _showPaymentResultModal(
        success: false,
        failureMessage: 'Unable to confirm payment right now.',
      );
    }
  }

  void _openExistingConfirmation(CheckoutData checkout) {
    final invoice = checkout.invoice;
    context.go(
      Uri(
        path: AppRoutes.orderConfirmation,
        queryParameters: {
          'shipmentId': checkout.shipment.id.toString(),
          'bookingId': checkout.shipment.shipmentCode,
          if (invoice != null) 'invoiceId': invoice.id.toString(),
          'pickup': checkout.shipment.pickupDateTime,
        },
      ).toString(),
    );
  }

  void _showFailureDemo() {
    _showPaymentResultModal(
      success: false,
      failureMessage:
          'Gateway timeout while preparing ${_methodLabel(_selectedMethod)} payment.',
    );
  }

  void _showProcessingModal() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Processing payment',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Preparing a mock ${_methodLabel(_selectedMethod)} payment. No money is charged.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showPaymentResultModal({
    required bool success,
    PaymentConfirmationData? result,
    String? failureMessage,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: !success,
      enableDrag: !success,
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.md,
            AppSpacing.screenPadding,
            AppSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: success
                    ? const Color(0xFFE8F7ED)
                    : const Color(0xFFFFEBEE),
                child: Icon(
                  success
                      ? Icons.check_circle_rounded
                      : Icons.error_outline_rounded,
                  color: success ? AppColors.success : AppColors.danger,
                  size: 38,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                success ? 'Payment successful' : 'Payment failed',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                success
                    ? '${_money(result?.payment.totalAmount.round() ?? _total)} captured in mock mode for ${result?.bookingId ?? _checkout?.shipment.shipmentCode ?? 'this shipment'}.'
                    : 'Payment summary: ${failureMessage ?? 'The mock payment could not be confirmed.'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (success)
                ElevatedButton.icon(
                  onPressed: () {
                    final confirmation = result;
                    Navigator.of(context).pop();
                    context.go(
                      Uri(
                        path: AppRoutes.orderConfirmation,
                        queryParameters: {
                          if (confirmation != null) ...{
                            'shipmentId': confirmation.shipment.id.toString(),
                            'bookingId': confirmation.bookingId,
                            'invoiceId': confirmation.invoice.id.toString(),
                            'pickup': confirmation.shipment.pickupDateTime,
                          },
                        },
                      ).toString(),
                    );
                  },
                  icon: const Icon(Icons.assignment_turned_in_outlined),
                  label: const Text('View order confirmation'),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Payment',
      subtitle: 'Choose a mock payment method for this shipment.',
      body: FutureBuilder<CheckoutData>(
        future: _checkoutFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading checkout details');
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Unable to load checkout details.';

            return ErrorStateWidget(
              title: 'Checkout unavailable',
              message: message,
              onRetry: _retryCheckout,
            );
          }

          _checkout = snapshot.data!;
          final checkout = _checkout!;
          final alreadyPaid = checkout.payment?.paymentStatus == 'paid';

          return Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PaymentShipmentCard(shipment: checkout.shipment),
                const SizedBox(height: AppSpacing.lg),
                _PriceBreakdown(
                  baseFare: _baseFare,
                  distanceCharge: _distanceCharge,
                  handlingFee: _handlingFee,
                  insuranceFee: _insuranceFee,
                  taxes: _taxes,
                  couponDiscount: _couponDiscount,
                  total: _total,
                ),
                const SizedBox(height: AppSpacing.lg),
                _CouponField(
                  controller: _couponController,
                  onApply: _isPaying ? null : _applyCoupon,
                  validator: _validateCoupon,
                ),
                const SizedBox(height: AppSpacing.lg),
                _PaymentMethodSelector(
                  selected: _selectedMethod,
                  availableMethods: checkout.paymentMethods,
                  onChanged: _isPaying
                      ? null
                      : (method) => setState(() => _selectedMethod = method),
                ),
                if (_selectedMethod == _PaymentMethod.card) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CardFields(
                    cardNumberController: _cardNumberController,
                    cardNameController: _cardNameController,
                    expiryController: _expiryController,
                    cvvController: _cvvController,
                    isEnabled: !_isPaying,
                    validateCardNumber: _validateCardNumber,
                    validateCardName: _validateCardName,
                    validateExpiry: _validateExpiry,
                    validateCvv: _validateCvv,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                CheckboxListTile(
                  value: _acceptedTerms,
                  onChanged: _isPaying
                      ? null
                      : (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text(
                    'I agree to the mock payment terms and cancellation policy.',
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton.icon(
                  onPressed: _isPaying
                      ? null
                      : alreadyPaid
                      ? () => _openExistingConfirmation(checkout)
                      : _payNow,
                  icon: _isPaying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.textInverse,
                          ),
                        )
                      : Icon(
                          alreadyPaid
                              ? Icons.assignment_turned_in_outlined
                              : Icons.lock_rounded,
                        ),
                  label: Text(
                    _isPaying
                        ? 'Processing...'
                        : alreadyPaid
                        ? 'View confirmation'
                        : 'Pay now',
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: TextButton.icon(
                    onPressed: _isPaying ? null : _showFailureDemo,
                    icon: const Icon(Icons.error_outline_rounded),
                    label: const Text('Show failure summary'),
                  ),
                ),
                Center(
                  child: Text(
                    'No actual payment will be processed.',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PaymentShipmentCard extends StatelessWidget {
  const _PaymentShipmentCard({required this.shipment});

  final CustomerShipment shipment;

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
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.textInverse.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
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
                  shipment.shipmentCode,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.textInverse,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '${shipment.pickupAddress} - ${shipment.packageType}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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

class _PriceBreakdown extends StatelessWidget {
  const _PriceBreakdown({
    required this.baseFare,
    required this.distanceCharge,
    required this.handlingFee,
    required this.insuranceFee,
    required this.taxes,
    required this.couponDiscount,
    required this.total,
  });

  final int baseFare;
  final int distanceCharge;
  final int handlingFee;
  final int insuranceFee;
  final int taxes;
  final int couponDiscount;
  final int total;

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
                  Icons.receipt_long_rounded,
                  color: AppColors.primaryBlue,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Amount summary',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _PriceLine(label: 'Base fare', amount: baseFare),
            _PriceLine(label: 'Distance charge', amount: distanceCharge),
            _PriceLine(label: 'Handling fee', amount: handlingFee),
            _PriceLine(label: 'Insurance fee', amount: insuranceFee),
            _PriceLine(label: 'Taxes and fees', amount: taxes),
            if (couponDiscount > 0)
              _PriceLine(
                label: 'Coupon discount',
                amount: -couponDiscount,
                isDiscount: true,
              ),
            const Divider(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Payable now',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  _money(total),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.primaryNavy,
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

class _PriceLine extends StatelessWidget {
  const _PriceLine({
    required this.label,
    required this.amount,
    this.isDiscount = false,
  });

  final String label;
  final int amount;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final color = isDiscount ? AppColors.success : AppColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            isDiscount ? '- ${_money(amount.abs())}' : _money(amount),
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CouponField extends StatelessWidget {
  const _CouponField({
    required this.controller,
    required this.onApply,
    required this.validator,
  });

  final TextEditingController controller;
  final VoidCallback? onApply;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      textCapitalization: TextCapitalization.characters,
      decoration: InputDecoration(
        labelText: 'Coupon code',
        hintText: 'Try CARGO10',
        prefixIcon: const Icon(Icons.local_offer_outlined),
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: TextButton(onPressed: onApply, child: const Text('Apply')),
        ),
      ),
      validator: validator,
    );
  }
}

class _PaymentMethodSelector extends StatelessWidget {
  const _PaymentMethodSelector({
    required this.selected,
    required this.availableMethods,
    required this.onChanged,
  });

  final _PaymentMethod selected;
  final List<String> availableMethods;
  final ValueChanged<_PaymentMethod>? onChanged;

  static const _methods = [
    _PaymentMethodData(
      method: _PaymentMethod.upi,
      label: 'UPI',
      description: 'Mock instant transfer',
      icon: Icons.qr_code_2_rounded,
    ),
    _PaymentMethodData(
      method: _PaymentMethod.card,
      label: 'Card',
      description: 'Credit or debit card',
      icon: Icons.credit_card_rounded,
    ),
    _PaymentMethodData(
      method: _PaymentMethod.cash,
      label: 'Mock cash',
      description: 'Cash on delivery placeholder',
      icon: Icons.payments_outlined,
    ),
    _PaymentMethodData(
      method: _PaymentMethod.wallet,
      label: 'Wallet',
      description: 'Wallet placeholder',
      icon: Icons.account_balance_wallet_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final methods = _methods
        .where(
          (method) =>
              availableMethods.isEmpty ||
              availableMethods.contains(_methodValue(method.method)),
        )
        .toList(growable: false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final method in methods) ...[
              _PaymentMethodTile(
                data: method,
                isSelected: selected == method.method,
                onTap: onChanged == null
                    ? null
                    : () => onChanged!(method.method),
              ),
              if (method != methods.last) const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  final _PaymentMethodData data;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(data.icon, color: AppColors.primaryBlue),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.label,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    data.description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            Icon(
              isSelected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: isSelected
                  ? AppColors.primaryBlue
                  : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardFields extends StatelessWidget {
  const _CardFields({
    required this.cardNumberController,
    required this.cardNameController,
    required this.expiryController,
    required this.cvvController,
    required this.isEnabled,
    required this.validateCardNumber,
    required this.validateCardName,
    required this.validateExpiry,
    required this.validateCvv,
  });

  final TextEditingController cardNumberController;
  final TextEditingController cardNameController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final bool isEnabled;
  final FormFieldValidator<String> validateCardNumber;
  final FormFieldValidator<String> validateCardName;
  final FormFieldValidator<String> validateExpiry;
  final FormFieldValidator<String> validateCvv;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card details',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: cardNumberController,
              enabled: isEnabled,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Card number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card_rounded),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(16),
              ],
              validator: validateCardNumber,
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: cardNameController,
              enabled: isEnabled,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Cardholder name',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              validator: validateCardName,
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expiryController,
                    enabled: isEnabled,
                    keyboardType: TextInputType.datetime,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Expiry',
                      hintText: 'MM/YY',
                      prefixIcon: Icon(Icons.event_outlined),
                    ),
                    inputFormatters: [LengthLimitingTextInputFormatter(5)],
                    validator: validateExpiry,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextFormField(
                    controller: cvvController,
                    enabled: isEnabled,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      prefixIcon: Icon(Icons.lock_outline_rounded),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: validateCvv,
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

class _PaymentMethodData {
  const _PaymentMethodData({
    required this.method,
    required this.label,
    required this.description,
    required this.icon,
  });

  final _PaymentMethod method;
  final String label;
  final String description;
  final IconData icon;
}

String _methodValue(_PaymentMethod method) {
  return switch (method) {
    _PaymentMethod.upi => 'upi',
    _PaymentMethod.card => 'card',
    _PaymentMethod.cash => 'cash',
    _PaymentMethod.wallet => 'wallet',
  };
}

String _methodLabel(_PaymentMethod method) {
  return switch (method) {
    _PaymentMethod.upi => 'UPI',
    _PaymentMethod.card => 'card',
    _PaymentMethod.cash => 'mock cash',
    _PaymentMethod.wallet => 'wallet',
  };
}

String _money(int value) {
  final text = value.toString();
  if (text.length <= 3) {
    return 'INR $text';
  }

  final lastThree = text.substring(text.length - 3);
  var leading = text.substring(0, text.length - 3);
  final groups = <String>[];
  while (leading.length > 2) {
    groups.insert(0, leading.substring(leading.length - 2));
    leading = leading.substring(0, leading.length - 2);
  }
  if (leading.isNotEmpty) {
    groups.insert(0, leading);
  }

  return 'INR ${[...groups, lastThree].join(',')}';
}
