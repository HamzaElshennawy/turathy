# Geidea Flutter Payment SDK

## Overview

The Geidea Flutter Payment SDK delivers a seamless and secure payment experience for cross-platform Flutter applications. Designed for flexibility and ease of integration, the SDK enables developers to add payment functionality with minimal code while supporting rich UI customization and multiple presentation styles.

## Key Features

- **Dynamic Payment Methods** - Support for multiple payment options
- **Flexible UI & Presentation Options** - Customizable to match your brand
- **Native 3D Secure Authentication** - Enhanced security for transactions
- **Fast Card Scanning** - Quick data entry using device camera
- **Security & Compliance** - Industry-standard security protocols
- **Optimized Performance** - Efficient processing for smooth UX
- **Multi-language & Localization Support** - English and Arabic support
- **Smart Error Handling** - Clear error messages and recovery flows

## How It Works

1. Initialize the Geidea Flutter SDK in your application
2. The SDK retrieves and displays available payment methods
3. Customer payment details are securely collected
4. The SDK processes the payment via Geidea's payment gateway
5. The payment result is returned to the Flutter application and displayed to the user

## Getting Started

### Prerequisites

| Requirement | Minimum Version |
|------------|-----------------|
| Flutter SDK | 3.3.0+ |
| Dart | 2.17.0+ |
| iOS Deployment Target | iOS 15.0+ |
| Android Min SDK | API 23 (Android 6.0) |

### Installation

Add the Geidea Payment SDK to your Flutter project by updating `pubspec.yaml`:

```yaml
dependencies:
  gd_payment_sdk:
    path: ./GD_FLUTTER_SDK // SDK Directory
```

Then run:

```bash
flutter pub get
```

### Platform-Specific Setup

#### iOS Setup

Ensure the minimum deployment target in `ios/Podfile`:

```ruby
platform :ios, '15.0'
```
Then run in your ios folder:

```ruby
pod install
```

#### Android Setup

Ensure the minimum SDK version in `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 23
    }
}
```

## Integration Guide

### Step 1: Create a Payment Session (Server-Side)

Before launching the SDK, create a payment session using Geidea APIs. The generated `session.id` will be required to initialize the SDK on the client side.

Refer to the [Geidea API Documentation](https://docs.geidea.net/) for full details.

### Step 2: SDK Configuration (Client-Side)

#### Import the SDK

```dart
import 'package:gd_payment_sdk/gd_payment_sdk.dart';
```

#### Initialize and Start the SDK

```dart
class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final GDPaymentSDK _sdk = GDPaymentSDK.sharedInstance();
  bool _isProcessing = false;

  Future<void> _startPayment() async {
    setState(() {
      _isProcessing = true;
    });

    final configuration = GDPaymentSDKConfiguration(
      sessionId: 'your_session_id',
      region: Region.egy,
      language: SDKLanguage.english,
      theme: SDKTheme(
        primaryColor: '#667eea', // String HEX Color
        secondaryColor: '#764ba2', // String HEX Color
        merchantLogoPath: "assets/logo.png" // get path of logo from flutter assets folder
      ),
    );

    try {
      final response = await _sdk.start(
        configuration: configuration,
        presentationStyle: const PushStyle(),
      );

      setState(() {
        _isProcessing = false;
      });

      if (!mounted) return;

      switch (response.status) {
        case PaymentStatus.success:
          _handlePaymentSuccess(response.result!);
          break;
        case PaymentStatus.failure:
          _handlePaymentFailure(response.error!);
          break;
        case PaymentStatus.canceled:
          _handlePaymentCanceled();
          break;
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _handlePaymentSuccess(GDPaymentResult result) {}
  void _handlePaymentFailure(GDPaymentError error) {}
  void _handlePaymentCanceled() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Center(
        child: _isProcessing
            ? const CircularProgressIndicator()
            : ElevatedButton(
                onPressed: _startPayment,
                child: const Text('Start Payment'),
              ),
      ),
    );
  }
}
```

### Theme Customization

Customize the SDK appearance to match your brand identity:

```dart
final customTheme = SDKTheme(
  primaryColor: '#FF6B35',
  secondaryColor: '#F7F7F7',
  merchantLogoPath: "assets/logo.png"
);

final configuration = GDPaymentSDKConfiguration(
  sessionId: 'your_session_id',
  theme: customTheme,
  language: SDKLanguage.english,
  region: Region.egy,
  applePayMerchantId: "merchant.com.company.example", // required if you need Apple Pay, also Apple Pay should be enabled from portal to be visible in the SDK
);
```

#### Theme Properties

- `primaryColor`: Hex color string (e.g. `#667eea`)
- `secondaryColor`: Hex color string (e.g. `#764ba2`)
- `merchantLogoPath`: Asset or file path for merchant logo

## Payment Testing (Sandbox)

Use the following test card details in sandbox mode:

### Successful Payment

- **Card Number**: 4111 1111 1111 1111
- **CVV**: 123
- **Expiry Date**: Any future date (e.g. 12/27)
- **Cardholder Name**: Any name

## API Reference

### GDPaymentSDK

```dart
class GDPaymentSDK {
  static GDPaymentSDK sharedInstance();

  Future<PaymentResponse> start({
    required GDPaymentSDKConfiguration configuration,
    SDKPresentationStyle presentationStyle = const PushStyle(),
  });
}
```

### GDPaymentSDKConfiguration

```dart
class GDPaymentSDKConfiguration {
  final SDKTheme? theme;
  final String sessionId;
  final SDKLanguage language;
  final Region region;
  final String? applePayMerchantId;
}
```

#### Parameters

- `sessionId` (required): Payment session ID
- `region`: `Region.egy`, `Region.uae`, `Region.ksa`
- `applePayMerchantId`: Optionally add Apple Pay merchant ID to avail Apple Pay
- `language`: `SDKLanguage.english` or `SDKLanguage.arabic`
- `theme`: Optional theme configuration

### PaymentResponse

```dart
class PaymentResponse {
  final PaymentStatus status;
  final GDPaymentResult? result;
  final GDPaymentError? error;
}
```

### GDPaymentResult

```dart
class GDPaymentResult {
  final String? orderId;
  final String? tokenId;
  final String? agreementId;
  final PaymentMethodResult? paymentMethod;
}
```

### GDPaymentError

```dart
class GDPaymentError {
  final String code;
  final String message;
  final String? details;
}
```

### Enums

```dart
enum Region { egy, uae, ksa }

enum SDKLanguage { english, arabic }

enum PaymentStatus { success, failure, canceled }
```

## Support

For additional support or questions, please contact Geidea support or refer to the official documentation.

## License

Copyright © Geidea. All rights reserved.
