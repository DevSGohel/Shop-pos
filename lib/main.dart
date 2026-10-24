import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  runApp(const RetailBillingApp());
}

class RetailBillingApp extends StatelessWidget {
  const RetailBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dukan Billing POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1E88E5)),
        useMaterial3: true,
      ),
      home: const CounterScreen(),
    );
  }
}

class Product {
  final String id;
  final String name;
  final double price;
  int stock;

  Product({required this.id, required this.name, required this.price, required this.stock});
}

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
  double get total => product.price * quantity;
}

class CounterScreen extends StatefulWidget {
  const CounterScreen({super.key});

  @override
  State<CounterScreen> createState() => _CounterScreenState();
}

class _CounterScreenState extends State<CounterScreen> {
  final List<Product> _catalog = [
    Product(id: '1', name: 'Cotton Shirt', price: 450, stock: 25),
    Product(id: '2', name: 'Formal Trousers', price: 750, stock: 18),
    Product(id: '3', name: 'T-Shirt Plain', price: 250, stock: 40),
    Product(id: '4', name: 'Jeans Denim', price: 950, stock: 12),
    Product(id: '5', name: 'Kurta Pyjama Set', price: 1200, stock: 8),
  ];

  final List<CartItem> _cart = [];
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _customerNameController = TextEditingController();
  String _paymentMode = 'CASH';
  bool _isOnline = true; // In real app, listen to connectivity

  double get _subtotal => _cart.fold(0, (sum, item) => sum + item.total);

  void _addToCart(Product p) {
    setState(() {
      final index = _cart.indexWhere((item) => item.product.id == p.id);
      if (index >= 0) {
        _cart[index].quantity++;
      } else {
        _cart.add(CartItem(product: p));
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

  Future<void> _completeBillAndSendWhatsApp() async {
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty! Add products first.')),
      );
      return;
    }

    final phone = _phoneController.text.trim();
    final customer = _customerNameController.text.trim();

    // 1. Build Receipt text
    final billNo = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    final buffer = StringBuffer();
    buffer.writeln('🧾 *IMPEX RETAIL STORE*');
    buffer.writeln('---------------------------');
    buffer.writeln('Bill No: #$billNo');
    buffer.writeln('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}');
    if (customer.isNotEmpty) buffer.writeln('Customer: $customer');
    buffer.writeln('Mode: $_paymentMode');
    buffer.writeln('---------------------------');
    for (final item in _cart) {
      buffer.writeln('${item.product.name} x${item.quantity} = ₹${item.total.toStringAsFixed(0)}');
    }
    buffer.writeln('---------------------------');
    buffer.writeln('*TOTAL AMOUNT: ₹${_subtotal.toStringAsFixed(0)}*');
    buffer.writeln('---------------------------');
    buffer.writeln('Thank you for shopping with us! 🙏');

    // 2. Clear state
    setState(() {
      _cart.clear();
      _phoneController.clear();
      _customerNameController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bill saved offline & queued for sync!')),
    );

    // 3. Dispatch to WhatsApp if phone number provided
    if (phone.isNotEmpty) {
      final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
      final formattedPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
      final encodedText = Uri.encodeComponent(buffer.toString());
      final url = Uri.parse('https://wa.me/$formattedPhone?text=$encodedText');

      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Counter POS', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: _isOnline ? Colors.green.shade100 : Colors.amber.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.circle, size: 10, color: _isOnline ? Colors.green : Colors.amber.shade900),
                const SizedBox(width: 6),
                Text(
                  _isOnline ? 'Online (Synced)' : 'Offline Cache',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _isOnline ? Colors.green.shade900 : Colors.amber.shade900,
                  ),
                ),
              ],
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // 1. Catalog Grid
          Expanded(
            flex: 5,
            child: GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.6,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _catalog.length,
              itemBuilder: (context, index) {
                final p = _catalog[index];
                return InkWell(
                  onTap: () => _addToCart(p),
                  borderRadius: BorderRadius.circular(10),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('₹${p.price.toStringAsFixed(0)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                          Text('Stock: ${p.stock}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1),

          // 2. Live Cart & Customer Entry
          Expanded(
            flex: 6,
            child: Container(
              color: Colors.grey.shade50,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customerNameController,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'Customer Name (Opt)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            isDense: true,
                            labelText: 'WhatsApp No.',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ChoiceChip(
                        label: const Text('Cash'),
                        selected: _paymentMode == 'CASH',
                        onSelected: (_) => setState(() => _paymentMode = 'CASH'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('UPI'),
                        selected: _paymentMode == 'UPI',
                        onSelected: (_) => setState(() => _paymentMode = 'UPI'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Udhaar (Khata)'),
                        selected: _paymentMode == 'UDHAAR',
                        onSelected: (_) => setState(() => _paymentMode = 'UDHAAR'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: _cart.isEmpty
                        ? const Center(child: Text('Tap items above to add to bill'))
                        : ListView.separated(
                            itemCount: _cart.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final item = _cart[i];
                              return ListTile(
                                dense: true,
                                title: Text(item.product.name),
                                subtitle: Text('₹${item.product.price} x ${item.quantity}'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20),
                                      onPressed: () => _removeFromCart(i),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _completeBillAndSendWhatsApp,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline),
                        const SizedBox(width: 8),
                        Text(
                          'Save & Send WhatsApp Bill (₹${_subtotal.toStringAsFixed(0)})',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
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
