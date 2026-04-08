import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moyasar/moyasar.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/auctions/data/auction_payments_repository.dart';

import '../../../core/common_widgets/custom_card.dart';
import '../../../core/constants/app_strings/app_strings.dart';
import '../../../core/helper/analytics/analytics_service.dart';
import '../../../core/helper/cache/cached_variables.dart';
import '../../addresses/domain/user_address_model.dart';
import '../../addresses/presentation/address_selection_screen.dart';
import '../../cart/data/cart_repository.dart';
import '../data/order_repository.dart';
import '../domain/order_model.dart';
import '../../main_screen.dart';

enum UnifiedPaymentMethod { creditCard, bankTransfer }

class OrderConfirmationScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final UserAddressModel? preselectedAddress;

  const OrderConfirmationScreen({
    super.key,
    required this.order,
    this.preselectedAddress,
  });

  @override
  ConsumerState<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState
    extends ConsumerState<OrderConfirmationScreen> {
  UserAddressModel? _selectedAddress;

  UnifiedPaymentMethod _paymentMethod = UnifiedPaymentMethod.bankTransfer;
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;
  String? _errorMessage;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  @override
  void initState() {
    super.initState();
    _selectedAddress = widget.preselectedAddress;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.logScreenView(
        screenName: 'order_confirmation',
        screenClass: 'OrderConfirmationScreen',
      );
      AnalyticsService.logBeginCheckout(
        value: widget.order.total,
        itemCount: widget.order.items.isNotEmpty ? widget.order.items.length : 1,
        hasAuctionItems: widget.order.auctionId != 0,
      );
    });
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.of(context).push<UserAddressModel>(
      MaterialPageRoute(
        builder: (context) => AddressSelectionScreen(
          preselectedAddressId: _selectedAddress?.id ?? widget.order.addressId,
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() => _selectedAddress = result);
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'gif', 'pdf'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > _maxFileSizeBytes) {
          setState(() {
            _errorMessage = AppStrings.fileSizeExceeded.tr();
            _selectedFile = null;
          });
          return;
        }
        setState(() {
          _selectedFile = file;
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    }
  }

  Future<OrderModel?> _syncOrderDetails() async {
    try {
      final updatedOrderData = widget.order.copyWith(
        addressId: _selectedAddress!.id,
      );

      if (widget.order.id == 0) {
        return await ref
            .read(orderRepositoryProvider)
            .createOrder(updatedOrderData);
      } else {
        return await ref
            .read(orderRepositoryProvider)
            .updateOrder(updatedOrderData);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString());
      return null;
    }
  }

  Future<void> _handleSubmit() async {
    if (_selectedAddress == null) {
      setState(() => _errorMessage = AppStrings.selectAddress.tr());
      return;
    }

    if (_paymentMethod == UnifiedPaymentMethod.bankTransfer &&
        (_selectedFile == null || _selectedFile!.path == null)) {
      setState(() => _errorMessage = AppStrings.selectFile.tr());
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    final finalizedOrder = await _syncOrderDetails();
    if (finalizedOrder == null) {
      setState(() => _isSubmitting = false);
      return;
    }

    if (_paymentMethod == UnifiedPaymentMethod.bankTransfer) {
      try {
        if (finalizedOrder.auctionId != 0) {
          await ref
              .read(auctionPaymentsRepositoryProvider)
              .uploadReceipt(
                userId: finalizedOrder.userId,
                auctionId: finalizedOrder.auctionId,
                productId:
                    (finalizedOrder.items.firstOrNull?.auctionProductId ??
                        finalizedOrder.items.firstOrNull?.productId) ??
                    0,
                orderId: finalizedOrder.id,
                amount: finalizedOrder.total.toInt(),
                filePath: _selectedFile!.path!,
              );
        } else {
          await ref
              .read(orderRepositoryProvider)
              .uploadStoreReceipt(
                userId: finalizedOrder.userId,
                orderId: finalizedOrder.id,
                amount: finalizedOrder.total.toInt(),
                filePath: _selectedFile!.path!,
              );
        }

        if (mounted) {
          await AnalyticsService.logPaymentSubmitted(
            orderId: finalizedOrder.id,
            amount: finalizedOrder.total,
            method: 'bank_transfer',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.orderSubmittedSuccessfully.tr()),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
          ref.read(mainScreenTabIndexProvider.notifier).state = 3;
          ref.invalidate(userWinningAuctionsProvider);
          ref.invalidate(getUserOrdersProvider);
          if (CachedVariables.userId != null) {
            ref.invalidate(cartProvider(CachedVariables.userId!));
          }
        }
      } catch (e) {
        setState(() => _errorMessage = e.toString());
      }
    }

    if (mounted) setState(() => _isSubmitting = false);
  }

  Future<void> _handleMoyasarResult(dynamic result) async {
    if (result is PaymentResponse) {
      if (result.status == PaymentStatus.paid) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) =>
              const Center(child: CircularProgressIndicator()),
        );

        try {
          final finalizedOrder = await _syncOrderDetails();
          if (finalizedOrder != null) {
            final updatedOrder = finalizedOrder.copyWith(
              paymentStatus: 'paid',
              paymentId: result.id,
            );
            await ref.read(orderRepositoryProvider).updateOrder(updatedOrder);
            await AnalyticsService.logPurchase(
              orderId: updatedOrder.id.toString(),
              value: updatedOrder.total,
              itemCount: updatedOrder.items.isNotEmpty
                  ? updatedOrder.items.length
                  : 1,
              hasAuctionItems: updatedOrder.auctionId != 0,
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error saving order: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) Navigator.pop(context);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.popUntil(context, (route) => route.isFirst);
          ref.read(mainScreenTabIndexProvider.notifier).state = 3;
          ref.invalidate(userWinningAuctionsProvider);
          ref.invalidate(getUserOrdersProvider);
          if (CachedVariables.userId != null) {
            ref.invalidate(cartProvider(CachedVariables.userId!));
          }
        }
      } else if (result.status == PaymentStatus.failed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final paymentConfig = PaymentConfig(
      publishableApiKey: 'pk_live_oZiKtWnZr9yzgyoxhVKhKXtLG1Cbt3emJ3kRLGgW',
      amount: (widget.order.total * 100).round(),
      description: 'Order #${widget.order.id != 0 ? widget.order.id : "New"}',
      metadata: {
        'user_id': widget.order.userId,
        'auction_id': widget.order.auctionId,
      },
      applePay: Platform.isIOS
          ? ApplePayConfig(
              merchantId: 'merchant.turathy.sa',
              label: 'Turathy',
              manual: false,
              saveCard: false,
            )
          : null,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.orderConfirmation.tr()),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSectionTitle(theme, AppStrings.orderSummary.tr()),
            CustomCard(
              child: Column(
                children: [
                  ...List.generate(widget.order.items.length, (index) {
                    final item = widget.order.items[index];
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.fullImageUrl,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                        width: 50,
                                        height: 50,
                                        color: Colors.grey[200],
                                        child: const Icon(
                                          Icons.image,
                                          size: 20,
                                        ),
                                      ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(fontSize: 13),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          '${item.quantity} x ${item.price} ',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.grey),
                                        ),
                                        SvgPicture.asset(
                                          'assets/icons/RSA.svg',
                                          height: 10,
                                          colorFilter: const ColorFilter.mode(
                                            Colors.grey,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (index < widget.order.items.length - 1)
                          const Divider(),
                      ],
                    );
                  }),
                  const Divider(thickness: 1.2),
                  _buildDetailRow(
                    theme,
                    AppStrings.totalAmount.tr(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${widget.order.total} ',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        SvgPicture.asset(
                          'assets/icons/RSA.svg',
                          height: 12,
                          colorFilter: ColorFilter.mode(
                            theme.colorScheme.primary,
                            BlendMode.srcIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Shipping Address Section
            _buildSectionTitle(theme, AppStrings.shippingDetails.tr()),
            _buildAddressSection(theme),
            const SizedBox(height: 16),

            _buildSectionTitle(theme, AppStrings.paymentMethod.tr()),
            Row(
              children: [
                Expanded(
                  child: _buildPaymentTile(
                    Icons.credit_card,
                    AppStrings.cardPayment.tr(),
                    UnifiedPaymentMethod.creditCard,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPaymentTile(
                    Icons.account_balance,
                    AppStrings.bankTransfer.tr(),
                    UnifiedPaymentMethod.bankTransfer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_paymentMethod == UnifiedPaymentMethod.bankTransfer)
              _buildBankTransferSection(theme),
            if (_paymentMethod == UnifiedPaymentMethod.creditCard)
              _buildCreditCardSection(paymentConfig, theme),

            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 24),
            if (_paymentMethod == UnifiedPaymentMethod.bankTransfer)
              ElevatedButton(
                onPressed: _isSubmitting ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(AppStrings.submitOrder.tr()),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    if (_selectedAddress != null) {
      return CustomCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppStrings.selectedAddress.tr(),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                TextButton.icon(
                  onPressed: _pickAddress,
                  icon: const Icon(Icons.edit, size: 16),
                  label: Text(AppStrings.changeAddress.tr()),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (_selectedAddress!.label != null)
              Text(
                _selectedAddress!.label!,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              _selectedAddress!.name,
              style: TextStyle(color: Colors.grey[700]),
            ),
            Text(
              _selectedAddress!.mobile,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              _selectedAddress!.fullAddress,
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    // No address selected yet — big "Select Address" button
    return InkWell(
      onTap: _pickAddress,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.5),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.location_on, size: 40, color: theme.colorScheme.primary),
            const SizedBox(height: 8),
            Text(
              AppStrings.selectAddress.tr(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(ThemeData theme, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    ThemeData theme,
    String label,
    dynamic value, {
    bool isPrice = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          if (isPrice)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                value,
                SvgPicture.asset(
                  'assets/icons/RSA.svg',
                  height: 12,
                  colorFilter: ColorFilter.mode(
                    theme.colorScheme.primary,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            )
          else if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentTile(
    IconData icon,
    String label,
    UnifiedPaymentMethod method,
  ) {
    final isSelected = _paymentMethod == method;
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => setState(() => _paymentMethod = method),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withOpacity(0.3),
            width: isSelected ? 2 : 1,
          ),
          color: isSelected
              ? theme.colorScheme.primaryContainer.withOpacity(0.1)
              : null,
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBankTransferSection(ThemeData theme) {
    return Column(
      children: [
        CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBankInfoRow('Bank', 'Al Rajhi Bank', theme),
              _buildBankInfoRow('Account Name', 'Turathy Co.', theme),
              _buildBankInfoRow('IBAN', 'SA00 0000 0000 0000 0000 0000', theme),
            ],
          ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickFile,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedFile != null
                    ? theme.colorScheme.primary
                    : Colors.grey.withOpacity(0.5),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: _selectedFile != null
                  ? theme.colorScheme.primaryContainer.withOpacity(0.1)
                  : null,
            ),
            child: Column(
              children: [
                Icon(
                  _selectedFile != null
                      ? Icons.check_circle
                      : Icons.upload_file,
                  color: _selectedFile != null
                      ? theme.colorScheme.primary
                      : Colors.grey,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(_selectedFile?.name ?? AppStrings.uploadReceipt.tr()),
              ],
            ),
          ),
        ),
        if (_selectedFile != null &&
            _selectedFile!.path != null &&
            !_selectedFile!.name.endsWith('.pdf'))
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_selectedFile!.path!),
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBankInfoRow(String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditCardSection(PaymentConfig config, ThemeData theme) {
    return Column(
      children: [
        if (Platform.isIOS)
          ApplePay(config: config, onPaymentResult: _handleMoyasarResult),
        CreditCard(config: config, onPaymentResult: _handleMoyasarResult),
        const SizedBox(height: 16),
        Text(
          'Note: Clicking pay will automatically save your shipping details.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
        ),
      ],
    );
  }
}
