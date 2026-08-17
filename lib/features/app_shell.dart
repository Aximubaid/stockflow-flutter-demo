import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../domain/models.dart';
import 'store_controller.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  int inventoryRevision = 0;
  bool openLowStock = false;
  bool notificationsUnread = true;
  static const labels = ['Overview', 'Inventory', 'Orders', 'Customers'];

  void select(int value, {bool lowStock = false}) => setState(() {
    index = value;
    openLowStock = lowStock;
    if (value == 1) inventoryRevision++;
  });

  void push(Widget page) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final pages = [
      DashboardPage(
        onRevenue: () => push(const RevenueDetailsPage()),
        onOrders: () => select(2),
        onProducts: () => select(1),
        onLowStock: () => select(1, lowStock: true),
        onOrder: (order) => push(OrderDetailsPage(order: order)),
      ),
      InventoryPage(
        key: ValueKey(inventoryRevision),
        lowStockInitially: openLowStock,
      ),
      OrdersPage(onOrder: (order) => push(OrderDetailsPage(order: order))),
      CustomersPage(
        onCustomer: (customer) => push(CustomerDetailsPage(customer: customer)),
      ),
    ];
    final content = SafeArea(
      child: Column(
        children: [
          _TopBar(
            title: labels[index],
            unread: notificationsUnread,
            onNotifications: () async {
              setState(() => notificationsUnread = false);
              await Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsPage()),
              );
            },
            onProfile: () => push(const ProfilePage()),
          ),
          Expanded(
            child: Consumer<StoreController>(
              builder: (context, store, child) {
                if (store.isLoading) {
                  return const LoadingState();
                }
                if (store.error != null) {
                  return ErrorState(message: store.error!, retry: store.load);
                }
                return pages[index];
              },
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      body: wide
          ? Row(
              children: [
                _SideNav(index: index, onChanged: select),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: select,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.grid_view_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.inventory_2_outlined),
                  label: 'Inventory',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  label: 'Orders',
                ),
                NavigationDestination(
                  icon: Icon(Icons.people_outline),
                  label: 'Customers',
                ),
              ],
            ),
      floatingActionButton: index == 1
          ? FloatingActionButton.extended(
              onPressed: () => showProductForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.unread,
    required this.onNotifications,
    required this.onProfile,
  });
  final String title;
  final bool unread;
  final VoidCallback onNotifications, onProfile;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 18, 10),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: StockFlowTheme.navy,
                ),
              ),
              const Text(
                'Monday, August 17',
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
        Badge(
          isLabelVisible: unread,
          smallSize: 8,
          child: IconButton.filledTonal(
            tooltip: 'Notifications',
            onPressed: onNotifications,
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Demo profile',
          child: InkWell(
            key: const ValueKey('profile-avatar'),
            onTap: onProfile,
            borderRadius: BorderRadius.circular(30),
            child: const CircleAvatar(
              backgroundColor: Color(0xFFDBEAFE),
              child: Text(
                'AD',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: StockFlowTheme.blue,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SideNav extends StatelessWidget {
  const _SideNav({required this.index, required this.onChanged});
  final int index;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Container(
    width: 240,
    color: StockFlowTheme.navy,
    padding: const EdgeInsets.fromLTRB(18, 28, 18, 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.stacked_bar_chart_rounded, color: Colors.white),
              SizedBox(width: 10),
              Text(
                'StockFlow',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        ...List.generate(
          4,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                selected: index == i,
                selectedTileColor: Colors.white12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: Icon(
                  [
                    Icons.grid_view_rounded,
                    Icons.inventory_2_outlined,
                    Icons.receipt_long_outlined,
                    Icons.people_outline,
                  ][i],
                  color: index == i ? Colors.white : Colors.white60,
                ),
                title: Text(
                  ['Overview', 'Inventory', 'Orders', 'Customers'][i],
                  style: TextStyle(
                    color: index == i ? Colors.white : Colors.white60,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () => onChanged(i),
              ),
            ),
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white10,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            children: [
              Icon(Icons.cloud_done_outlined, color: StockFlowTheme.mint),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'All changes synced',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    required this.onRevenue,
    required this.onOrders,
    required this.onProducts,
    required this.onLowStock,
    required this.onOrder,
  });
  final VoidCallback onRevenue, onOrders, onProducts, onLowStock;
  final ValueChanged<SalesOrder> onOrder;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreController>();
    return RefreshIndicator(
      onRefresh: store.load,
      child: ListView(
        key: const ValueKey('dashboard-page'),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [StockFlowTheme.navy, Color(0xFF28456F)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good morning, Alex',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Here’s what is happening with your store today.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.auto_graph_rounded, color: Colors.white38, size: 58),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth > 700
                  ? (constraints.maxWidth - 36) / 4
                  : (constraints.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  MetricCard(
                    key: const ValueKey('metric-revenue'),
                    width: width,
                    label: 'Revenue',
                    value: money(store.revenue),
                    icon: Icons.payments_outlined,
                    color: StockFlowTheme.mint,
                    detail: '+12.4%',
                    onTap: onRevenue,
                  ),
                  MetricCard(
                    key: const ValueKey('metric-orders'),
                    width: width,
                    label: 'Orders',
                    value: '${store.orders.length}',
                    icon: Icons.shopping_bag_outlined,
                    color: StockFlowTheme.blue,
                    detail: '+8.2%',
                    onTap: onOrders,
                  ),
                  MetricCard(
                    key: const ValueKey('metric-products'),
                    width: width,
                    label: 'Products',
                    value: '${store.products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.deepPurple,
                    detail: 'Active',
                    onTap: onProducts,
                  ),
                  MetricCard(
                    key: const ValueKey('metric-low-stock'),
                    width: width,
                    label: 'Low stock',
                    value: '${store.lowStockCount}',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    detail: 'Needs action',
                    onTap: onLowStock,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Sales performance', action: 'Last 7 days'),
          const SizedBox(height: 10),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: SizedBox(
                height: 150,
                child: BarChart(values: [38, 62, 47, 82, 70, 96, 78]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          SectionTitle(
            title: 'Recent orders',
            action: 'View all',
            onAction: onOrders,
          ),
          const SizedBox(height: 10),
          if (store.orders.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              subtitle: 'New orders will appear here.',
            )
          else
            ...store.orders
                .take(3)
                .map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: OrderCard(order: order, onTap: () => onOrder(order)),
                  ),
                ),
        ],
      ),
    );
  }
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.detail,
    required this.onTap,
  });
  final double width;
  final String label, value, detail;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: .12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: color, size: 21),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Colors.black26,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    color: StockFlowTheme.navy,
                  ),
                ),
              ),
              Text(label, style: const TextStyle(color: Colors.black54)),
              const SizedBox(height: 8),
              Text(
                detail,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key, this.lowStockInitially = false});
  final bool lowStockInitially;
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String query = '';
  late bool lowOnly = widget.lowStockInitially;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreController>();
    final items = store.products
        .where(
          (p) =>
              (!lowOnly || p.isLowStock) &&
              '${p.name} ${p.sku} ${p.category}'.toLowerCase().contains(
                query.toLowerCase(),
              ),
        )
        .toList();
    return ListView(
      key: const ValueKey('inventory-page'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        TextField(
          key: const ValueKey('inventory-search'),
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search name, SKU, or category...',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilterChip(
              key: const ValueKey('low-stock-filter'),
              label: const Text('Low stock'),
              selected: lowOnly,
              onSelected: (value) => setState(() => lowOnly = value),
            ),
            const Spacer(),
            Text(
              '${items.length} products',
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (items.isEmpty)
          EmptyState(
            icon: Icons.search_off_rounded,
            title: lowOnly ? 'No low-stock products' : 'No matching products',
            subtitle: lowOnly
                ? 'Inventory levels currently look healthy.'
                : 'Try another search or clear the filter.',
          ),
        ...items.map(
          (product) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: ProductCard(
              product: product,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailsPage(productId: product.id),
                ),
              ),
              onEdit: () => showProductForm(context, product: product),
              onDelete: () => confirmDeleteProduct(context, product),
            ),
          ),
        ),
      ],
    );
  }
}

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });
  final Product product;
  final VoidCallback onTap, onEdit, onDelete;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: StockFlowTheme.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${product.sku} • ${product.category}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  Text(
                    money(product.price),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${product.stock} in stock',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: product.isLowStock
                        ? Colors.orange.shade800
                        : StockFlowTheme.mint,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Product actions',
                  style: IconButton.styleFrom(
                    minimumSize: const Size(32, 32),
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onSelected: (value) =>
                      value == 'edit' ? onEdit() : onDelete(),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key, required this.onOrder});
  final ValueChanged<SalesOrder> onOrder;
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<StoreController>().orders;
    return ListView(
      key: const ValueKey('orders-page'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        const InfoBanner(
          icon: Icons.notifications_active_outlined,
          text: 'Order SF-1048 is ready for dispatch. Customer notification queued.',
        ),
        const SizedBox(height: 14),
        if (orders.isEmpty)
          const EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'No orders yet',
            subtitle: 'Orders will appear here when created.',
          )
        else
          ...orders.map(
            (order) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OrderCard(order: order, onTap: () => onOrder(order)),
            ),
          ),
      ],
    );
  }
}

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, required this.onTap});
  final SalesOrder order;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.id,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: StockFlowTheme.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      money(order.total),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: StockFlowTheme.navy,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 7),
            Text(
              order.customer,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Text(
                    '${order.items} items • ${DateFormat('MMM d, yyyy').format(order.date)}',
                    maxLines: 2,
                    style: const TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                OrderStatusChip(status: order.status),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});
  final OrderStatus status;
  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.delivered => StockFlowTheme.mint,
      OrderStatus.processing => StockFlowTheme.blue,
      OrderStatus.pending => Colors.orange.shade800,
    };
    return Container(
      key: ValueKey('status-${status.name}'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        toBeginningOfSentenceCase(status.name),
        maxLines: 1,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key, required this.onCustomer});
  final ValueChanged<Customer> onCustomer;
  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final customers = context
        .watch<StoreController>()
        .customers
        .where(
          (customer) => '${customer.name} ${customer.company} ${customer.email}'
              .toLowerCase()
              .contains(query.toLowerCase()),
        )
        .toList();
    return ListView(
      key: const ValueKey('customers-page'),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        TextField(
          onChanged: (value) => setState(() => query = value),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search customers...',
          ),
        ),
        const SizedBox(height: 14),
        if (customers.isEmpty)
          const EmptyState(
            icon: Icons.person_search_outlined,
            title: 'No matching customers',
            subtitle: 'Try a different name, company, or email.',
          ),
        ...customers.map(
          (customer) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: InkWell(
                onTap: () => widget.onCustomer(customer),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: const Color(0xFFDBEAFE),
                        child: Text(
                          customer.name
                              .split(' ')
                              .map((part) => part[0])
                              .join(),
                          style: const TextStyle(
                            color: StockFlowTheme.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              customer.company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              customer.email,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        children: [
                          Text(
                            '${customer.orders}',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          const Text(
                            'orders',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right,
                            color: Colors.black38,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OrderDetailsPage extends StatelessWidget {
  const OrderDetailsPage({super.key, required this.order});
  final SalesOrder order;
  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: 'Order details',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                order.id,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: StockFlowTheme.navy,
                ),
              ),
            ),
            OrderStatusChip(status: order.status),
          ],
        ),
        const SizedBox(height: 18),
        DetailCard(
          children: [
            DetailRow(
              icon: Icons.storefront_outlined,
              label: 'Customer / company',
              value: order.customer,
            ),
            DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Order date',
              value: DateFormat('MMMM d, yyyy').format(order.date),
            ),
            DetailRow(
              icon: Icons.inventory_2_outlined,
              label: 'Items',
              value: '${order.items} products',
            ),
            DetailRow(
              icon: Icons.payments_outlined,
              label: 'Order total',
              value: money(order.total),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.cloud_done_outlined,
          text: 'This order is synchronized with the offline demo workspace.',
        ),
      ],
    ),
  );
}

class CustomerDetailsPage extends StatelessWidget {
  const CustomerDetailsPage({super.key, required this.customer});
  final Customer customer;
  @override
  Widget build(BuildContext context) {
    final recent = context
        .watch<StoreController>()
        .orders
        .where((order) => order.customer == customer.company)
        .toList();
    return DetailScaffold(
      title: 'Customer details',
      child: ListView(
        key: const ValueKey('customer-details-page'),
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: const Color(0xFFDBEAFE),
                    child: Text(
                      customer.name.split(' ').map((part) => part[0]).join(),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: StockFlowTheme.blue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    customer.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    customer.company,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 16),
                  DetailRow(
                    icon: Icons.email_outlined,
                    label: 'Demo email',
                    value: customer.email,
                  ),
                  DetailRow(
                    icon: Icons.receipt_long_outlined,
                    label: 'Total historical orders',
                    value: '${customer.orders} orders',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(title: 'Recent orders', action: 'Seeded records'),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No recent orders',
              subtitle:
                  'No seeded recent records are available for this customer.',
            )
          else
            ...recent.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderCard(
                  order: order,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsPage(order: order),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductDetailsPage extends StatelessWidget {
  const ProductDetailsPage({super.key, required this.productId});
  final String productId;
  @override
  Widget build(BuildContext context) {
    final product = context
        .watch<StoreController>()
        .products
        .where((item) => item.id == productId)
        .firstOrNull;
    if (product == null) {
      return const DetailScaffold(
        title: 'Product details',
        child: EmptyState(
          icon: Icons.inventory_2_outlined,
          title: 'Product unavailable',
          subtitle: 'This product may have been deleted.',
        ),
      );
    }
    return DetailScaffold(
      title: 'Product details',
      actions: [
        IconButton(
          tooltip: 'Edit product',
          onPressed: () => showProductForm(context, product: product),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FF),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.inventory_2_outlined,
                          color: StockFlowTheme.blue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  DetailRow(
                    icon: Icons.qr_code_outlined,
                    label: 'SKU',
                    value: product.sku,
                  ),
                  DetailRow(
                    icon: Icons.category_outlined,
                    label: 'Category',
                    value: product.category,
                  ),
                  DetailRow(
                    icon: Icons.payments_outlined,
                    label: 'Price',
                    value: money(product.price),
                  ),
                  DetailRow(
                    icon: Icons.inventory_outlined,
                    label: 'Available stock',
                    value: '${product.stock} units',
                  ),
                  DetailRow(
                    icon: Icons.warning_amber_outlined,
                    label: 'Reorder threshold',
                    value: '${product.reorderAt} units',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class RevenueDetailsPage extends StatelessWidget {
  const RevenueDetailsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreController>();
    final delivered = store.orders
        .where((order) => order.status == OrderStatus.delivered)
        .toList();
    return DetailScaffold(
      title: 'Revenue details',
      child: ListView(
        key: const ValueKey('revenue-details-page'),
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [StockFlowTheme.navy, Color(0xFF28456F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivered-order revenue',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 6),
                Text(
                  money(store.revenue),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${delivered.length} completed orders',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const SectionTitle(
            title: 'Recent completed sales',
            action: 'Demo data',
          ),
          const SizedBox(height: 10),
          if (delivered.isEmpty)
            const EmptyState(
              icon: Icons.payments_outlined,
              title: 'No completed sales',
              subtitle: 'Delivered orders will contribute to revenue.',
            )
          else
            ...delivered.map(
              (order) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: OrderCard(
                  order: order,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsPage(order: order),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});
  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: 'Notifications',
    child: ListView(
      key: const ValueKey('notifications-page'),
      padding: const EdgeInsets.all(20),
      children: const [
        NotificationTile(
          icon: Icons.warning_amber_rounded,
          color: Colors.orange,
          title: 'Low-stock alert',
          message: 'Two products have reached their reorder threshold.',
          time: '10 min ago',
        ),
        NotificationTile(
          icon: Icons.local_shipping_outlined,
          color: StockFlowTheme.blue,
          title: 'Order ready for dispatch',
          message: 'Order SF-1048 is ready for the next fulfillment step.',
          time: '1 hr ago',
        ),
        NotificationTile(
          icon: Icons.cloud_done_outlined,
          color: StockFlowTheme.mint,
          title: 'Synchronization completed',
          message: 'Offline inventory changes are safely synchronized.',
          time: 'Today',
        ),
      ],
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});
  @override
  Widget build(BuildContext context) => DetailScaffold(
    title: 'Demo profile',
    child: ListView(
      key: const ValueKey('profile-page'),
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 34,
                  backgroundColor: Color(0xFFDBEAFE),
                  child: Text(
                    'AD',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: StockFlowTheme.blue,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Alex Demo',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const Text(
                  'StockFlow Demo Account',
                  style: TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),
                const DetailRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: 'Store Manager',
                ),
                const DetailRow(
                  icon: Icons.cloud_done_outlined,
                  label: 'Workspace status',
                  value: 'Synced • offline-ready',
                ),
                const DetailRow(
                  icon: Icons.notifications_active_outlined,
                  label: 'Notifications',
                  value: 'Demo alerts enabled',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        const InfoBanner(
          icon: Icons.info_outline,
          text: 'StockFlow is a credential-free Flutter portfolio demo using fictional business data.',
        ),
      ],
    ),
  );
}

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.time,
  });
  final IconData icon;
  final Color color;
  final String title, message, time;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 3),
                  Text(message, style: const TextStyle(color: Colors.black54)),
                  const SizedBox(height: 6),
                  Text(
                    time,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class DetailScaffold extends StatelessWidget {
  const DetailScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), actions: actions),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: child,
        ),
      ),
    ),
  );
}

class DetailCard extends StatelessWidget {
  const DetailCard({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(children: children),
    ),
  );
}

class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: StockFlowTheme.blue),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 12),
              ),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    ),
  );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle({
    super.key,
    required this.title,
    required this.action,
    this.onAction,
  });
  final String title, action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: StockFlowTheme.navy,
          ),
        ),
      ),
      const SizedBox(width: 12),
      ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 112),
        child: onAction == null
            ? Text(
                action,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  color: Colors.black45,
                  fontWeight: FontWeight.w600,
                ),
              )
            : TextButton(onPressed: onAction, child: Text(action)),
      ),
    ],
  );
}

class BarChart extends StatelessWidget {
  const BarChart({super.key, required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: List.generate(
      values.length,
      (i) => Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: FractionallySizedBox(
                    heightFactor: values[i] / 100,
                    child: Container(
                      decoration: BoxDecoration(
                        color: i == 5
                            ? StockFlowTheme.blue
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                ['M', 'T', 'W', 'T', 'F', 'S', 'S'][i],
                style: const TextStyle(fontSize: 11, color: Colors.black45),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFFECFDF5),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      children: [
        Icon(icon, color: StockFlowTheme.mint),
        const SizedBox(width: 12),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF065F46))),
        ),
      ],
    ),
  );
}

class LoadingState extends StatelessWidget {
  const LoadingState({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(20),
    children: List.generate(
      5,
      (i) => Container(
        height: i == 0 ? 140 : 88,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .7),
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    ),
  );
}

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.black38),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: retry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 18),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 52, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.black54),
        ),
      ],
    ),
  );
}

String money(double value) =>
    NumberFormat.simpleCurrency(decimalDigits: 0).format(value);

Future<void> showProductForm(BuildContext context, {Product? product}) async {
  final key = GlobalKey<FormState>();
  final name = TextEditingController(text: product?.name),
      sku = TextEditingController(text: product?.sku),
      category = TextEditingController(text: product?.category),
      price = TextEditingController(text: product?.price.toStringAsFixed(0)),
      stock = TextEditingController(text: product?.stock.toString());
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        MediaQuery.viewInsetsOf(sheetContext).bottom + 24,
      ),
      child: Form(
        key: key,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                product == null ? 'Add new product' : 'Edit product',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: requiredField,
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) => constraints.maxWidth < 380
                    ? Column(
                        children: [
                          TextFormField(
                            controller: sku,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(labelText: 'SKU'),
                            validator: requiredField,
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            controller: category,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Category',
                            ),
                            validator: requiredField,
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: sku,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'SKU',
                              ),
                              validator: requiredField,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: category,
                              textInputAction: TextInputAction.next,
                              decoration: const InputDecoration(
                                labelText: 'Category',
                              ),
                              validator: requiredField,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(labelText: 'Price'),
                      validator: positiveNumber,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      validator: wholeNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                key: const ValueKey('save-product'),
                onPressed: () async {
                  if (!key.currentState!.validate()) return;
                  final controller = context.read<StoreController>();
                  if (product == null) {
                    await controller.addProduct(
                      name: name.text.trim(),
                      sku: sku.text.trim(),
                      category: category.text.trim(),
                      price: double.parse(price.text),
                      stock: int.parse(stock.text),
                    );
                  } else {
                    await controller.updateProduct(
                      product.copyWith(
                        name: name.text.trim(),
                        sku: sku.text.trim(),
                        category: category.text.trim(),
                        price: double.parse(price.text),
                        stock: int.parse(stock.text),
                      ),
                    );
                  }
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    product == null ? 'Save product' : 'Save changes',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  name.dispose();
  sku.dispose();
  category.dispose();
  price.dispose();
  stock.dispose();
}

Future<void> confirmDeleteProduct(BuildContext context, Product product) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete product?'),
      content: Text(
        '${product.name} will be removed from this demo inventory.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed == true && context.mounted) {
    await context.read<StoreController>().deleteProduct(product.id);
  }
}

String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
String? positiveNumber(String? value) {
  final parsed = double.tryParse(value ?? '');
  return parsed == null || parsed < 0 ? 'Enter a valid number' : null;
}

String? wholeNumber(String? value) {
  final parsed = int.tryParse(value ?? '');
  return parsed == null || parsed < 0 ? 'Enter a whole number' : null;
}
