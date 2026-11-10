import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:turathy/src/features/main_screen_tab.dart';
import 'package:turathy/src/features/orders/presentation/payment_success_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('paid order thanks the customer and returns to the order', (
    tester,
  ) async {
    await EasyLocalization.ensureInitialized();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(mainScreenTabIndexProvider.notifier).state = 2;

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('ar')],
        path: 'assets/lang',
        fallbackLocale: const Locale('ar'),
        startLocale: const Locale('ar'),
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) {
              return MaterialApp(
                locale: context.locale,
                supportedLocales: context.supportedLocales,
                localizationsDelegates: context.localizationDelegates,
                home: const _OpenSuccess(),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('تم استلام طلبك'), findsWidgets);
    expect(find.text('شكراً لك. تم تأكيد الدفع، وسنجهّز طلبك.'), findsOneWidget);
    expect(find.text('رقم الطلب 42'), findsOneWidget);
    expect(find.text('المبلغ 150.50 ر.س'), findsOneWidget);
    expect(find.text('يمكنك متابعة حالة الطلب من طلباتي'), findsOneWidget);

    await tester.tap(find.text('عرض الطلب'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('العودة للرئيسية'));
    await tester.pumpAndSettle();

    expect(container.read(mainScreenTabIndexProvider), 0);
    expect(find.text('open'), findsOneWidget    );
  });
}

class _OpenSuccess extends StatelessWidget {
  const _OpenSuccess();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TextButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const PaymentSuccessScreen(
                orderId: 42,
                total: 150.5,
              ),
            ),
          );
        },
        child: const Text('open'),
      ),
    );
  }
}
