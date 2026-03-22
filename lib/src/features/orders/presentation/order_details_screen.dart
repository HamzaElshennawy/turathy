import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/features/auctions/data/auction_payments_repository.dart';
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';
import 'package:turathy/src/features/addresses/domain/user_address_model.dart';
import 'package:turathy/src/features/addresses/presentation/address_selection_screen.dart';

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final String? productImage;

  const OrderDetailsScreen({super.key, required this.order, this.productImage});

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  late OrderModel _currentOrder;
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  String? _errorMessage;

  static const int _maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
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
      if (mounted) setState(() => _errorMessage = e.toString());
    }
  }

  Future<void> _uploadReceipt() async {
    if (_selectedFile == null || _selectedFile!.path == null) {
      setState(() => _errorMessage = AppStrings.selectFile.tr());
      return;
    }

    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });

    try {
      if (_currentOrder.auctionId != 0) {
        await ref
            .read(auctionPaymentsRepositoryProvider)
            .uploadReceipt(
              userId: _currentOrder.userId,
              auctionId: _currentOrder.auctionId,
              productId:
                  _currentOrder.items.firstOrNull?.productId ??
                  _currentOrder.items.firstOrNull?.auctionProductId ??
                  0,
              orderId: _currentOrder.id,
              amount: _currentOrder.total.toInt(),
              filePath: _selectedFile!.path!,
            );
      } else {
        await ref
            .read(orderRepositoryProvider)
            .uploadStoreReceipt(
              userId: _currentOrder.userId,
              orderId: _currentOrder.id,
              amount: _currentOrder.total.toInt(),
              filePath: _selectedFile!.path!,
            );
      }

      if (mounted) {
        ref.invalidate(getUserOrdersProvider);

        setState(() {
          _currentOrder = _currentOrder.copyWith(
            paymentStatus: 'initiated',
            orderStatus: 'pending_approval',
          );
          _selectedFile = null;
        });

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 16),
                Text(
                  AppStrings.receiptUploadedSuccessfully.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    AppStrings.ok.tr(),
                    //style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final order = _currentOrder;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppStrings.orderDetails.tr()),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildStatusHeader(order),
            _buildOrderInfo(order, theme),
            _buildProductSection(order, theme),
            _buildShippingSection(order, theme),
            _buildTimelineSection(order, theme),
            if (order.paymentStatus == null ||
                order.paymentStatus == 'rejected')
              _buildUploadReceiptSection(theme),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order) {
    final status = order.orderStatus?.toLowerCase() ?? 'pending';
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case 'confirmed':
        color = Colors.green;
        icon = Icons.check_circle;
        text = AppStrings.completed.tr();
        break;
      case 'pending_approval':
        color = Colors.orange;
        icon = Icons.history;
        text = AppStrings.waitingForApproval.tr();
        break;
      case 'shipped':
        color = Colors.blue;
        icon = Icons.local_shipping;
        text = AppStrings.shipped.tr();
        break;
      case 'delivered':
        color = const Color(0xFF2D4739);
        icon = Icons.home;
        text = AppStrings.delivered.tr();
        break;
      case 'cancelled':
        color = Colors.red;
        icon = Icons.cancel;
        text = AppStrings.orderCanceled.tr();
        break;
      default:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        text = AppStrings.pending.tr();
    }

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 40),
          ),
          const SizedBox(height: 12),
          Text(
            text,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (order.refNo != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '#${order.refNo}',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
            ),
        ],
      ),
    );
  }

  String _translatePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return AppStrings.paymentApproved.tr();
      case 'rejected':
        return AppStrings.paymentRejected.tr();
      case 'initiated':
      case 'pending':
        return AppStrings.paymentPending.tr();
      default:
        return status;
    }
  }

  Widget _buildOrderInfo(OrderModel order, ThemeData theme) {
    return _buildCard(
      title: AppStrings.orderSummary.tr(),
      child: Column(
        children: [
          _buildInfoRow(
            AppStrings.orderDate.tr(),
            DateFormat('dd MMM yyyy').format(order.date),
          ),
          _buildInfoRow(
            AppStrings.totalAmount.tr(),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${order.total} ',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SvgPicture.asset('assets/icons/RSA.svg', height: 12),
              ],
            ),
          ),
          if (order.paymentStatus != null)
            _buildInfoRow(
              AppStrings.status.tr(),
              _translatePaymentStatus(order.paymentStatus!),
            ),
        ],
      ),
    );
  }

  Widget _buildProductSection(OrderModel order, ThemeData theme) {
    if (order.items.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      title: order.auctionId != 0
          ? AppStrings.auctionProducts.tr()
          : AppStrings.products.tr(),
      child: Column(
        children: order.items.map((item) {
          final imageUrl = item.fullImageUrl;
          final bool hasImage = imageUrl.isNotEmpty;
          final heroTag = 'order_product_${order.id}_${item.id}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: hasImage
                      ? () => AppFunctions.showImageDialog(
                          context: context,
                          imageUrl: imageUrl,
                          id: heroTag.hashCode,
                        )
                      : null,
                  child: Hero(
                    tag: heroTag.hashCode,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: hasImage
                          ? Image.network(
                              imageUrl,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                            )
                          : Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[200],
                              child: const Icon(Icons.image),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.localizedTitle(context.locale.languageCode),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (item
                          .localizedDescription(context.locale.languageCode)
                          .isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.localizedDescription(
                            context.locale.languageCode,
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${item.quantity} ${AppStrings.items.tr()}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${item.price} ',
                            style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
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
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildShippingSection(OrderModel order, ThemeData theme) {
    final status = order.orderStatus?.toLowerCase() ?? 'pending';
    final canEdit =
        ['pending', 'initiated', ''].contains(status) ||
        order.paymentStatus == null;

    return _buildCard(
      title: AppStrings.shippingDetails.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(AppStrings.name.tr(), order.cName),
          _buildInfoRow(AppStrings.mobileNumber.tr(), order.cMobile),
          _buildInfoRow(AppStrings.country.tr(), order.cCountry),
          _buildInfoRow(AppStrings.city.tr(), order.cCity),
          const SizedBox(height: 8),
          Text(
            AppStrings.address.tr(),
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(order.cAddress, style: const TextStyle(fontSize: 14)),
          if (order.deliveryCompany != null && order.deliveryCompany!.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            _buildInfoRow('Delivery Company'.tr(), order.deliveryCompany!),
            if (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)
              _buildInfoRow('Tracking Number'.tr(), order.trackingNumber!),
          ],
          if (canEdit) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _changeShippingAddress(order),
                icon: const Icon(Icons.edit_location_alt, size: 18),
                label: Text(AppStrings.editAddress.tr()),
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.colorScheme.primary,
                  side: BorderSide(color: theme.colorScheme.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _changeShippingAddress(OrderModel order) async {
    final selectedAddress = await Navigator.push<UserAddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AddressSelectionScreen(preselectedAddressId: order.addressId),
      ),
    );

    if (selectedAddress == null || !mounted) return;

    try {
      final updated = order.copyWith(addressId: selectedAddress.id);
      final result = await ref
          .read(orderRepositoryProvider)
          .updateOrder(updated);
      if (mounted) {
        // Merge the selected address data into the result so UI shows it
        final withAddress = result.copyWith(
          address: {
            'name': selectedAddress.name,
            'mobile': selectedAddress.mobile,
            'country': selectedAddress.country,
            'city': selectedAddress.city,
            'address': selectedAddress.address,
          },
        );
        setState(() => _currentOrder = withAddress);
        ref.invalidate(getUserOrdersProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.addressSavedSuccessfully.tr()),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTimelineSection(OrderModel order, ThemeData theme) {
    final status = order.orderStatus?.toLowerCase() ?? 'pending';

    return _buildCard(
      title: AppStrings.orderStatusTimeline.tr(),
      child: Column(
        children: [
          _buildTimelineItem(
            AppStrings.pending.tr(),
            AppStrings.orderCreatedWaiting.tr(),
            isFirst: true,
            isDone: true,
          ),
          _buildTimelineItem(
            AppStrings.waitingForApproval.tr(),
            AppStrings.receiptUploadedWaiting.tr(),
            isDone: [
              'pending_approval',
              'confirmed',
              'shipped',
              'delivered',
            ].contains(status),
            isActive: status == 'pending_approval',
          ),
          _buildTimelineItem(
            AppStrings.confirmed.tr(),
            AppStrings.paymentVerifiedConfirmed.tr(),
            isDone: ['confirmed', 'shipped', 'delivered'].contains(status),
            isActive: status == 'confirmed',
          ),
          _buildTimelineItem(
            AppStrings.shipped.tr(),
            AppStrings.itemOnItsWay.tr(),
            isDone: ['shipped', 'delivered'].contains(status),
            isActive: status == 'shipped',
          ),
          _buildTimelineItem(
            AppStrings.delivered.tr(),
            AppStrings.itemDeliveredSuccessfully.tr(),
            isLast: true,
            isDone: status == 'delivered',
            isActive: status == 'delivered',
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(
    String title,
    String subtitle, {
    bool isFirst = false,
    bool isLast = false,
    bool isDone = false,
    bool isActive = false,
  }) {
    return SizedBox(
      height: 70,
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 2,
                height: 10,
                color: isFirst
                    ? Colors.transparent
                    : (isDone ? const Color(0xFF2D4739) : Colors.grey[300]),
              ),
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: isDone
                      ? const Color(0xFF2D4739)
                      : (isActive ? Colors.orange : Colors.white),
                  border: Border.all(
                    color: isDone ? const Color(0xFF2D4739) : Colors.grey[300]!,
                    width: 2,
                  ),
                  shape: BoxShape.circle,
                ),
                child: isDone
                    ? const Icon(Icons.check, size: 8, color: Colors.white)
                    : null,
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: isLast
                      ? Colors.transparent
                      : (isDone ? const Color(0xFF2D4739) : Colors.grey[300]),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: fontWeightBold,
                    color: isDone
                        ? Colors.black
                        : (isActive ? Colors.orange : Colors.grey[600]),
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, dynamic value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          if (value is Widget)
            value
          else
            Text(
              value.toString(),
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: 14,
              ),
            ),
        ],
      ),
    );
  }

  static const FontWeight fontWeightBold = FontWeight.bold;
  Widget _buildUploadReceiptSection(ThemeData theme) {
    final isRejected = _currentOrder.paymentStatus == 'rejected';
    final title = isRejected
        ? AppStrings.uploadNewReceipt.tr()
        : AppStrings.uploadReceipt.tr();

    return _buildCard(
      title: title,
      child: Column(
        children: [
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
                  Text(_selectedFile?.name ?? title),
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
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isUploading ? null : _uploadReceipt,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(title),
            ),
          ),
        ],
      ),
    );
  }
}
