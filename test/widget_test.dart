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
  Future<List<Product>> products() async => [
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
}
