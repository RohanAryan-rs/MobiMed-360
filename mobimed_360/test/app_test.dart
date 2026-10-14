import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobimed_360/main.dart';
import 'package:mobimed_360/live.dart';
import 'package:mobimed_360/portal.dart';

void main() {
  for (final role in ['Doctor', 'Hospital', 'Pathology', 'Medi-Store']) {
    testWidgets('$role demo workspace fits a compact phone', (tester) async {
      tester.view.physicalSize = const Size(320, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(MaterialApp(home: ProviderPortal(role: role)));
      await tester.pumpAndSettle();
      expect(find.text('$role workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  test('Prices use integer cents', () {
    expect(money(1250), '\$12.50');
    expect(money(0), '\$0.00');
    expect(services.map((s) => s.id).toSet().length, services.length);
  });
  test('International prices respect currency minor units', () {
    expect(formatPrice(1250, 'USD'), contains('12.50'));
    expect(formatPrice(1250, 'JPY'), contains('1,250'));
    expect(formatPrice(1250, 'KWD'), contains('1.250'));
  });
  for (final width in [320.0, 390.0, 800.0, 1200.0]) {
    testWidgets('Adaptive home and directory at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(const MobiMed360App());
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Feel better.\nStart here.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Find your doctor'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Find your doctor'));
      await tester.pumpAndSettle();
      expect(find.text('Dr. Maya Patel'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pumpAndSettle();
      expect(find.text('No matches'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Protected route resumes only after explicit demo login', (
    tester,
  ) async {
    await tester.pumpWidget(const MobiMed360App());
    await tester.pump(const Duration(seconds: 3));
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome to MobiMed'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Your bookings'), findsNothing);
    await tester.tap(find.text('Bookings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore demo account'));
    await tester.pumpAndSettle();
    expect(find.text('Your bookings'), findsOneWidget);
    expect(find.text('A fresh start'), findsOneWidget);
  });
  testWidgets('Cart quantity and demo checkout preserve cent totals', (
    tester,
  ) async {
    await tester.pumpWidget(const MobiMed360App());
    await tester.pump(const Duration(seconds: 3));
    await tester.ensureVisible(find.text('Find your doctor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Find your doctor'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pharmacy'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Care cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore demo account'));
    await tester.pumpAndSettle();
    expect(find.text('Total \$12.50'), findsOneWidget);
    await tester.tap(find.byTooltip('Increase Digital thermometer'));
    await tester.pumpAndSettle();
    expect(find.text('Total \$25.00'), findsOneWidget);
    await tester.tap(find.text('Create demo order'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Records'));
    await tester.pumpAndSettle();
    expect(find.text('Demo order 1 • \$25.00'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
