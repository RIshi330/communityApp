import 'package:flutter/material.dart';
import '../../Database/Database.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/theme/app_theme.dart';
import 'payment_adjustment_modal.dart';
import 'cart_payment_modal.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // App Theme Colors - Matching the app design
  static const Color primaryColor = AppTheme.primaryColor;
  static const Color accentColor = AppTheme.primaryColor;
  static const Color backgroundColor = AppTheme.backgroundColor;
  static const Color surfaceColor = Colors.white;
  static const Color cardShadowColor = Color(0x0A000000);

  List<CartItem> cart = [];
  List<CartItem> saved = [];
  bool loading = true;
  Map<String, dynamic> cartSummary = {};

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    setState(() => loading = true);
    
    try {
      final response = await Database().getData({
        "action": "get_cart_summary",
      });
      
      debugPrint("🛒 Full API Response: $response");
      
      // Check if response has the expected structure
      if (response['status'] == true && response['data'] != null) {
        final data = response['data'];
        
        // Handle items array safely
        List items = [];
        if (data['items'] != null) {
          try {
            items = data['items'] is List 
                ? data['items'] as List
                : [];
          } catch (e) {
            debugPrint("❌ Error parsing items: $e");
            items = [];
          }
        }
        
        // Handle summary safely
        Map<String, dynamic> summary = {};
        if (data['summary'] != null) {
          try {
            summary = data['summary'] is Map<String, dynamic>
                ? data['summary'] as Map<String, dynamic>
                : {};
          } catch (e) {
            debugPrint("❌ Error parsing summary: $e");
            summary = {};
          }
        }
        
        debugPrint("📊 Parsed items count: ${items.length}");
        debugPrint("📊 Parsed summary: $summary");
        
        // Fetch product details including images for each cart item
        final cartItems = <CartItem>[];
        for (var item in items) {
          try {
            // Get product details from product listing API
            final productResponse = await Database().getData({
              "action": "apply_normal_filter",
              "cat_id": "all",
              "minPrice": "0",
              "maxPrice": "9999",
              "selectedBrand": "",
              "sortingTech": "dateNew",
              "page": "1",
            });
            
            String productImage = "https://picsum.photos/seed/${item['product_id']}/70/70";
            
            if (productResponse['success'] == true && productResponse['data'] != null) {
              final List productList = productResponse['data'];
              // Find the matching product by product_id
              final matchingProduct = productList.firstWhere(
                (product) => product['product_id'].toString() == item['product_id'].toString(),
                orElse: () => null,
              );
              
              if (matchingProduct != null && matchingProduct['image'] != null) {
                productImage = matchingProduct['image'];
                debugPrint("✅ Found product image for ${item['product_id']}: $productImage");
              }
            }
            
            cartItems.add(CartItem(
              id: item['product_id'] ?? 0,
              type: _getCartItemType(item['marketplace_id'] ?? 5),
              title: item['name'] ?? "Unknown Product",
              seller: "Seller", // Backend doesn't provide seller name
              image: productImage, // Use actual product image from product listing API
              variant: "Variant ${item['variant_id'] ?? 0}",
              qty: item['quantity'] ?? 1,
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
            ));
          } catch (e) {
            debugPrint("❌ Error fetching product image for ${item['product_id']}: $e");
            // Fallback to placeholder if product fetch fails
            cartItems.add(CartItem(
              id: item['product_id'] ?? 0,
              type: _getCartItemType(item['marketplace_id'] ?? 5),
              title: item['name'] ?? "Unknown Product",
              seller: "Seller",
              image: "https://picsum.photos/seed/${item['product_id']}/70/70",
              variant: "Variant ${item['variant_id'] ?? 0}",
              qty: item['quantity'] ?? 1,
              price: (item['price'] as num?)?.toDouble() ?? 0.0,
            ));
          }
        }
        
        setState(() {
          cart = cartItems;
          cartSummary = summary;
          loading = false;
        });
      } else if (response['status'] == 300) {
        // Handle server not reachable error
        debugPrint("❌ Server not reachable (300)");
        setState(() {
          cart = [];
          cartSummary = {};
          loading = false;
        });
      } else {
        // Handle other errors
        debugPrint("❌ API returned status: ${response['status']}, error: ${response['error'] ?? 'Unknown'}");
        setState(() {
          cart = [];
          cartSummary = {};
          loading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error loading cart: $e");
      setState(() {
        cart = [];
        cartSummary = {};
        loading = false;
      });
    }
  }

  Future<void> _updateCartQuantity(CartItem item, int newQty) async {
    try {
      final response = await Database().getData({
        "action": "update_cart_quantity",
        "product_id": item.id,
        "quantity": newQty,
        "variant_id": item.variant,
      });
      
      debugPrint("🔄 Update Quantity Response: $response");
      
      if (response['success'] == true || response['status'] == true) {
        // Update local state
        setState(() {
          item.qty = newQty;
        });
        // Reload cart to get updated totals
        await _loadCart();
      } else {
        debugPrint("⚠️ Failed to update quantity: ${response['error'] ?? 'Unknown error'}");
      }
    } catch (e) {
      debugPrint("❌ Error updating cart quantity: $e");
    }
  }

  CartItemType _getCartItemType(int marketplaceId) {
    switch (marketplaceId) {
      case 5:
        return CartItemType.btc;
      case 6:
        return CartItemType.btb;
      case 16:
        return CartItemType.combo;
      default:
        return CartItemType.btc;
    }
  }

  // ---------------- CALCULATIONS ----------------

  double get subtotal {
    if (cart.isEmpty) return 0;
    return cart.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  double get gst {
    if (cartSummary.isEmpty) return 0;
    return (cartSummary['gst'] as num).toDouble();
  }

  double get discount {
    if (cartSummary.isEmpty) return 0;
    return (cartSummary['discount'] as num).toDouble();
  }

  double get grandTotal {
    if (cartSummary.isEmpty) return 0;
    return (cartSummary['grand_total'] as num).toDouble();
  }
  
  // ---------------- GROUP BY SELLER ----------------

  Map<String, List<CartItem>> get sellerGroups {
    final map = <String, List<CartItem>>{};
    for (var i in cart) {
      map.putIfAbsent(i.seller, () => []).add(i);
    }
    return map;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          "My Cart",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Text(
              "${cart.length} Items",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
      body: loading 
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : cart.isEmpty && saved.isEmpty
              ? _buildEmptyState()
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          ...sellerGroups.entries.map(
                            (e) => _sellerSection(e.key, e.value),
                          ),
                          if (saved.isNotEmpty) _savedSection(),
                          const SizedBox(height: 16),
                          _summary(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                    _checkoutButton(),
                  ],
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 60,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Your cart is empty",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Add some products to get started!",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              "Continue Shopping",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- SELLER SECTION ----------------

  Widget _sellerSection(String seller, List<CartItem> items) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.store,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      seller,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${items.length} items",
                      style: const TextStyle(
                        fontSize: 12,
                        color: primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...items.map(_cartItem),
            ],
          ),
        ),
      );

  // ---------------- CART ITEM ----------------

  Widget _cartItem(CartItem item) {
    switch (item.type) {
      case CartItemType.btc:
        return _btcItem(item);
      case CartItemType.btb:
        return _btbItem(item);
      case CartItemType.combo:
        return _comboItem(item);
    }
  }

  Widget _btcItem(CartItem item) => _baseItem(item, _qtyControls(item));

  Widget _btbItem(CartItem item) => _baseItem(
        item,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(4),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: item.selectedSlab,
                  isDense: true,
                  // Fix: Ensure dropdown doesn't cause overflow
                  isExpanded: false, 
                  items: List.generate(item.slabs!.length, (i) {
                    final s = item.slabs![i];
                    return DropdownMenuItem(
                      value: i,
                      child: Text(
                        "${s["label"]} @ ₹${s["price"]}",
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }),
                  onChanged: (v) =>
                      setState(() => item.selectedSlab = v as int),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _qtyControls(item, step: 10),
          ],
        ),
      );

  Widget _comboItem(CartItem item) => _baseItem(
        item,
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Combo Includes:",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            if (item.comboItems != null)
              ...item.comboItems!
                  .map((e) => Text("• $e", style: const TextStyle(fontSize: 12)))
            else
              const Text("• Combo items not available", style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            _qtyControls(item),
            const SizedBox(height: 4),
            const Text("10% Discount Applied",
                style: TextStyle(color: Colors.green, fontSize: 11)),
          ],
        ),
      );

  // ---------------- BASE CARD (ENHANCED) ----------------

  Widget _baseItem(CartItem item, Widget child) => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image with better styling
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    item.image,
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.grey.shade400,
                          size: 32,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Product Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF1A1A1A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        item.variant,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    child,
                  ],
                ),
              ),
              
              // Price and Actions
              SizedBox(
                width: 80,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "₹${item.subtotal.toInt()}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => setState(() => cart.remove(item)),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade400,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          cart.remove(item);
                          saved.add(item);
                        });
                      },
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 24),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        "Save",
                        style: TextStyle(
                          fontSize: 12,
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  // ---------------- QTY CONTROLS (ENHANCED) ----------------

  Widget _qtyControls(CartItem item, {int step = 1}) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _qtyBtn(Icons.remove, () async {
              final newQty = (item.qty - step).clamp(1, 99999);
              await _updateCartQuantity(item, newQty);
            }),
            Container(
              constraints: const BoxConstraints(minWidth: 40),
              alignment: Alignment.center,
              child: Text(
                "${item.qty}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            _qtyBtn(Icons.add, () async {
              final newQty = item.qty + step;
              await _updateCartQuantity(item, newQty);
            }),
          ],
        ),
      );

  Widget _qtyBtn(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon, 
            size: 16,
            color: primaryColor,
          ),
        ),
      );

  // ---------------- SAVED SECTION ----------------

  Widget _savedSection() => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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
                      color: accentColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.bookmark_outline,
                      color: accentColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Saved for Later",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...saved.map((i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          i.image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.broken_image),
                          ),
                        ),
                      ),
                    ),
                    title: Text(
                      i.title, 
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    trailing: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          saved.remove(i);
                          cart.add(i);
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: const Text(
                        "Move to Cart",
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ),
              )),
            ],
          ),
        ),
      );

  // ---------------- SUMMARY ----------------

  Widget _summary() => Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.receipt_long,
                      color: primaryColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Order Summary",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _row("Subtotal", subtotal),
              _row("GST", gst),
              if (discount > 0)
                _row("Discount", -discount, color: Colors.green),
              const Divider(height: 32),
              _row("Grand Total", grandTotal, bold: true, fontSize: 20),
            ],
          ),
        ),
      );

  Widget _row(String l, double v,
          {bool bold = false, Color? color, double fontSize = 14}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(l,
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                    fontSize: fontSize,
                    color: bold ? primaryColor : Colors.grey.shade700)),
            Text("₹${v.toInt()}",
                style: TextStyle(
                    fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                    color: color ?? (bold ? primaryColor : Colors.grey.shade800),
                    fontSize: fontSize)),
          ],
        ),
      );

  // ---------------- CHECKOUT ----------------

  Widget _checkoutButton() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor, // Dark teal color matching app
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24),
            ),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              
              if (cart.isEmpty) {
                scaffoldMessenger.showSnackBar(
                  const SnackBar(content: Text("Your cart is empty")),
                );
                return;
              }
              
              // Get user info from secure storage
              final userName = await FlutterSecureStorage().read(key: 'userName') ?? 'Guest User';
              final userEmail = await FlutterSecureStorage().read(key: 'userEmail') ?? 'guest@example.com';
              final userPhone = await FlutterSecureStorage().read(key: 'userPhone') ?? '9999999999';
              
              // Show Cart Payment Modal
              if (mounted) {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => CartPaymentModal(
                    amount: grandTotal,
                    orderId: 'ORD${DateTime.now().millisecondsSinceEpoch}',
                    customerName: userName,
                    customerEmail: userEmail,
                    customerPhone: userPhone,
                    cartItems: cart.map((item) => item.id.toString()).toList(),
                    onPaymentComplete: () {
                      // Clear cart after successful payment
                      setState(() {
                        cart.clear();
                        cartSummary.clear();
                      });
                    },
                  ),
                );
              }
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "Proceed to Checkout",
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      );
}

// ---------------- MODELS ----------------

enum CartItemType { btc, btb, combo }

class CartItem {
  final int id;
  final CartItemType type;
  final String title;
  final String seller;
  final String image;
  final String variant;
  int qty;
  double? price; // For BTC/Combo
  List<Map<String, dynamic>>? slabs; // For BTB
  int selectedSlab; // Index of selected slab
  List<String>? comboItems; // For Combo

  CartItem({
    required this.id,
    required this.type,
    required this.title,
    required this.seller,
    required this.image,
    required this.variant,
    this.qty = 1,
    this.price,
    this.slabs,
    this.selectedSlab = 0,
    this.comboItems,
  });

  double get currentPrice {
    if (type == CartItemType.btb && slabs != null) {
      return (slabs![selectedSlab]["price"] as num).toDouble();
    }
    return price ?? 0;
  }

  double get subtotal => currentPrice * qty;

  double get gstAmount => subtotal * 0.18; // Mock 18% GST
}
