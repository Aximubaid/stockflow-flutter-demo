enum OrderStatus { pending, processing, delivered }

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.stock,
    required this.reorderAt,
  });
  final String id, name, sku, category;
  final double price;
  final int stock, reorderAt;
  bool get isLowStock => stock <= reorderAt;
  Product copyWith({
    String? name,
    String? sku,
    String? category,
    double? price,
    int? stock,
    int? reorderAt,
  }) => Product(
    id: id,
    name: name ?? this.name,
    sku: sku ?? this.sku,
    category: category ?? this.category,
    price: price ?? this.price,
    stock: stock ?? this.stock,
    reorderAt: reorderAt ?? this.reorderAt,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'sku': sku,
    'category': category,
    'price': price,
    'stock': stock,
    'reorderAt': reorderAt,
  };
  factory Product.fromJson(Map<String, dynamic> json) => Product(
    id: json['id'],
    name: json['name'],
    sku: json['sku'],
    category: json['category'],
    price: (json['price'] as num).toDouble(),
    stock: json['stock'],
    reorderAt: json['reorderAt'],
  );
}

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.company,
    required this.email,
    required this.orders,
  });
  final String id, name, company, email;
  final int orders;
}

class SalesOrder {
  const SalesOrder({
    required this.id,
    required this.customer,
    required this.date,
    required this.total,
    required this.items,
    required this.status,
  });
  final String id, customer;
  final DateTime date;
  final double total;
  final int items;
  final OrderStatus status;
}
