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
  static const labels = ['Overview', 'Inventory', 'Orders', 'Customers'];
  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 850;
    final pages = const [
      DashboardPage(),
      InventoryPage(),
      OrdersPage(),
      CustomersPage(),
    ];
    final content = SafeArea(
      child: Column(
        children: [
          _TopBar(title: labels[index]),
          Expanded(
            child: Consumer<StoreController>(
              builder: (context, store, child) {
                if (store.isLoading) {
                  return const _LoadingState();
                }
                if (store.error != null) {
                  return _ErrorState(message: store.error!, retry: store.load);
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
                _SideNav(
                  index: index,
                  onChanged: (v) => setState(() => index = v),
                ),
                Expanded(child: content),
              ],
            )
          : content,
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (v) => setState(() => index = v),
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
              onPressed: () => _showProductForm(context),
              icon: const Icon(Icons.add),
              label: const Text('Add product'),
            )
          : null,
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 18, 20, 10),
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
          smallSize: 8,
          child: IconButton.filledTonal(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Notifications are up to date')),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ),
        const SizedBox(width: 10),
        const CircleAvatar(
          backgroundColor: Color(0xFFDBEAFE),
          child: Text(
            'AD',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: StockFlowTheme.blue,
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
  const DashboardPage({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<StoreController>();
    return RefreshIndicator(
      onRefresh: s.load,
      child: ListView(
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
                Icon(Icons.auto_graph_rounded, color: Colors.white38, size: 64),
              ],
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (_, c) {
              final w = c.maxWidth > 700
                  ? (c.maxWidth - 36) / 4
                  : (c.maxWidth - 12) / 2;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _Metric(
                    width: w,
                    label: 'Revenue',
                    value: money(s.revenue),
                    icon: Icons.payments_outlined,
                    color: StockFlowTheme.mint,
                    delta: '+12.4%',
                  ),
                  _Metric(
                    width: w,
                    label: 'Orders',
                    value: '${s.orders.length}',
                    icon: Icons.shopping_bag_outlined,
                    color: StockFlowTheme.blue,
                    delta: '+8.2%',
                  ),
                  _Metric(
                    width: w,
                    label: 'Products',
                    value: '${s.products.length}',
                    icon: Icons.inventory_2_outlined,
                    color: Colors.deepPurple,
                    delta: 'Active',
                  ),
                  _Metric(
                    width: w,
                    label: 'Low stock',
                    value: '${s.lowStockCount}',
                    icon: Icons.warning_amber_rounded,
                    color: Colors.orange,
                    delta: 'Needs action',
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 22),
          const _SectionTitle(
            title: 'Sales performance',
            action: 'Last 7 days',
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                height: 150,
                child: _BarChart(values: const [38, 62, 47, 82, 70, 96, 78]),
              ),
            ),
          ),
          const SizedBox(height: 22),
          const _SectionTitle(title: 'Recent orders', action: 'View all'),
          const SizedBox(height: 10),
          ...s.orders
              .take(3)
              .map(
                (o) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _OrderTile(order: o),
                ),
              ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.delta,
  });
  final double width;
  final String label, value, delta;
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(height: 14),
            Text(
              value,
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: StockFlowTheme.navy,
              ),
            ),
            Text(label, style: const TextStyle(color: Colors.black54)),
            const SizedBox(height: 8),
            Text(
              delta,
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
  );
}

class _BarChart extends StatelessWidget {
  const _BarChart({required this.values});
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

class InventoryPage extends StatefulWidget {
  const InventoryPage({super.key});
  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  String query = '';
  bool lowOnly = false;
  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreController>();
    final items = store.products
        .where(
          (p) =>
              (!lowOnly || p.isLowStock) &&
              ('${p.name} ${p.sku} ${p.category}'.toLowerCase().contains(
                query.toLowerCase(),
              )),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
      children: [
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search name, SKU, or category...',
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            FilterChip(
              label: const Text('Low stock'),
              selected: lowOnly,
              onSelected: (v) => setState(() => lowOnly = v),
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
          const _EmptyState(
            icon: Icons.search_off_rounded,
            title: 'No matching products',
            subtitle: 'Try another search or clear the filter.',
          ),
        ...items.map(
          (p) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Card(
              child: ListTile(
                contentPadding: const EdgeInsets.all(14),
                leading: Container(
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
                title: Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text('${p.sku}  •  ${p.category}\n${money(p.price)}'),
                isThreeLine: true,
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${p.stock} in stock',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: p.isLowStock
                            ? Colors.orange.shade800
                            : StockFlowTheme.mint,
                      ),
                    ),
                    PopupMenuButton(
                      style: IconButton.styleFrom(
                        minimumSize: const Size(32, 32),
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: const Text('Delete'),
                        ),
                      ],
                      onSelected: (_) => store.deleteProduct(p.id),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OrdersPage extends StatelessWidget {
  const OrdersPage({super.key});
  @override
  Widget build(BuildContext context) {
    final orders = context.watch<StoreController>().orders;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
      children: [
        const _InfoBanner(
          icon: Icons.notifications_active_outlined,
          text: 'Order SF-1048 is ready for dispatch. Customer notification queued.',
        ),
        const SizedBox(height: 14),
        ...orders.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _OrderTile(order: o),
          ),
        ),
      ],
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});
  final SalesOrder order;
  @override
  Widget build(BuildContext context) {
    final color = switch (order.status) {
      OrderStatus.delivered => StockFlowTheme.mint,
      OrderStatus.processing => StockFlowTheme.blue,
      OrderStatus.pending => Colors.orange,
    };
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: .12),
          child: Icon(Icons.receipt_long_outlined, color: color),
        ),
        title: Row(
          children: [
            Text(order.id, style: const TextStyle(fontWeight: FontWeight.w800)),
            const Spacer(),
            Text(
              money(order.total),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            '${order.customer}  •  ${order.items} items\n${DateFormat('MMM d, yyyy').format(order.date)}',
          ),
        ),
        isThreeLine: true,
        trailing: Padding(
          padding: const EdgeInsets.only(top: 45),
          child: Text(
            order.status.name,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

class CustomersPage extends StatelessWidget {
  const CustomersPage({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
    children: [
      const TextField(
        decoration: InputDecoration(
          prefixIcon: Icon(Icons.search),
          hintText: 'Search customers...',
        ),
      ),
      const SizedBox(height: 14),
      ...context.watch<StoreController>().customers.map(
        (c) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(14),
              leading: CircleAvatar(
                backgroundColor: const Color(0xFFDBEAFE),
                child: Text(
                  c.name.split(' ').map((e) => e[0]).join(),
                  style: const TextStyle(
                    color: StockFlowTheme.blue,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                c.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text('${c.company}\n${c.email}'),
              isThreeLine: true,
              trailing: Text(
                '${c.orders}\norders',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          ),
        ),
      ),
    ],
  );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});
  final String title, action;
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
      Flexible(
        child: Text(
          action,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: StockFlowTheme.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ],
  );
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
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

class _LoadingState extends StatelessWidget {
  const _LoadingState();
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.retry});
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.cloud_off_rounded, size: 52, color: Colors.black38),
        const SizedBox(height: 12),
        Text(message),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title, subtitle;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 60),
    child: Column(
      children: [
        Icon(icon, size: 52, color: Colors.black26),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        Text(subtitle, style: const TextStyle(color: Colors.black54)),
      ],
    ),
  );
}

String money(double value) =>
    NumberFormat.simpleCurrency(decimalDigits: 0).format(value);

Future<void> _showProductForm(BuildContext context) async {
  final key = GlobalKey<FormState>();
  final name = TextEditingController(),
      sku = TextEditingController(),
      category = TextEditingController(),
      price = TextEditingController(),
      stock = TextEditingController();
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
              const Text(
                'Add new product',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              TextFormField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: requiredField,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: sku,
                      decoration: const InputDecoration(labelText: 'SKU'),
                      validator: requiredField,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextFormField(
                      controller: category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      validator: requiredField,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: price,
                      keyboardType: TextInputType.number,
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
                      validator: positiveNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: () async {
                  if (!key.currentState!.validate()) return;
                  await context.read<StoreController>().addProduct(
                    name: name.text,
                    sku: sku.text,
                    category: category.text,
                    price: double.parse(price.text),
                    stock: int.parse(stock.text),
                  );
                  if (sheetContext.mounted) Navigator.pop(sheetContext);
                },
                child: const Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('Save product'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String? requiredField(String? value) =>
    value == null || value.trim().isEmpty ? 'Required' : null;
String? positiveNumber(String? value) =>
    double.tryParse(value ?? '') == null || double.parse(value!) < 0
    ? 'Enter a valid number'
    : null;
