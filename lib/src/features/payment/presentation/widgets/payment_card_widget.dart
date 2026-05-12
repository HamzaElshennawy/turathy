import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:turathy/src/features/orders/domain/saved_payment_method_model.dart';
import '../../../../core/constants/app_strings/app_strings.dart';

class PaymentCardWidget extends StatelessWidget {
  final SavedPaymentMethodModel card;
  final VoidCallback? onSetDefault;
  final VoidCallback? onDelete;
  final bool isSelected;
  final VoidCallback? onTap;

  const PaymentCardWidget({
    super.key,
    required this.card,
    this.onSetDefault,
    this.onDelete,
    this.isSelected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Generate a sleek background color based on card ID
    final colors = [
      [const Color(0xFF1E1E1E), const Color(0xFF323232)], // Dark Grey
      [const Color(0xFF0F2027), const Color(0xFF203A43)], // Midnight Blue
      [const Color(0xFF4B1248), const Color(0xFFF0C27B)], // Purple to Gold
      [const Color(0xFF141E30), const Color(0xFF243B55)], // Deep Blue
      [const Color(0xFFD31027), const Color(0xFFEA384D)], // Red
      [const Color(0xFF11998E), const Color(0xFF38EF7D)], // Green
    ];

    final gradientColors = colors[card.id % colors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        height: 200,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: isSelected
              ? Border.all(color: Colors.greenAccent, width: 3)
              : null,
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors[0].withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background subtle pattern/shapes
            Positioned(
              right: -50,
              top: -50,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -30,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Row: Bank/Provider Name and Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          // EMV Chip
                          SvgPicture.string(
                            '''<svg width="40" height="30" viewBox="0 0 40 30" fill="none" xmlns="http://www.w3.org/2000/svg">
<rect width="40" height="30" rx="6" fill="#D4AF37"/>
<path d="M12 0V30M28 0V30M0 10H12M28 10H40M0 20H12M28 20H40" stroke="#B8860B" stroke-width="1.5"/>
<rect x="12" y="8" width="16" height="14" rx="2" stroke="#B8860B" stroke-width="1.5"/>
</svg>''',
                            height: 32,
                          ),
                          const SizedBox(width: 12),
                          // Contactless Icon
                          Transform.rotate(
                            angle: 1.5708, // 90 degrees
                            child: Icon(
                              Icons.wifi,
                              color: Colors.white.withOpacity(0.8),
                              size: 28,
                            ),
                          ),
                        ],
                      ),
                      if (card.isDefault)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.greenAccent.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.greenAccent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AppStrings.defaultCard.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        PopupMenuButton<String>(
                          icon: const Icon(
                            Icons.more_vert,
                            color: Colors.white,
                          ),
                          onSelected: (value) {
                            if (value == 'default' && onSetDefault != null) {
                              onSetDefault!();
                            } else if (value == 'delete' && onDelete != null) {
                              onDelete!();
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'default',
                              child: Text(AppStrings.setAsDefault.tr()),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(
                                AppStrings.delete.tr(),
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  // Bottom Row: Card Number and Provider Logo
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (card.cardholderName != null &&
                              card.cardholderName!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Text(
                                card.cardholderName!.toUpperCase(),
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 14,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          Text(
                            '•••• •••• •••• ${card.last4 ?? '0000'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              letterSpacing: 4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      _buildProviderLogo(),
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Positioned(
                top: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.greenAccent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check, color: Colors.black, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  //String _getBankName() {
  //  final name = card.cardholderName?.trim();
  //  if (name != null && name.isNotEmpty)
  //    return "Alturath"; // Mock Bank Name or Use App Name
  //  return "Alturath Card";
  //}

  Widget _buildProviderLogo() {
    final brand = card.brand?.toLowerCase() ?? '';
    String assetPath = '';

    if (brand.contains('visa')) {
      assetPath = 'assets/icons/payment/visa.svg';
    } else if (brand.contains('mastercard') || brand.contains('master')) {
      assetPath = 'assets/icons/payment/mastercard.svg';
    } else if (brand.contains('mada')) {
      assetPath = 'assets/icons/payment/mada.svg';
    } else if (brand.contains('apple')) {
      assetPath = 'assets/icons/payment/apple_pay.svg';
    }

    if (assetPath.isNotEmpty) {
      return SvgPicture.asset(
        assetPath,
        height: 40,
        // Visa or others might need color adjustment if they are black. My manual SVG is white/colors.
      );
    }

    return Text(
      card.brand ?? 'CARD',
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
    );
  }
}
