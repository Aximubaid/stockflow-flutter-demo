import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stockflow/app/app.dart';
import 'package:stockflow/features/store_controller.dart';

import 'widget_test.dart';

void main() {
  Future<void> renderDashboard(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = StoreController(FakeRepository());
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const StockFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('mobile portfolio dashboard', (tester) async {
    await renderDashboard(tester, const Size(390, 844));
    await expectLater(
      find.byType(StockFlowApp),
      matchesGoldenFile('goldens/stockflow-mobile-dashboard.png'),
    );
  }, tags: 'golden');

  testWidgets('desktop portfolio dashboard', (tester) async {
    await renderDashboard(tester, const Size(1280, 800));
    await expectLater(
      find.byType(StockFlowApp),
      matchesGoldenFile('goldens/stockflow-desktop-dashboard.png'),
    );
  }, tags: 'golden');
}
