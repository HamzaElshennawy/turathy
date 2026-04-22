import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:turathy/src/core/constants/app_functions/app_functions.dart';
import 'package:turathy/src/core/constants/app_strings/app_strings.dart';
import 'package:turathy/src/core/helper/analytics/analytics_service.dart';
import 'package:turathy/src/core/helper/cache/cached_variables.dart';
import 'package:turathy/src/features/addresses/domain/user_address_model.dart';
import 'package:turathy/src/features/addresses/presentation/address_selection_screen.dart';
import 'package:turathy/src/features/auctions/data/auctions_repository.dart';
import 'package:turathy/src/features/cart/data/cart_repository.dart';
import 'package:turathy/src/features/orders/data/checkout_flow_coordinator.dart';
import 'package:turathy/src/features/orders/data/geidea_sdk_service.dart';
import 'package:turathy/src/features/orders/data/order_repository.dart';
import 'package:turathy/src/features/orders/domain/order_flow_state.dart';
import 'package:turathy/src/features/orders/domain/order_model.dart';
import 'package:turathy/src/features/orders/domain/saved_payment_method_model.dart';
import 'package:turathy/src/features/orders/presentation/widgets/card_checkout_section.dart';
import 'package:turathy/src/features/orders/utils/payment_debug_logger.dart';

enum UnifiedPaymentMethod { creditCard, bankTransfer }

class OrderDetailsScreen extends ConsumerStatefulWidget {
  final OrderModel order;
  final String? productImage;
  final UserAddressModel? preselectedAddress;

  const OrderDetailsScreen({
    super.key,
    required this.order,
    this.productImage,
    this.preselectedAddress,
  });

  @override
  ConsumerState<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends ConsumerState<OrderDetailsScreen> {
  static const int _maxFileSizeBytes = 5 * 1024 * 1024;
  static const bool _saveCardFeatureEnabled = bool.fromEnvironment(
    'GEIDEA_SAVE_CARD_ENABLED',
    defaultValue: true,
  );
  static const GeideaSdkService _geideaSdkService = GeideaSdkService();

  late OrderModel _currentOrder;
  UserAddressModel? _selectedAddress;
  PlatformFile? _selectedFile;
  UnifiedPaymentMethod _paymentMethod = UnifiedPaymentMethod.bankTransfer;
  bool _isSubmitting = false;
  bool _isUploading = false;
  bool _isCheckingGeideaStatus = false;
  bool _isLoadingSavedPaymentMethods = false;
  bool _isSavingCard = false;
  bool _saveCardForFutureUse = false;
  int? _selectedSavedPaymentMethodId;
  List<SavedPaymentMethodModel> _savedPaymentMethods = const [];

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
    _selectedAddress =
        widget.preselectedAddress ?? _addressFromOrder(widget.order);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      PaymentDebugLogger.info(
        'OrderDetailsScreen:init',
        data: {
          'orderId': _currentOrder.id,
          'auctionId': _currentOrder.auctionId,
          'paymentStatus': _currentOrder.paymentStatus,
          'orderStatus': _currentOrder.orderStatus,
          'saveCardFeatureEnabled': _saveCardFeatureEnabled,
          'saveCardForFutureUse': _saveCardForFutureUse,
        },
      );
      if (_saveCardFeatureEnabled) {
        _loadSavedPaymentMethods();
      }
      AnalyticsService.logScreenView(
        screenName: 'order_details',
        screenClass: 'OrderDetailsScreen',
      );
    });
  }

  bool get _showPaymentSection {
    final stage = OrderFlowState.stage(_currentOrder);
    return _currentOrder.id == 0 ||
        stage == OrderFlowStage.pending ||
        stage == OrderFlowStage.paymentRejected;
  }

  UserAddressModel? _addressFromOrder(OrderModel order) {
    if (order.addressId == null || order.address == null) {
      return null;
    }

    final address = order.address!;
    final name = address['name'] as String?;
    final mobile = address['mobile'] as String?;
    final country = address['country'] as String?;
    final city = address['city'] as String?;
    final street = address['address'] as String?;

    if (name == null ||
        mobile == null ||
        country == null ||
        city == null ||
        street == null) {
      return null;
    }

    return UserAddressModel(
      id: order.addressId!,
      userId: order.userId,
      label: address['label'] as String?,
      name: name,
      mobile: mobile,
      country: country,
      city: city,
      address: street,
      shortAddress: address['shortAddress'] as String?,
      isDefault: address['isDefault'] as bool? ?? false,
    );
  }

  String _friendlyErrorMessage(Object error, {required String fallback}) {
    final message = error.toString().toLowerCase();

    if (message.contains('404') || message.contains('not found')) {
      return AppStrings.orderNotAvailable.tr();
    }

    if (message.contains('socket') ||
        message.contains('timeout') ||
        message.contains('network') ||
        message.contains('connection')) {
      return AppStrings.checkInternetConnection.tr();
    }

    if (message.contains('address')) {
      return AppStrings.couldNotUpdateAddress.tr();
    }

    return fallback;
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    AppFunctions.showSnackBar(
      context: context,
      message: message,
      isError: true,
    );
  }

  Future<void> _loadSavedPaymentMethods() async {
    final userId = CachedVariables.userId;
    if (userId == null || !mounted) return;

    PaymentDebugLogger.info(
      'OrderDetailsScreen:loadSavedPaymentMethods:start',
      data: {'userId': userId},
    );
    setState(() => _isLoadingSavedPaymentMethods = true);
    try {
      final methods = await ref
          .read(checkoutFlowCoordinatorProvider)
          .getSavedPaymentMethods(userId: userId);
      if (!mounted) return;
      setState(() {
        _savedPaymentMethods = methods;
        final activeSelectionStillExists = methods.any(
          (method) => method.id == _selectedSavedPaymentMethodId,
        );
        if (!activeSelectionStillExists) {
          _selectedSavedPaymentMethodId = methods
              .cast<SavedPaymentMethodModel?>()
              .firstWhere(
                (method) => method?.isDefault ?? false,
                orElse: () => methods.isNotEmpty ? methods.first : null,
              )
              ?.id;
        }
      });
      PaymentDebugLogger.info(
        'OrderDetailsScreen:loadSavedPaymentMethods:success',
        data: {'userId': userId, 'count': methods.length},
      );
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:loadSavedPaymentMethods:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotLoadSavedCards.tr(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingSavedPaymentMethods = false);
      }
    }
  }

  Future<void> _pickAddress() async {
    final result = await Navigator.of(context).push<UserAddressModel>(
      MaterialPageRoute(
        builder: (context) => AddressSelectionScreen(
          preselectedAddressId: _selectedAddress?.id ?? _currentOrder.addressId,
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
          setState(() => _selectedFile = null);
          _showErrorSnackBar(AppStrings.fileSizeExceeded.tr());
          return;
        }

        setState(() => _selectedFile = file);
      }
    } catch (e) {
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotUploadReceipt.tr(),
        ),
      );
    }
  }

  Future<OrderModel?> _syncOrderDetails() async {
    if (_selectedAddress == null) {
      _showErrorSnackBar(AppStrings.selectAddress.tr());
      return null;
    }

    try {
      PaymentDebugLogger.info(
        'OrderDetailsScreen:syncOrderDetails:start',
        data: {
          'currentOrderId': _currentOrder.id,
          'selectedAddressId': _selectedAddress!.id,
        },
      );
      final synced = await ref
          .read(checkoutFlowCoordinatorProvider)
          .syncOrderDetails(
            order: _currentOrder,
            addressId: _selectedAddress!.id,
          );
      if (!mounted) return synced;

      setState(() {
        _currentOrder = synced.copyWith(
          address: {
            'label': _selectedAddress!.label,
            'name': _selectedAddress!.name,
            'mobile': _selectedAddress!.mobile,
            'country': _selectedAddress!.country,
            'city': _selectedAddress!.city,
            'address': _selectedAddress!.address,
            'shortAddress': _selectedAddress!.shortAddress,
            'isDefault': _selectedAddress!.isDefault,
          },
        );
      });
      ref.invalidate(getUserOrdersProvider);
      PaymentDebugLogger.info(
        'OrderDetailsScreen:syncOrderDetails:success',
        data: {
          'orderId': _currentOrder.id,
          'paymentStatus': _currentOrder.paymentStatus,
          'orderStatus': _currentOrder.orderStatus,
        },
      );
      return _currentOrder;
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:syncOrderDetails:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotUpdateAddress.tr(),
        ),
      );
      return null;
    }
  }

  OrderModel _mergeTrustedOrder(OrderModel trustedOrder) {
    return _currentOrder.copyWith(
      id: trustedOrder.id != 0 ? trustedOrder.id : _currentOrder.id,
      userId: trustedOrder.userId != 0
          ? trustedOrder.userId
          : _currentOrder.userId,
      total: trustedOrder.total != 0 ? trustedOrder.total : _currentOrder.total,
      paymentStatus: trustedOrder.paymentStatus,
      orderStatus: trustedOrder.orderStatus,
      paymentId: trustedOrder.paymentId,
    );
  }

  Future<void> _submitBankTransfer() async {
    if (_selectedFile == null || _selectedFile!.path == null) {
      _showErrorSnackBar(AppStrings.selectFile.tr());
      return;
    }

    PaymentDebugLogger.info(
      'OrderDetailsScreen:submitBankTransfer:start',
      data: {
        'orderId': _currentOrder.id,
        'auctionId': _currentOrder.auctionId,
        'filePath': _selectedFile!.path,
      },
    );
    setState(() => _isUploading = true);
    try {
      final syncedOrder = await _syncOrderDetails();
      if (syncedOrder == null) return;

      final updatedOrder = await ref
          .read(checkoutFlowCoordinatorProvider)
          .submitBankTransfer(
            order: syncedOrder,
            filePath: _selectedFile!.path!,
          );

      if (!mounted) return;
      setState(() {
        _currentOrder = _mergeTrustedOrder(updatedOrder);
        _selectedFile = null;
      });
      PaymentDebugLogger.info(
        'OrderDetailsScreen:submitBankTransfer:success',
        data: {
          'orderId': _currentOrder.id,
          'paymentStatus': _currentOrder.paymentStatus,
          'orderStatus': _currentOrder.orderStatus,
        },
      );
      ref.invalidate(userWinningAuctionsProvider);
      ref.invalidate(getUserOrdersProvider);
      if (CachedVariables.userId != null) {
        ref.invalidate(cartProvider(CachedVariables.userId!));
      }
      AppFunctions.showSnackBar(
        context: context,
        message: AppStrings.receiptUploadedSuccessfully.tr(),
      );
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:submitBankTransfer:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotUploadReceipt.tr(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _startGeideaCheckout() async {
    final isUsingSavedPaymentMethod = _selectedSavedPaymentMethodId != null;
    PaymentDebugLogger.info(
      'OrderDetailsScreen:startGeideaCheckout:start',
      data: {
        'orderId': _currentOrder.id,
        'saveCardForFutureUse': _saveCardForFutureUse,
        'selectedSavedMethodId': _selectedSavedPaymentMethodId,
        'isUsingSavedPaymentMethod': isUsingSavedPaymentMethod,
        'paymentMethod': _paymentMethod.name,
      },
    );
    setState(() => _isSubmitting = true);
    try {
      final syncedOrder = await _syncOrderDetails();
      if (syncedOrder == null) return;

      final session = await ref
          .read(checkoutFlowCoordinatorProvider)
          .createGeideaCheckoutSession(
            order: syncedOrder,
            cardOnFile: _saveCardFeatureEnabled &&
                _saveCardForFutureUse &&
                !isUsingSavedPaymentMethod,
            savedMethodId: _selectedSavedPaymentMethodId,
          );

      if (!mounted) return;

      PaymentDebugLogger.info(
        'OrderDetailsScreen:startGeideaCheckout:sessionReady',
        data: {
          'orderId': syncedOrder.id,
          'merchantReferenceId': session.merchantReferenceId,
          'sessionId': session.sessionId,
          'checkoutUrl': session.checkoutUrl,
          'response': session.rawResponse,
        },
      );
      final outcome = await _geideaSdkService.startCheckout(
        context: context,
        session: session,
        theme: Theme.of(context),
      );
      if (!mounted) return;

      PaymentDebugLogger.info(
        'OrderDetailsScreen:startGeideaCheckout:sdkFinished',
        data: {
          'orderId': syncedOrder.id,
          'status': outcome.status.name,
          'message': outcome.message,
          'raw': outcome.raw,
        },
      );

      if (outcome.status == GeideaPaymentOutcomeStatus.canceled) {
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.geideaCheckoutCanceled.tr(),
        );
        return;
      }

      if (outcome.status == GeideaPaymentOutcomeStatus.failure) {
        _showErrorSnackBar(outcome.message ?? AppStrings.paymentFailed.tr());
        return;
      }

      await _refreshGeideaPaymentStatus(orderId: syncedOrder.id);
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:startGeideaCheckout:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotStartPayment.tr(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Future<void> _startGeideaSaveCard() async {
    final userId = CachedVariables.userId;
    if (userId == null) return;

    PaymentDebugLogger.info(
      'OrderDetailsScreen:startGeideaSaveCard:start',
      data: {'userId': userId},
    );
    setState(() => _isSavingCard = true);
    try {
      final session = await ref
          .read(checkoutFlowCoordinatorProvider)
          .createGeideaSaveCardSession(userId: userId);

      if (!mounted) return;

      PaymentDebugLogger.info(
        'OrderDetailsScreen:startGeideaSaveCard:sessionReady',
        data: {
          'userId': userId,
          'merchantReferenceId': session.merchantReferenceId,
          'sessionId': session.sessionId,
          'checkoutUrl': session.checkoutUrl,
          'response': session.rawResponse,
        },
      );
      final outcome = await _geideaSdkService.startCheckout(
        context: context,
        session: session,
        theme: Theme.of(context),
      );
      if (!mounted) return;

      PaymentDebugLogger.info(
        'OrderDetailsScreen:startGeideaSaveCard:sdkFinished',
        data: {
          'userId': userId,
          'status': outcome.status.name,
          'message': outcome.message,
          'raw': outcome.raw,
        },
      );

      if (outcome.status == GeideaPaymentOutcomeStatus.success) {
        await _refreshSavedPaymentMethodsAfterReturn();
        return;
      }

      if (outcome.status == GeideaPaymentOutcomeStatus.canceled) {
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.geideaCheckoutCanceled.tr(),
        );
        return;
      }

      _showErrorSnackBar(outcome.message ?? AppStrings.paymentFailed.tr());
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:startGeideaSaveCard:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotStartPayment.tr(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSavingCard = false);
      }
    }
  }

  Future<void> _refreshSavedPaymentMethodsAfterReturn() async {
    final previousCount = _savedPaymentMethods.length;
    PaymentDebugLogger.info(
      'OrderDetailsScreen:refreshSavedPaymentMethodsAfterReturn:start',
      data: {'previousCount': previousCount},
    );
    final deadline = DateTime.now().add(const Duration(seconds: 15));
    do {
      await _loadSavedPaymentMethods();
      if (!mounted) return;
      if (_savedPaymentMethods.length > previousCount) {
        break;
      }
      if (DateTime.now().isAfter(deadline)) {
        break;
      }
      await Future.delayed(const Duration(seconds: 2));
    } while (mounted);
    if (!mounted) return;

    AppFunctions.showSnackBar(
      context: context,
      message: _savedPaymentMethods.length > previousCount
          ? AppStrings.cardSavedSuccessfully.tr()
          : AppStrings.savedPaymentMethodsRefreshed.tr(),
    );
    PaymentDebugLogger.info(
      'OrderDetailsScreen:refreshSavedPaymentMethodsAfterReturn:success',
      data: {
        'previousCount': previousCount,
        'newCount': _savedPaymentMethods.length,
      },
    );
  }

  Future<void> _refreshGeideaPaymentStatus({required int orderId}) async {
    PaymentDebugLogger.info(
      'OrderDetailsScreen:refreshGeideaPaymentStatus:start',
      data: {'orderId': orderId},
    );
    setState(() => _isCheckingGeideaStatus = true);
    try {
      OrderModel trustedOrder = await ref
          .read(orderRepositoryProvider)
          .getTrustedOrderStatus(orderId);
      final deadline = DateTime.now().add(const Duration(seconds: 20));
      while (mounted &&
          trustedOrder.paymentStatus != 'paid' &&
          trustedOrder.paymentStatus != 'failed' &&
          DateTime.now().isBefore(deadline)) {
        await Future.delayed(const Duration(seconds: 2));
        trustedOrder = await ref
            .read(orderRepositoryProvider)
            .getTrustedOrderStatus(orderId);
      }
      if (!mounted) return;

      final merged = _mergeTrustedOrder(trustedOrder);
      setState(() => _currentOrder = merged);
      PaymentDebugLogger.info(
        'OrderDetailsScreen:refreshGeideaPaymentStatus:success',
        data: {
          'orderId': merged.id,
          'paymentStatus': merged.paymentStatus,
          'orderStatus': merged.orderStatus,
          'paymentId': merged.paymentId,
        },
      );
      ref.invalidate(getUserOrdersProvider);
      ref.invalidate(userWinningAuctionsProvider);
      if (CachedVariables.userId != null) {
        ref.invalidate(cartProvider(CachedVariables.userId!));
      }

      if (merged.paymentStatus == 'paid') {
        AppFunctions.showSnackBar(
          context: context,
          message: AppStrings.paymentSuccessful.tr(),
        );
        return;
      }

      if (merged.paymentStatus == 'failed') {
        _showErrorSnackBar(AppStrings.paymentFailed.tr());
        return;
      }

      AppFunctions.showSnackBar(
        context: context,
        message: AppStrings.paymentVerificationPending.tr(),
      );
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:refreshGeideaPaymentStatus:failure',
        error: e,
        data: {'orderId': orderId},
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotCheckPaymentStatus.tr(),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isCheckingGeideaStatus = false);
      }
    }
  }

  Future<void> _setDefaultSavedPaymentMethod(int methodId) async {
    final userId = CachedVariables.userId;
    if (userId == null) return;

    try {
      PaymentDebugLogger.info(
        'OrderDetailsScreen:setDefaultSavedPaymentMethod:start',
        data: {'userId': userId, 'methodId': methodId},
      );
      await ref
          .read(checkoutFlowCoordinatorProvider)
          .setDefaultSavedPaymentMethod(userId: userId, methodId: methodId);
      if (mounted) {
        setState(() => _selectedSavedPaymentMethodId = methodId);
      }
      await _loadSavedPaymentMethods();
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:setDefaultSavedPaymentMethod:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotUpdateSavedCards.tr(),
        ),
      );
    }
  }

  Future<void> _deactivateSavedPaymentMethod(int methodId) async {
    final userId = CachedVariables.userId;
    if (userId == null) return;

    try {
      PaymentDebugLogger.info(
        'OrderDetailsScreen:deactivateSavedPaymentMethod:start',
        data: {'userId': userId, 'methodId': methodId},
      );
      await ref
          .read(checkoutFlowCoordinatorProvider)
          .deactivateSavedPaymentMethod(userId: userId, methodId: methodId);
      if (mounted && _selectedSavedPaymentMethodId == methodId) {
        setState(() => _selectedSavedPaymentMethodId = null);
      }
      await _loadSavedPaymentMethods();
    } catch (e) {
      PaymentDebugLogger.error(
        'OrderDetailsScreen:deactivateSavedPaymentMethod:failure',
        error: e,
      );
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotUpdateSavedCards.tr(),
        ),
      );
    }
  }

  Future<void> _changeShippingAddress() async {
    final selectedAddress = await Navigator.push<UserAddressModel>(
      context,
      MaterialPageRoute(
        builder: (context) => AddressSelectionScreen(
          preselectedAddressId: _selectedAddress?.id ?? _currentOrder.addressId,
        ),
      ),
    );

    if (selectedAddress == null || !mounted) return;

    if (_currentOrder.id == 0) {
      setState(() => _selectedAddress = selectedAddress);
      AppFunctions.showSnackBar(
        context: context,
        message: AppStrings.addressSavedSuccessfully.tr(),
      );
      return;
    }

    try {
      final updated = _currentOrder.copyWith(addressId: selectedAddress.id);
      final result = await ref
          .read(orderRepositoryProvider)
          .updateOrder(updated);
      if (!mounted) return;
      setState(() {
        _selectedAddress = selectedAddress;
        _currentOrder = result.copyWith(
          address: {
            'label': selectedAddress.label,
            'name': selectedAddress.name,
            'mobile': selectedAddress.mobile,
            'country': selectedAddress.country,
            'city': selectedAddress.city,
            'address': selectedAddress.address,
            'shortAddress': selectedAddress.shortAddress,
            'isDefault': selectedAddress.isDefault,
          },
        );
      });
      ref.invalidate(getUserOrdersProvider);
      AppFunctions.showSnackBar(
        context: context,
        message: AppStrings.addressSavedSuccessfully.tr(),
      );
    } catch (e) {
      _showErrorSnackBar(
        _friendlyErrorMessage(
          e,
          fallback: AppStrings.couldNotUpdateAddress.tr(),
        ),
      );
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
            _buildOrderInfo(order),
            _buildProductSection(order, theme),
            _buildShippingSection(theme),
            if (_showPaymentSection) _buildPaymentSection(theme),
            _buildTimelineSection(order),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(OrderModel order) {
    final status = OrderFlowState.stage(order);
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case OrderFlowStage.confirmed:
        color = Colors.green;
        icon = Icons.check_circle;
        text = AppStrings.completed.tr();
        break;
      case OrderFlowStage.paymentReview:
      case OrderFlowStage.paymentApprovedAwaitingOrderApproval:
        color = Colors.orange;
        icon = Icons.history;
        text = AppStrings.waitingForApproval.tr();
        break;
      case OrderFlowStage.paymentRejected:
        color = Colors.red;
        icon = Icons.cancel;
        text = AppStrings.paymentRejected.tr();
        break;
      case OrderFlowStage.shipped:
        color = Colors.blue;
        icon = Icons.local_shipping;
        text = AppStrings.shipped.tr();
        break;
      case OrderFlowStage.delivered:
        color = const Color(0xFF2D4739);
        icon = Icons.home;
        text = AppStrings.delivered.tr();
        break;
      case OrderFlowStage.cancelled:
        color = Colors.red;
        icon = Icons.cancel;
        text = AppStrings.orderCanceled.tr();
        break;
      default:
        color = Colors.grey;
        icon = Icons.hourglass_empty;
        text = _showPaymentSection
            ? AppStrings.completeYourOrder.tr()
            : AppStrings.pending.tr();
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
              padding: const EdgeInsets.only(top: 8),
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
      case 'paid':
      case 'captured':
      case 'verified':
        return AppStrings.paymentApproved.tr();
      case 'rejected':
      case 'failed':
        return AppStrings.paymentRejected.tr();
      case 'initiated':
      case 'pending':
        return AppStrings.paymentPending.tr();
      default:
        return status;
    }
  }

  Widget _buildOrderInfo(OrderModel order) {
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
          final hasImage = imageUrl.isNotEmpty;
          final heroTag = 'order_product_${order.id}_${item.id}';

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
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

  Widget _buildShippingSection(ThemeData theme) {
    final selectedAddress =
        _selectedAddress ?? _addressFromOrder(_currentOrder);
    final canEdit =
        _currentOrder.id == 0 || OrderFlowState.canEditAddress(_currentOrder);

    return _buildCard(
      title: AppStrings.shippingDetails.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectedAddress == null)
            InkWell(
              onTap: _pickAddress,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.4),
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.selectAddress.tr(),
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildInfoRow(AppStrings.name.tr(), selectedAddress.name),
            _buildInfoRow(AppStrings.mobileNumber.tr(), selectedAddress.mobile),
            _buildInfoRow(AppStrings.country.tr(), selectedAddress.country),
            _buildInfoRow(AppStrings.city.tr(), selectedAddress.city),
            const SizedBox(height: 8),
            Text(
              AppStrings.address.tr(),
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(selectedAddress.address, style: const TextStyle(fontSize: 14)),
            if (_currentOrder.deliveryCompany != null &&
                _currentOrder.deliveryCompany!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Delivery Company'.tr(),
                _currentOrder.deliveryCompany!,
              ),
              if (_currentOrder.trackingNumber != null &&
                  _currentOrder.trackingNumber!.isNotEmpty)
                _buildInfoRow(
                  'Tracking Number'.tr(),
                  _currentOrder.trackingNumber!,
                ),
            ],
            if (canEdit) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _changeShippingAddress,
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
        ],
      ),
    );
  }

  Widget _buildPaymentSection(ThemeData theme) {
    final isRejected = _currentOrder.paymentStatus == 'rejected';
    final uploadTitle = isRejected
        ? AppStrings.uploadNewReceipt.tr()
        : AppStrings.uploadReceipt.tr();

    return _buildCard(
      title: AppStrings.paymentMethod.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
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
          if (_paymentMethod == UnifiedPaymentMethod.bankTransfer) ...[
            _buildBankTransferSection(theme, uploadTitle),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _submitBankTransfer,
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
                    : Text(AppStrings.submitOrder.tr()),
              ),
            ),
          ],
          if (_paymentMethod == UnifiedPaymentMethod.creditCard)
            CardCheckoutSection(
              theme: theme,
              onStartGeideaCheckout: _startGeideaCheckout,
              onAddCard: _startGeideaSaveCard,
              onSetDefault: _setDefaultSavedPaymentMethod,
              onDeactivate: _deactivateSavedPaymentMethod,
              selectedSavedMethodId: _selectedSavedPaymentMethodId,
              onSavedMethodSelected: (methodId) {
                setState(() {
                  _selectedSavedPaymentMethodId = methodId;
                  if (methodId != null) {
                    _saveCardForFutureUse = false;
                  }
                });
              },
              showSaveCardFeatures: _saveCardFeatureEnabled,
              savedPaymentMethods: _savedPaymentMethods,
              saveCardForFutureUse: _saveCardForFutureUse,
              onSaveCardForFutureUseChanged: (value) {
                setState(() => _saveCardForFutureUse = value);
              },
              isLoading: _isSubmitting || _isCheckingGeideaStatus,
              isLoadingSavedMethods: _isLoadingSavedPaymentMethods,
              isSavingCard: _isSavingCard,
            ),
        ],
      ),
    );
  }

  Widget _buildBankTransferSection(ThemeData theme, String uploadTitle) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
          ),
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
                Text(_selectedFile?.name ?? uploadTitle),
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

  Widget _buildTimelineSection(OrderModel order) {
    final stage = OrderFlowState.stage(order);
    final status = OrderFlowState.normalizedOrderStatus(order);

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
            AppStrings.paymentPending.tr(),
            AppStrings.receiptUploadedWaiting.tr(),
            isDone: [
              OrderFlowStage.paymentReview,
              OrderFlowStage.paymentApprovedAwaitingOrderApproval,
              OrderFlowStage.confirmed,
              OrderFlowStage.shipped,
              OrderFlowStage.delivered,
            ].contains(stage),
            isActive: stage == OrderFlowStage.paymentReview,
          ),
          _buildTimelineItem(
            stage == OrderFlowStage.paymentApprovedAwaitingOrderApproval
                ? AppStrings.waitingForApproval.tr()
                : AppStrings.confirmed.tr(),
            stage == OrderFlowStage.paymentApprovedAwaitingOrderApproval
                ? AppStrings.paymentApproved.tr()
                : AppStrings.paymentVerifiedConfirmed.tr(),
            isDone: ['confirmed', 'shipped', 'delivered'].contains(status),
            isActive:
                stage == OrderFlowStage.confirmed ||
                stage == OrderFlowStage.paymentApprovedAwaitingOrderApproval,
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
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
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
            Flexible(
              child: Text(
                value.toString(),
                textAlign: TextAlign.end,
                style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
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
}
