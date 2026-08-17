import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/store_repository.dart';
import '../domain/models.dart';

class StoreController extends ChangeNotifier {
  StoreController(this._repository);
  final StoreRepository _repository;
  final _uuid = const Uuid();
  List<Product> products = [];
  List<Customer> customers = [];
  List<SalesOrder> orders = [];
  bool isLoading = true;
  String? error;
  Future<void> load() async {
    try {
      isLoading = true;
      error = null;
      notifyListeners();
      final r = await Future.wait([
        _repository.products(),
        _repository.customers(),
        _repository.orders(),
      ]);
      products = r[0] as List<Product>;
      customers = r[1] as List<Customer>;
      orders = r[2] as List<SalesOrder>;
    } catch (_) {
      error = 'We could not load your workspace. Pull to retry.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double get revenue => orders
      .where((o) => o.status == OrderStatus.delivered)
      .fold(0, (sum, o) => sum + o.total);
  int get lowStockCount => products.where((p) => p.isLowStock).length;
  Future<void> addProduct({
    required String name,
    required String sku,
    required String category,
    required double price,
    required int stock,
  }) async {
    products = [
      ...products,
      Product(
        id: _uuid.v4(),
        name: name,
        sku: sku,
        category: category,
        price: price,
        stock: stock,
        reorderAt: 8,
      ),
    ];
    notifyListeners();
    await _repository.saveProducts(products);
  }

  Future<void> deleteProduct(String id) async {
    products = products.where((p) => p.id != id).toList();
    notifyListeners();
    await _repository.saveProducts(products);
  }

  Future<void> updateProduct(Product updated) async {
    products = products
        .map((product) => product.id == updated.id ? updated : product)
        .toList();
    notifyListeners();
    await _repository.saveProducts(products);
  }
}
