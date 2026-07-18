import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_shadows.dart';
import '../../core/constants/app_spacing.dart';
import '../../core/network/api_exception.dart';
import '../../core/utils/file_downloader.dart';
import '../../core/widgets/common_app_scaffold.dart';
import '../../core/widgets/error_state_widget.dart';
import '../../core/widgets/loading_widget.dart';
import '../shipment/data/customer_shipment_api.dart';

class InvoiceScreen extends ConsumerStatefulWidget {
  const InvoiceScreen({super.key, required this.invoiceId});

  final String? invoiceId;

  @override
  ConsumerState<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends ConsumerState<InvoiceScreen> {
  late Future<InvoicePreviewData> _invoiceFuture;
  bool _isDownloading = false;
  int? _resolvedInvoiceId;

  @override
  void initState() {
    super.initState();
    _invoiceFuture = _loadInvoice();
  }

  Future<InvoicePreviewData> _loadInvoice() async {
    final api = ref.read(customerShipmentApiProvider);
    final invoiceId = int.tryParse(widget.invoiceId ?? '');
    if (invoiceId != null) {
      _resolvedInvoiceId = invoiceId;
      return api.getInvoicePreview(invoiceId);
    }

    final history = await api.listShipmentHistory(
      paymentStatus: 'paid',
      limit: 20,
    );

    for (final shipment in history.shipments) {
      final details = await api.getShipmentDetails(shipment.id);
      final invoice = details.invoice;
      if (invoice != null) {
        _resolvedInvoiceId = invoice.id;
        return api.getInvoicePreview(invoice.id);
      }
    }

    throw const ApiException(
      message: 'No paid invoice is available for this customer yet.',
    );
  }

  void _retry() {
    setState(() => _invoiceFuture = _loadInvoice());
  }

  Future<void> _downloadPdf() async {
    final invoiceId =
        _resolvedInvoiceId ?? int.tryParse(widget.invoiceId ?? '');
    if (invoiceId == null || _isDownloading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Open a generated invoice before downloading the PDF.'),
        ),
      );
      return;
    }

    setState(() => _isDownloading = true);

    try {
      final download = await ref
          .read(customerShipmentApiProvider)
          .downloadInvoicePdf(invoiceId);
      final started = await downloadBytes(
        bytes: download.bytes,
        filename: download.filename,
        mimeType: 'application/pdf',
      );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            started
                ? 'Invoice PDF download started.'
                : 'Invoice PDF received from API (${download.bytes.length} bytes).',
          ),
        ),
      );
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  void _showPlaceholder(BuildContext context, String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$action is not exposed by the current local customer API.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CommonAppScaffold(
      title: 'Invoice preview',
      subtitle: 'Logistics invoice generated for this shipment.',
      body: FutureBuilder<InvoicePreviewData>(
        future: _invoiceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingWidget(message: 'Loading invoice preview');
          }

          if (snapshot.hasError) {
            final message = snapshot.error is ApiException
                ? (snapshot.error! as ApiException).message
                : 'Unable to load invoice preview.';

            return ErrorStateWidget(
              title: 'Invoice unavailable',
              message: message,
              onRetry: _retry,
            );
          }

          final preview = snapshot.data!;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _InvoiceDocument(preview: preview),
              const SizedBox(height: AppSpacing.lg),
              _InvoiceActions(
                isDownloading: _isDownloading,
                onDownload: _downloadPdf,
                onShare: () => _showPlaceholder(context, 'Share invoice'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InvoiceDocument extends StatelessWidget {
  const _InvoiceDocument({required this.preview});

  final InvoicePreviewData preview;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _InvoiceHeader(company: preview.company),
          const Divider(height: 1),
          _InvoiceMetaSection(invoice: preview.invoice),
          const Divider(height: 1),
          _CustomerAndShipmentSection(preview: preview),
          const Divider(height: 1),
          _ChargeBreakdown(invoice: preview.invoice, payment: preview.payment),
          const Divider(height: 1),
          _PaymentSummary(invoice: preview.invoice, payment: preview.payment),
        ],
      ),
    );
  }
}

class _InvoiceHeader extends StatelessWidget {
  const _InvoiceHeader({required this.company});

  final CompanyInfo company;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.primaryNavy,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.cardRadius),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.roadYellow,
                  borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
                ),
                child: const Icon(
                  Icons.local_shipping_rounded,
                  color: AppColors.primaryNavy,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${company.name} Logistics Pvt. Ltd.',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.textInverse,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'GSTIN: 27AABCC2403L1Z8 | PAN: AABCC2403L',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.surfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            company.address,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            company.email,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.surfaceMuted),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetaSection extends StatelessWidget {
  const _InvoiceMetaSection({required this.invoice});

  final InvoiceRecord invoice;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Wrap(
        spacing: AppSpacing.lg,
        runSpacing: AppSpacing.md,
        children: [
          _MetaTile(label: 'Invoice number', value: invoice.invoiceNumber),
          _MetaTile(
            label: 'Invoice date',
            value: _formatDate(invoice.issuedAt),
          ),
          _MetaTile(label: 'Booking ID', value: 'SHP-${invoice.shipmentId}'),
          _MetaTile(
            label: 'Payment status',
            valueWidget: _PaidBadge(label: _statusLabel(invoice.paymentStatus)),
          ),
        ],
      ),
    );
  }
}

class _CustomerAndShipmentSection extends StatelessWidget {
  const _CustomerAndShipmentSection({required this.preview});

  final InvoicePreviewData preview;

  @override
  Widget build(BuildContext context) {
    final invoice = preview.invoice;
    final shipment = preview.shipment;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          _InfoPanel(
            title: 'Billed to',
            icon: Icons.person_outline_rounded,
            rows: [
              _InfoRow(label: 'Customer', value: invoice.billingName),
              _InfoRow(label: 'Email', value: invoice.billingEmail ?? '-'),
              _InfoRow(label: 'Phone', value: invoice.billingPhone ?? '-'),
              _InfoRow(
                label: 'Billing address',
                value: invoice.billingAddress?.isNotEmpty == true
                    ? invoice.billingAddress!
                    : '-',
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _InfoPanel(
            title: 'Shipment info',
            icon: Icons.inventory_2_outlined,
            rows: [
              _InfoRow(
                label: 'Route',
                value:
                    '${shipment.pickupAddress} to ${shipment.deliveryAddress}',
              ),
              _InfoRow(
                label: 'Package',
                value:
                    '${shipment.packageType}, ${_number(shipment.packageWeightKg)} kg',
              ),
              _InfoRow(
                label: 'Vehicle',
                value: _vehicleLabel(shipment.vehiclePreference),
              ),
              _InfoRow(
                label: 'Distance',
                value: '${_number(shipment.estimatedDistanceKm)} km estimated',
              ),
              _InfoRow(
                label: 'Pickup slot',
                value: _formatDateTime(shipment.pickupDateTime),
              ),
              _InfoRow(label: 'Receiver', value: shipment.receiverName),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChargeBreakdown extends StatelessWidget {
  const _ChargeBreakdown({required this.invoice, required this.payment});

  final InvoiceRecord invoice;
  final PaymentRecord? payment;

  @override
  Widget build(BuildContext context) {
    final paymentRecord = payment;
    final feeAmount = paymentRecord?.feeAmount ?? 0;
    final subtotal = invoice.subtotalAmount.round();
    final tax = invoice.taxAmount.round();
    final discount = invoice.discountAmount.round();
    final total = invoice.totalAmount.round();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
                'Charge breakdown',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _AmountRow(label: 'Base freight subtotal', amount: subtotal),
          if (feeAmount > 0)
            _AmountRow(
              label: 'Platform and service fee',
              amount: feeAmount.round(),
            ),
          if (discount > 0)
            _AmountRow(label: 'Discount', amount: -discount, isDiscount: true),
          const Divider(height: AppSpacing.lg),
          _AmountRow(
            label: 'Taxable subtotal',
            amount: subtotal,
            isStrong: true,
          ),
          _AmountRow(label: 'GST and platform taxes', amount: tax),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceMuted,
              borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            ),
            child: _AmountRow(
              label: 'Invoice total',
              amount: total,
              isTotal: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentSummary extends StatelessWidget {
  const _PaymentSummary({required this.invoice, required this.payment});

  final InvoiceRecord invoice;
  final PaymentRecord? payment;

  @override
  Widget build(BuildContext context) {
    final paymentRecord = payment;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.verified_rounded,
                color: AppColors.success,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Payment summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.lg,
            runSpacing: AppSpacing.md,
            children: [
              _MetaTile(
                label: 'Payment method',
                value: _paymentMethodLabel(paymentRecord?.paymentMethod),
              ),
              _MetaTile(
                label: 'Transaction ID',
                value: paymentRecord?.transactionReference ?? '-',
              ),
              _MetaTile(
                label: 'Paid on',
                value: _formatDateTime(paymentRecord?.paidAt),
              ),
              _MetaTile(
                label: 'Settlement status',
                valueWidget: _PaidBadge(
                  label: _statusLabel(invoice.paymentStatus),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'This invoice was generated from the CargoConnect backend after mock payment confirmation.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _InvoiceActions extends StatelessWidget {
  const _InvoiceActions({
    required this.isDownloading,
    required this.onDownload,
    required this.onShare,
  });

  final bool isDownloading;
  final VoidCallback onDownload;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ElevatedButton.icon(
          onPressed: isDownloading ? null : onDownload,
          icon: isDownloading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.textInverse,
                  ),
                )
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(isDownloading ? 'Downloading...' : 'Download PDF'),
        ),
        OutlinedButton.icon(
          onPressed: onShare,
          icon: const Icon(Icons.ios_share_rounded),
          label: const Text('Share'),
        ),
      ],
    );
  }
}

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRow> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryBlue, size: 20),
              const SizedBox(width: AppSpacing.xs),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          for (final row in rows) ...[
            row,
            if (row != rows.last) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 118,
          child: Text(label, style: Theme.of(context).textTheme.labelMedium),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.label, this.value, this.valueWidget});

  final String label;
  final String? value;
  final Widget? valueWidget;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: AppSpacing.xxs),
          valueWidget ??
              Text(
                value ?? '',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.amount,
    this.isStrong = false,
    this.isTotal = false,
    this.isDiscount = false,
  });

  final String label;
  final int amount;
  final bool isStrong;
  final bool isTotal;
  final bool isDiscount;

  @override
  Widget build(BuildContext context) {
    final textStyle = isTotal
        ? Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.primaryNavy,
            fontWeight: FontWeight.w900,
          )
        : Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: isDiscount ? AppColors.success : null,
            fontWeight: isStrong ? FontWeight.w800 : FontWeight.w600,
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: textStyle)),
          Text(
            isDiscount ? '- ${_money(amount.abs())}' : _money(amount),
            style: textStyle,
          ),
        ],
      ),
    );
  }
}

class _PaidBadge extends StatelessWidget {
  const _PaidBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE8F7ED),
        borderRadius: BorderRadius.circular(AppSpacing.xs),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.success,
            fontSize: 12,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );
  }
}

String _formatDate(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return '-';
  }

  return '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
}

String _formatDateTime(String? value) {
  final parsed = DateTime.tryParse(value ?? '');
  if (parsed == null) {
    return value?.isNotEmpty == true ? value! : '-';
  }

  final day = parsed.day.toString().padLeft(2, '0');
  final month = parsed.month.toString().padLeft(2, '0');
  final year = parsed.year.toString();
  final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
  final minute = parsed.minute.toString().padLeft(2, '0');
  final period = parsed.hour >= 12 ? 'PM' : 'AM';
  return '$day/$month/$year, $hour:$minute $period';
}

String _paymentMethodLabel(String? value) {
  return switch (value) {
    'upi' => 'UPI mock payment',
    'card' => 'Card mock payment',
    'cash' => 'Mock cash payment',
    'wallet' => 'Wallet placeholder',
    _ => value ?? '-',
  };
}

String _statusLabel(String value) {
  if (value.isEmpty) {
    return '-';
  }
  return value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
}

String _vehicleLabel(String value) {
  return switch (value) {
    'bike' => 'Bike or mini van',
    'mini_truck' => 'Pickup truck',
    'truck' => '14 ft truck',
    'heavy_truck' => '32 ft container',
    'refrigerated_truck' => 'Reefer vehicle',
    'van' => 'Cushioned van',
    _ => value.replaceAll('_', ' '),
  };
}

String _number(double value) {
  if (value % 1 == 0) {
    return value.round().toString();
  }
  return value.toStringAsFixed(1);
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
