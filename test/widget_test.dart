import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:stockflow/app/app.dart';
import 'package:stockflow/data/store_repository.dart';
import 'package:stockflow/domain/models.dart';
import 'package:stockflow/features/store_controller.dart';

class FakeRepository implements StoreRepository {
  List<Product> saved = [];
  @override
  Future<List<Product>> products() async => saved.isNotEmpty
      ? saved
      : [
          const Product(
            id: '1',
            name: 'Test Product',
            sku: 'SKU-1',
            category: 'Office',
            price: 20,
            stock: 3,
            reorderAt: 5,
          ),
        ];
  @override
  Future<List<Customer>> customers() async => [
    const Customer(
      id: '1',
      name: 'Test Customer',
      company: 'Example Test Company',
      email: 'customer@test-data.example',
      orders: 2,
    ),
  ];
  @override
  Future<List<SalesOrder>> orders() async => [
    SalesOrder(
      id: 'SF-1048',
      customer: 'Dispatch Demo Company',
      date: DateTime(2026, 8, 16),
      total: 842,
      items: 12,
      status: OrderStatus.processing,
    ),
    SalesOrder(
      id: 'SF-1',
      customer: 'Example Test Company',
      date: DateTime(2026),
      total: 100,
      items: 2,
      status: OrderStatus.delivered,
    ),
  ];
  @override
  Future<void> saveProducts(List<Product> products) async => saved = products;
}

Future<void> pumpStockFlow(
  WidgetTester tester, {
  Size size = const Size(390, 844),
}) async {
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

void main() {
  test('controller calculates dashboard data and persists CRUD', () async {
    final repo = FakeRepository();
    final controller = StoreController(repo);
    await controller.load();
    expect(controller.revenue, 100);
    expect(controller.lowStockCount, 1);
    await controller.addProduct(
      name: 'New',
      sku: 'NEW-1',
      category: 'Home',
      price: 5,
      stock: 10,
    );
    expect(repo.saved.length, 2);
    await controller.deleteProduct('1');
    expect(repo.saved.length, 1);
    await controller.updateProduct(repo.saved.single.copyWith(name: 'Updated'));
    expect(repo.saved.single.name, 'Updated');

    final restartedController = StoreController(repo);
    await restartedController.load();
    expect(restartedController.products.single.name, 'Updated');
  });

  testWidgets('adding a product validates, persists, and closes cleanly', (
    tester,
  ) async {
    final repo = FakeRepository();
    final controller = StoreController(repo);
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const StockFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name'),
      'New Kitchen Item',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category'),
      'Kitchen',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '5');
    await tester.enterText(find.widgetWithText(TextFormField, 'Stock'), '10');
    await tester.tap(find.byKey(const ValueKey('save-product')));
    await tester.pump();
    expect(find.text('Required'), findsOneWidget);
    expect(find.text('Add new product'), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, 'SKU'),
      'KIT-5002',
    );
    await tester.tap(find.byKey(const ValueKey('save-product')));
    await tester.pumpAndSettle();

    expect(find.text('Add new product'), findsNothing);
    expect(find.text('New Kitchen Item'), findsOneWidget);
    expect(find.text('10 in stock'), findsOneWidget);
    expect(find.text('Product added successfully.'), findsOneWidget);
    expect(repo.saved.any((product) => product.sku == 'KIT-5002'), isTrue);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Product actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name'),
      'Updated Kitchen Item',
    );
    await tester.tap(find.byKey(const ValueKey('save-product')));
    await tester.pumpAndSettle();
    expect(find.text('Updated Kitchen Item'), findsOneWidget);

    await tester.tap(find.byTooltip('Product actions').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Delete').last);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Updated Kitchen Item'), findsNothing);

    await tester.tap(find.text('Add product'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Product name'),
      'Added Again',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'SKU'),
      'KIT-5003',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Category'),
      'Kitchen',
    );
    await tester.enterText(find.widgetWithText(TextFormField, 'Price'), '6');
    await tester.enterText(find.widgetWithText(TextFormField, 'Stock'), '12');
    await tester.tap(find.byKey(const ValueKey('save-product')));
    await tester.pumpAndSettle();
    expect(find.text('Added Again'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.grid_view_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Added Again'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('renders dashboard and navigates to inventory', (tester) async {
    final controller = StoreController(FakeRepository());
    await controller.load();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: controller,
        child: const StockFlowApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Good morning, Alex'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();
    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('3 in stock'), findsOneWidget);
  });

  testWidgets('dashboard metrics open their expected destinations', (
    tester,
  ) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byKey(const ValueKey('metric-revenue')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('revenue-details-page')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('metric-orders')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('orders-page')), findsOneWidget);
  });

  testWidgets('products and low stock metrics configure inventory', (
    tester,
  ) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byKey(const ValueKey('metric-products')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inventory-page')), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('low-stock-filter')))
          .selected,
      isFalse,
    );

    await tester.tap(find.byIcon(Icons.grid_view_rounded).last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('metric-low-stock')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('low-stock-filter')))
          .selected,
      isTrue,
    );
    expect(find.text('Test Product'), findsOneWidget);
  });

  testWidgets('recent order and View all navigate correctly', (tester) async {
    await pumpStockFlow(tester);
    await tester.scrollUntilVisible(find.text('SF-1'), 300);
    await tester.tap(find.text('SF-1').first);
    await tester.pumpAndSettle();
    expect(find.text('Order details'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('View all'), 300);
    await tester.tap(find.text('View all'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('orders-page')), findsOneWidget);
  });

  testWidgets('customer history drills down to order details', (tester) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byIcon(Icons.people_outline).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Test Customer'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('customer-details-page')), findsOneWidget);
    expect(find.text('Recent orders'), findsOneWidget);
    await tester.tap(find.text('SF-1'));
    await tester.pumpAndSettle();
    expect(find.text('Order details'), findsOneWidget);
  });

  testWidgets('notification bell and profile avatar open complete screens', (
    tester,
  ) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notifications-page')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-avatar')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('profile-page')), findsOneWidget);
    expect(find.text('Alex Demo'), findsOneWidget);
  });

  testWidgets('low-stock notification opens filtered inventory and returns', (
    tester,
  ) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-low-stock')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('inventory-page')), findsOneWidget);
    expect(
      tester
          .widget<FilterChip>(find.byKey(const ValueKey('low-stock-filter')))
          .selected,
      isTrue,
    );
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notifications-page')), findsOneWidget);
  });

  testWidgets('dispatch notification opens SF-1048 details and returns', (
    tester,
  ) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byTooltip('Notifications'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('notification-order-ready')));
    await tester.pumpAndSettle();
    expect(find.text('Order details'), findsOneWidget);
    expect(find.text('SF-1048'), findsOneWidget);
    expect(find.byKey(const ValueKey('status-processing')), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notifications-page')), findsOneWidget);
  });

  testWidgets('order statuses render without overflow at narrow width', (
    tester,
  ) async {
    await pumpStockFlow(tester, size: const Size(320, 700));
    await tester.tap(find.byIcon(Icons.receipt_long_outlined).last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('status-delivered')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('inventory search and low-stock filter update results', (
    tester,
  ) async {
    await pumpStockFlow(tester);
    await tester.tap(find.byIcon(Icons.inventory_2_outlined).last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('inventory-search')),
      'missing',
    );
    await tester.pump();
    expect(find.text('No matching products'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('inventory-search')),
      'Test',
    );
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('low-stock-filter')));
    await tester.pump();
    expect(find.text('Test Product'), findsOneWidget);
  });
}
