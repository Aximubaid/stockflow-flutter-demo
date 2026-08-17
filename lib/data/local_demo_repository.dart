import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/models.dart';
import 'store_repository.dart';

class LocalDemoRepository implements StoreRepository {
  late SharedPreferences _preferences;
  Future<void> initialize() async =>
      _preferences = await SharedPreferences.getInstance();
  static const _seedProducts = [
    Product(
      id: 'p1',
      name: 'Ceramic Pour-Over Set',
      sku: 'KIT-1042',
      category: 'Kitchen',
      price: 68,
      stock: 18,
      reorderAt: 8,
    ),
    Product(
      id: 'p2',
      name: 'Linen Desk Organizer',
      sku: 'DSK-2310',
      category: 'Office',
      price: 32,
      stock: 6,
      reorderAt: 8,
    ),
    Product(
      id: 'p3',
      name: 'Amber Glass Bottle',
      sku: 'HOM-1188',
      category: 'Home',
      price: 24,
      stock: 42,
      reorderAt: 10,
    ),
    Product(
      id: 'p4',
      name: 'Canvas Market Tote',
      sku: 'ACC-9012',
      category: 'Accessories',
      price: 29,
      stock: 4,
      reorderAt: 6,
    ),
    Product(
      id: 'p5',
      name: 'Oak Display Stand',
      sku: 'RET-4201',
      category: 'Retail',
      price: 84,
      stock: 12,
      reorderAt: 5,
    ),
  ];
  static final _seedCustomers = [
    const Customer(
      id: 'c1',
      name: 'Avery Demo',
      company: 'Northstar Demo Goods',
      email: 'avery@northstar-demo.example',
      orders: 14,
    ),
    const Customer(
      id: 'c2',
      name: 'Jordan Sample',
      company: 'Example Corner Shop',
      email: 'jordan@example-corner.example',
      orders: 9,
    ),
    const Customer(
      id: 'c3',
      name: 'Riley Placeholder',
      company: 'Demo Studio Eleven',
      email: 'riley@demo-studio.example',
      orders: 21,
    ),
  ];
  static final _seedOrders = [
    SalesOrder(
      id: 'SF-1048',
      customer: 'Northstar Demo Goods',
      date: DateTime(2026, 8, 16),
      total: 842,
      items: 12,
      status: OrderStatus.processing,
    ),
    SalesOrder(
      id: 'SF-1047',
      customer: 'Demo Studio Eleven',
      date: DateTime(2026, 8, 15),
      total: 1260,
      items: 18,
      status: OrderStatus.delivered,
    ),
    SalesOrder(
      id: 'SF-1046',
      customer: 'Example Corner Shop',
      date: DateTime(2026, 8, 14),
      total: 394,
      items: 6,
      status: OrderStatus.pending,
    ),
    SalesOrder(
      id: 'SF-1045',
      customer: 'Northstar Demo Goods',
      date: DateTime(2026, 8, 12),
      total: 675,
      items: 9,
      status: OrderStatus.delivered,
    ),
  ];
  @override
  Future<List<Product>> products() async {
    final cached = _preferences.getString('products');
    return cached == null
        ? List.of(_seedProducts)
        : (jsonDecode(cached) as List).map((e) => Product.fromJson(e)).toList();
  }

  @override
  Future<List<Customer>> customers() async => List.of(_seedCustomers);
  @override
  Future<List<SalesOrder>> orders() async => List.of(_seedOrders);
  @override
  Future<void> saveProducts(List<Product> products) async {
    await _preferences.setString(
      'products',
      jsonEncode(products.map((e) => e.toJson()).toList()),
    );
  }
}
