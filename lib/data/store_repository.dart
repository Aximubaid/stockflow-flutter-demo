import '../domain/models.dart';

abstract interface class StoreRepository {
  Future<List<Product>> products();
  Future<List<Customer>> customers();
  Future<List<SalesOrder>> orders();
  Future<void> saveProducts(List<Product> products);
}
