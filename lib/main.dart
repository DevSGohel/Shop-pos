import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const ImpexPosApp());
}

class ImpexPosApp extends StatelessWidget {
  const ImpexPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Shop POS & Inventory',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF1E88E5),
        scaffoldBackgroundColor: const Color(0xFFF8F9FA),
        cardTheme: CardThemeData(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

// -------------------------------------------------------------
// MODELS & IN-MEMORY STORE
// -------------------------------------------------------------
class Product {
  String id;
  String name;
  double price;
  int stock;
  String category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    required this.stock,
    this.category = 'General',
  });
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}

class OrderRecord {
  final String orderId;
  final String customerName;
  final String customerPhone;
  final String paymentMode;
  final double totalAmount;
  final DateTime dateTime;
  final List<CartItem> items;

  OrderRecord({
    required this.orderId,
    required this.customerName,
    required this.customerPhone,
    required this.paymentMode,
    required this.totalAmount,
    required this.dateTime,
    required this.items,
  });
}

class AppState extends ChangeNotifier {
  final List<Product> catalog = [
    Product(id: '1', name: 'Cotton Shirt', price: 450, stock: 25, category: 'Shirts'),
    Product(id: '2', name: 'Formal Trousers', price: 750, stock: 18, category: 'Trousers'),
    Product(id: '3', name: 'T-Shirt Plain', price: 250, stock: 40, category: 'Shirts'),
    Product(id: '4', name: 'Jeans Denim', price: 950, stock: 12, category: 'Jeans'),
    Product(id: '5', name: 'Kurta Pyjama Set', price: 1200, stock: 8, category: 'Ethnic'),
  ];

  final List<OrderRecord> orders = [];

  void addProduct(String name, double price, int stock, String category) {
    catalog.add(
      Product(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        price: price,
        stock: stock,
        category: category.isEmpty ? 'General' : category,
      ),
    );
    notifyListeners();
  }

  void updateProduct(String id, String name, double price, int stock) {
    final index = catalog.indexWhere((p) => p.id == id);
    if (index >= 0) {
      catalog[index].name = name;
      catalog[index].price = price;
      catalog[index].stock = stock;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    catalog.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void recordSale({
    required String customerName,
    required String phone,
    required String paymentMode,
    required List<CartItem> cartItems,
    required double total,
  }) {
    for (var item in cartItems) {
      final idx = catalog.indexWhere((p) => p.id == item.product.id);
      if (idx >= 0) {
        catalog[idx].stock = (catalog[idx].stock - item.quantity).clamp(0, 99999);
      }
    }

    orders.insert(
      0,
      OrderRecord(
        orderId: DateTime.now().millisecondsSinceEpoch.toString().substring(7),
        customerName: customerName,
        customerPhone: phone,
        paymentMode: paymentMode,
        totalAmount: total,
        dateTime: DateTime.now(),
        items: List.from(cartItems),
      ),
    );
    notifyListeners();
  }

  double get todaySales => orders.fold(0.0, (sum, order) => sum + order.totalAmount);
  int get lowStockCount => catalog.where((p) => p.stock <= 5).length;
}

final globalAppState = AppState();

// -------------------------------------------------------------
// MAIN TAB NAVIGATION
// -------------------------------------------------------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 1; // Default to Counter POS

  final List<Widget> _pages = const [
    HomeDashboardScreen(),
    CounterPosScreen(),
    BackendInventoryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Counter POS',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Backend',
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// SCREEN 1: HOME DASHBOARD
// -------------------------------------------------------------
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store Overview', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: AnimatedBuilder(
        animation: globalAppState,
        builder: (context, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E88E5), Color(0xFF1565C0)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Today\'s Revenue',
                            style: TextStyle(color: Colors.white70, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '₹${globalAppState.todaySales.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 30,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${globalAppState.orders.length} Bills Processed',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                        ],
                      ),
                      const CircleAvatar(
                        radius: 28,
                        backgroundColor: Colors.white24,
                        child: Icon(Icons.account_balance_wallet, color: Colors.white, size: 28),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Quick Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _statCard(
                        'Total Products',
                        '${globalAppState.catalog.length}',
                        Icons.category,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _statCard(
                        'Low Stock Alert',
                        '${globalAppState.lowStockCount}',
                        Icons.warning_amber_rounded,
                        globalAppState.lowStockCount > 0 ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Recent Transactions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (globalAppState.orders.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: Center(
                      child: Text('No orders created yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: globalAppState.orders.length.clamp(0, 5),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = globalAppState.orders[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade50,
                          child: Icon(
                            order.paymentMode == 'UPI'
                                ? Icons.qr_code
                                : (order.paymentMode == 'UDHAAR' ? Icons.history : Icons.money),
                            color: Colors.blue.shade700,
                          ),
                        ),
                        title: Text(
                          order.customerName.isEmpty ? 'Bill #${order.orderId}' : order.customerName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${order.paymentMode} • ${order.items.length} items',
                        ),
                        trailing: Text(
                          '₹${order.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.black54, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// SCREEN 2: COUNTER POS
// -------------------------------------------------------------
class CounterPosScreen extends StatefulWidget {
  const CounterPosScreen({super.key});

  @override
  State<CounterPosScreen> createState() => _CounterPosScreenState();
}

class _CounterPosScreenState extends State<CounterPosScreen> {
  final List<CartItem> _cart = [];
  final TextEditingController _customerNameController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  String _paymentMode = 'Cash';

  double get _cartTotal => _cart.fold(0.0, (sum, item) => sum + item.total);

  void _addToCart(Product product) {
    if (product.stock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} is out of stock!')),
      );
      return;
    }

    setState(() {
      final existingIndex = _cart.indexWhere((c) => c.product.id == product.id);
      if (existingIndex >= 0) {
        if (_cart[existingIndex].quantity < product.stock) {
          _cart[existingIndex].quantity++;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cannot exceed available stock limit!')),
          );
        }
      } else {
        _cart.add(CartItem(product: product, quantity: 1));
      }
    });
  }

  void _removeFromCart(int index) {
    setState(() {
      if (_cart[index].quantity > 1) {
        _cart[index].quantity--;
      } else {
        _cart.removeAt(index);
      }
    });
  }

  Future<void> _processBill() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add items to cart first!')),
      );
      return;
    }

    final billId = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final customer = _customerNameController.text.trim();
    final phone = _whatsappController.text.trim();
    final total = _cartTotal;

    globalAppState.recordSale(
      customerName: customer,
      phone: phone,
      paymentMode: _paymentMode,
      cartItems: _cart,
      total: total,
    );

    final billText = StringBuffer();
    billText.writeln('🧾 *BILL RECEIPT - STORE*');
    billText.writeln('--------------------------------');
    billText.writeln('Bill No: #$billId');
    if (customer.isNotEmpty) billText.writeln('Customer: $customer');
    billText.writeln('Payment: $_paymentMode');
    billText.writeln('Date: ${DateTime.now().toLocal().toString().split('.')[0]}');
    billText.writeln('--------------------------------');
    for (var item in _cart) {
      billText.writeln(
        '• ${item.product.name} x${item.quantity} = ₹${item.total.toStringAsFixed(0)}',
      );
    }
    billText.writeln('--------------------------------');
    billText.writeln('*Total: ₹${total.toStringAsFixed(0)}*');
    billText.writeln('--------------------------------');
    billText.writeln('Thank you for shopping with us!');

    setState(() {
      _cart.clear();
      _customerNameController.clear();
      _whatsappController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill saved successfully!')),
    );

    if (phone.isNotEmpty) {
      final sanitizedPhone = phone.replaceAll(RegExp(r'\D'), '');
      final fullPhone = sanitizedPhone.length == 10 ? '91$sanitizedPhone' : sanitizedPhone;
      final encodedMessage = Uri.encodeComponent(billText.toString());
      final whatsappUrl = Uri.parse('https://wa.me/$fullPhone?text=$encodedMessage');

      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter POS', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: Colors.green.shade800),
                const SizedBox(width: 6),
                Text(
                  'Online (Synced)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.green.shade900,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: AnimatedBuilder(
        animation: globalAppState,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                flex: 5,
                child: GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: globalAppState.catalog.length,
                  itemBuilder: (context, index) {
                    final p = globalAppState.catalog[index];
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _addToCart(p),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₹${p.price.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Stock: ${p.stock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: p.stock <= 5 ? Colors.red : Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, -3))
                  ],
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                ),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Customer Name (Opt)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _whatsappController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'WhatsApp No.',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _paymentChip('Cash'),
                        const SizedBox(width: 6),
                        _paymentChip('UPI'),
                        const SizedBox(width: 6),
                        _paymentChip('Udhaar (Khata)'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 110,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _cart.isEmpty
                          ? const Center(
                              child: Text(
                                'Tap items above to add to bill',
                                style: TextStyle(color: Colors.black45),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _cart.length,
                              itemBuilder: (context, i) {
                                final item = _cart[i];
                                return ListTile(
                                  dense: true,
                                  visualDensity: const VisualDensity(vertical: -4),
                                  title: Text(item.product.name, maxLines: 1),
                                  subtitle: Text('₹${item.product.price} x ${item.quantity}'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, size: 20),
                                        onPressed: () => _removeFromCart(i),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, size: 20),
                                        onPressed: () => _addToCart(item.product),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        'Save & Send WhatsApp Bill (₹${_cartTotal.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _processBill,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _paymentChip(String title) {
    final isSelected = _paymentMode == title;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (_) => setState(() => _paymentMode = title),
    );
  }
}

// -------------------------------------------------------------
// SCREEN 3: BACKEND (ITEM & STOCK MANAGER)
// -------------------------------------------------------------
class BackendInventoryScreen extends StatelessWidget {
  const BackendInventoryScreen({super.key});

  void _showItemDialog(BuildContext context, [Product? product]) {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: isEdit ? product.name : '');
    final priceCtrl = TextEditingController(text: isEdit ? product.price.toStringAsFixed(0) : '');
    final stockCtrl = TextEditingController(text: isEdit ? product.stock.toString() : '');
    final catCtrl = TextEditingController(text: isEdit ? product.category : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEdit ? 'Edit ${product.name}' : 'Add New Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainBuildContext.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Item Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Price (₹)',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Stock Units',
                  prefixIcon: Icon(Icons.inventory_2),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              if (!isEdit)
                TextField(
                  controller: catCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Category (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final price = double.tryParse(priceCtrl.text) ?? 0.0;
              final stock = int.tryParse(stockCtrl.text) ?? 0;

              if (name.isEmpty) return;

              if (isEdit) {
                globalAppState.updateProduct(product.id, name, price, stock);
              } else {
                globalAppState.addProduct(name, price, stock, catCtrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory Backend', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Add Product'),
        onPressed: () => _showItemDialog(context),
      ),
      body: AnimatedBuilder(
        animation: globalAppState,
        builder: (context, _) {
          return ListView.separated(
            padding: const EdgeInsets.only(left: 12, right: 12, top: 12, bottom: 80),
            itemCount: globalAppState.catalog.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = globalAppState.catalog[index];
              return Card(
                child: ListTile(
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    'Price: ₹${product.price.toStringAsFixed(0)} | Stock: ${product.stock} units',
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showItemDialog(context, product),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => globalAppState.deleteProduct(product.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
