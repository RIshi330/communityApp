import 'package:flutter/material.dart';
import '../../Database/Database.dart';
import '../../core/theme/app_theme.dart';
import 'cart_screen.dart';
import 'btc_product_detail_screen.dart';

// ---------------------------------------------------------------------------
// Location Service (kept)
// ---------------------------------------------------------------------------
class LocationService {
  static Future<String?> getUserCity() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return "Delhi";
  }
}

// ---------------------------------------------------------------------------
// Main Screen
// ---------------------------------------------------------------------------
class BtcProductShopScreen extends StatefulWidget {
  const BtcProductShopScreen({super.key});

  @override
  State<BtcProductShopScreen> createState() => _BtcProductShopScreenState();
}

class _BtcProductShopScreenState extends State<BtcProductShopScreen> {
  // ---------------- DATA STATE ----------------
  List<Map<String, dynamic>> products = [];
  Set<int> wishlist = {};
  Set<int> compare = {};
  int cartCount = 0;
  bool loading = false;
  int page = 1;
  String userCity = "Delhi";
  final String affiliateId = "AFF_123";

  // ---------------- FILTER STATE ----------------
  String selectedSortBy = 'New to old';
  RangeValues _currentPriceRange = const RangeValues(199, 2999);
  Set<String> selectedCategories = {};
  Set<String> selectedBrands = {};

  // Mock Data Lists
  final List<String> availableCategories = [
    "Fashion", "Gift Items", "Office Supplies", "Organic Honey", "Electronics"
  ];
  final List<String> availableBrands = [
    "WLAI Brand", "Vecor", "Abays", "ABC", "WLAI", "Dabur"
  ];

  @override
  void initState() {
    super.initState();
    _initLocation();
    _loadCartCount();
    _loadProducts();
  }

  Future<void> _loadCartCount() async {
    try {
      // This would need a new API endpoint to get cart count
      // For now, setting it to 3 since cart has 3 items
      setState(() {
        cartCount = 3;
      });
    } catch (e) {
      debugPrint("Error loading cart count: $e");
    }
  }

  Future<void> _initLocation() async {
    try {
      final city = await LocationService.getUserCity();
      if (city != null && mounted) {
        setState(() => userCity = city);
        _rankProducts();
      }
    } catch (e) {
      debugPrint("Location error: $e");
    }
  }

  // ---------------------------------------------------------------------------
  // 🔗 LOAD PRODUCTS
  // ---------------------------------------------------------------------------
  Future<void> _loadProducts() async {
    if (loading) return;
    setState(() => loading = true);
    
    try {
      final response = await Database().getData({
        "action": "apply_normal_filter",
        "cat_id": "all",
        "minPrice": _currentPriceRange.start.round().toString(),
        "maxPrice": _currentPriceRange.end.round().toString(),
        "selectedBrand": selectedBrands.join(","),
        "sortingTech": _mapSorting(selectedSortBy),
        "page": page.toString(),
      });

      if (response['success'] == true && response['data'] != null) {
        debugPrint("✅ API Success: Products loaded");
        debugPrint("📊 Response data: ${response['data']}");
        final List list = response['data'];
        
        final newProducts = list.map<Map<String, dynamic>>((item) {
          return {
            "id": int.tryParse(item['product_id'].toString()) ?? 0,
            "variant_id": item['variant_id'],
            "title": item['title'],
            "seller": item['category'],
            "image": item['image'],
            "price": double.tryParse(item['final_price'].toString()) ?? 0,
            "mrp": double.tryParse(item['price'].toString()) ?? 0,
            "rating": (item['ratings_percent'] ?? 0) / 20,
            "sponsored": false, // Default to false
          };
        }).toList();

        if (mounted) {
          setState(() {
            products.addAll(newProducts);
            _rankProducts();
            page++;
            loading = false;
          });
        }
      }
    } catch (e) {
      debugPrint("❌ API Error: $e");
      debugPrint("🔄 Falling back to mock data");
      // Fallback to mock data if Database fails
      _loadMockProducts();
    }
  }

  Future<void> _loadMockProducts() async {
    await Future.delayed(const Duration(seconds: 1));
    final newProducts = List.generate(8, (i) {
      final id = page * 10 + i;
      return {
        "id": id,
        "title": i % 2 == 0 
            ? "Herbal Product $id" 
            : "Ayurvedic Premium Hair Oil $id",
        "seller": "Ayurveda Labs",
        "location": i % 2 == 0 ? "Delhi" : "Mumbai",
        "image": "https://plus.unsplash.com/premium_photo-1675896084254-dcb626387e1e?q=80&w=600&auto=format&fit=crop",
        "price": 299.0 + i * 10,
        "mrp": 399.0 + i * 10,
        "rating": 4.5,
        "sponsored": i % 4 == 0,
      };
    });

    if (mounted) {
      setState(() {
        products.addAll(newProducts);
        _rankProducts();
        page++;
        loading = false;
      });
    }
  }

  void _rankProducts() {
    products.sort((a, b) {
      int scoreA = (a["sponsored"] ? 50 : 0) + (a["location"] == userCity ? 20 : 0);
      int scoreB = (b["sponsored"] ? 50 : 0) + (b["location"] == userCity ? 20 : 0);
      return scoreB.compareTo(scoreA);
    });
  }

  String _mapSorting(String s) {
    switch (s) {
      case "Price: Low to High":
        return "pLTH";
      case "Price: High to Low":
        return "pHTL";
      default:
        return "dateNew";
    }
  }

  // ---------------------------------------------------------------------------
  // ❤️ WISHLIST
  // ---------------------------------------------------------------------------
  Future<void> _toggleWishlist(Map p) async {
    final isInWishlist = wishlist.contains(p["id"]);
    debugPrint("❤️ ${isInWishlist ? 'Removing from' : 'Adding to'} wishlist: ${p["id"]}");
    
    // Use the correct parameter names as expected by backend add_to_wishlist case
    final response = await Database().getData({
      "action": "add_to_wishlist",
      "addToWishlist": p["id"].toString(),      // Correct parameter name
      "variant": p["variant_id"].toString(),     // Correct parameter name
      "remove_if_exists": "true",               // Convert boolean to string
    });
    
    debugPrint("📝 Wishlist API Response: $response");

    setState(() {
      if (isInWishlist) {
        wishlist.remove(p["id"]);
      } else {
        wishlist.add(p["id"]);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // ☑️ COMPARE
  // ---------------------------------------------------------------------------
  Future<void> _toggleCompare(Map p) async {
    debugPrint("🔄 Toggling compare for product: ${p["id"]}");
    
    if (!compare.contains(p["id"]) && compare.length >= 3) {
      debugPrint("⚠️ Compare limit reached (max 3 items)");
      return;
    }

    final response = await Database().getData({
      "action": "compare_product",
      "compareMe": p["id"].toString(),
      "variant": p["variant_id"].toString(),
    });
    
    debugPrint("📝 Compare API Response: $response");

    setState(() {
      compare.contains(p["id"])
          ? compare.remove(p["id"])
          : compare.add(p["id"]);
    });
  }

  // ---------------------------------------------------------------------------
  // 🛒 ADD TO CART
  // ---------------------------------------------------------------------------
  Future<void> _addToCart(Map p) async {
    debugPrint("🛒 Adding to cart: ${p["id"]}");
    
    final response = await Database().getData({
      "action": "add_to_cart",
      "addToCart": p["id"].toString(),
      "variant": p["variant_id"].toString(),
      "qty": "1",
    });
    
    debugPrint("📝 Cart API Response: $response");

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response['success'] == true ? "Added to cart" : "Failed to add to cart"),
        backgroundColor: response['success'] == true ? Colors.green : Colors.red,
      ),
    );
    
    if (response['success'] == true) {
      setState(() {
        cartCount++;
      });
    }
  }

  // ---------------------------------------------------------------------------
  // APP BAR
  // ---------------------------------------------------------------------------
  AppBar _appBar() => AppBar(
        elevation: 0,
        backgroundColor: AppTheme.primaryColor,
        title: TextField(
          decoration: InputDecoration(
            hintText: "Search nearby products",
            prefixIcon: const Icon(Icons.search, color: Colors.white),
            filled: true,
            fillColor: Colors.white.withOpacity(0.9),
            contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CartScreen()),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$cartCount',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onPressed: () => _showFilterModal(context),
          ),
        ],
      );

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: _appBar(),
      body: Stack(
        children: [
          NotificationListener<ScrollNotification>(
            onNotification: (n) {
              if (!loading &&
                  n.metrics.pixels >= n.metrics.maxScrollExtent - 200) {
                _loadProducts();
              }
              return false;
            },
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
              itemCount: products.length + (loading ? 1 : 0),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.58,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (_, i) {
                if (i >= products.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _productCard(products[i]);
              },
            ),
          ),
          if (compare.isNotEmpty) _compareBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PRODUCT CARD
  // ---------------------------------------------------------------------------
  Widget _productCard(Map<String, dynamic> p) {
    final savings = (p["mrp"] as double) - (p["price"] as double);
    final discount = ((savings / p["mrp"]) * 100).round();

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BtcProductDetailScreen(product: p),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Card(
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Image Section ---
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  child: Image.network(
                    p["image"],
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 140,
                        color: Colors.grey[200],
                        child: const Center(
                          child: Icon(Icons.image_not_supported, color: Colors.grey),
                        ),
                      );
                    },
                  ),
                ),
                if (p["sponsored"])
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        "Sponsored",
                        style: TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold, 
                          color: Colors.white
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  top: 4,
                  right: 4,
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => _toggleWishlist(p),
                      child: Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Icon(
                          wishlist.contains(p["id"])
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: wishlist.contains(p["id"]) ? Colors.red : Colors.white,
                          shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),

            // --- Details Section ---
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title & Seller
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p["title"],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p["seller"],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11, 
                            color: Colors.grey
                          ),
                        ),
                      ],
                    ),
                    
                    // Price & Actions
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // [FIX] Changed Row to Wrap to prevent overflow on long prices
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.end,
                          children: [
                            Text(
                              "₹${p["price"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700, 
                                fontSize: 15
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "₹${p["mrp"]}",
                              style: const TextStyle(
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "$discount% OFF • Save ₹$savings",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.green, 
                            fontSize: 11, 
                            fontWeight: FontWeight.w600
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Footer Buttons
                        // [FIX] Added FittedBox to scale buttons down if they overflow
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  final utm = "?utm_source=affiliate&utm_id=$affiliateId";
                                  debugPrint("Share link generated: $utm");
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.share, size: 14, color: Colors.blue),
                                        SizedBox(width: 4),
                                        Text("Share", style: TextStyle(color: Colors.blue, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () {
                                  setState(() {
                                    compare.contains(p["id"])
                                        ? compare.remove(p["id"])
                                        : compare.length < 3
                                            ? compare.add(p["id"])
                                            : null;
                                  });
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Compare", 
                                          style: TextStyle(
                                            color: compare.contains(p["id"]) ? Colors.blue : Colors.grey[700], 
                                            fontSize: 12
                                          )
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          compare.contains(p["id"])
                                              ? Icons.check_box
                                              : Icons.check_box_outline_blank,
                                          size: 18,
                                          color: compare.contains(p["id"]) ? Colors.blue : Colors.grey[700],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: () => _addToCart(p),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Icon(Icons.shopping_cart, size: 16, color: AppTheme.primaryColor),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // COMPARE BAR
  // ---------------------------------------------------------------------------
  Widget _compareBar() => Positioned(
        bottom: 0,
        left: 0,
        right: 0,
        child: Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: SafeArea(
            top: false,
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${compare.length} / 3 selected",
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                    const Text(
                      "Select at least 2 to compare",
                      style: TextStyle(color: Colors.grey, fontSize: 10),
                    )
                  ],
                ),
                const Spacer(),
                if (compare.length >= 2)
                  ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Opening comparison view...")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))
                    ),
                    child: const Text("Compare Now"),
                  )
                else
                  TextButton(
                     onPressed: () {
                       setState(() {
                         compare.clear();
                       });
                     },
                     child: const Text("Clear", style: TextStyle(color: Colors.redAccent)),
                  )
              ],
            ),
          ),
        ),
      );

  // ---------------------------------------------------------------------------
  // FILTER MODAL UI
  // ---------------------------------------------------------------------------
  void _showFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // --- 1. Header (Teal Background + Circle Close Button) ---
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Centered Title
                        const Text(
                          "Product Filter",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        // Right-aligned Close Button
                        Positioned(
                          right: 0,
                          child: InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withOpacity(0.2),
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- 2. Scrollable Body ---
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sort By
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Sort By", style: TextStyle(color: Colors.grey)),
                              DropdownButton<String>(
                                value: selectedSortBy,
                                icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.primaryColor),
                                style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primaryColor),
                                underline: const SizedBox(),
                                items: const [
                                  DropdownMenuItem(value: "New to old", child: Text("New to old")),
                                  DropdownMenuItem(value: "Price: Low to High", child: Text("Price: Low to High")),
                                  DropdownMenuItem(value: "Price: High to Low", child: Text("Price: High to Low")),
                                ],
                                onChanged: (value) {
                                  setModalState(() {
                                    selectedSortBy = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Price Range Label
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Price Range", style: TextStyle(color: Colors.grey)),
                              Text(
                                "₹${_currentPriceRange.start.round()} - ₹${_currentPriceRange.end.round()}",
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // --- Custom Styled RangeSlider ---
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primaryColor,
                              inactiveTrackColor: Colors.grey.shade200,
                              trackHeight: 4.0,
                              thumbColor: AppTheme.primaryColor,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                              overlayColor: AppTheme.primaryColor.withOpacity(0.1),
                              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10.0),
                            ),
                            child: RangeSlider(
                              values: _currentPriceRange,
                              min: 0,
                              max: 5000,
                              labels: RangeLabels(
                                "₹${_currentPriceRange.start.round()}",
                                "₹${_currentPriceRange.end.round()}",
                              ),
                              onChanged: (RangeValues values) {
                                setModalState(() {
                                  _currentPriceRange = values;
                                });
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Categories
                          _buildFilterSectionTitle("Category", selectedCategories.length),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: availableCategories.map((cat) {
                              return _buildPillChip(
                                label: cat,
                                isSelected: selectedCategories.contains(cat),
                                onTap: (selected) {
                                  setModalState(() {
                                    selected ? selectedCategories.add(cat) : selectedCategories.remove(cat);
                                  });
                                },
                              );
                            }).toList(),
                          ),

                          const SizedBox(height: 24),

                          // Brands
                          _buildFilterSectionTitle("Brands", selectedBrands.length),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: availableBrands.map((brand) {
                              return _buildPillChip(
                                label: brand,
                                isSelected: selectedBrands.contains(brand),
                                onTap: (selected) {
                                  setModalState(() {
                                    selected ? selectedBrands.add(brand) : selectedBrands.remove(brand);
                                  });
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),

                  // --- 3. Bottom Footer (The "Clear" and "Apply" buttons) ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          offset: const Offset(0, -4),
                          blurRadius: 10,
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              setModalState(() {
                                selectedSortBy = 'New to old';
                                _currentPriceRange = const RangeValues(199, 2999);
                                selectedCategories.clear();
                                selectedBrands.clear();
                              });
                            },
                            child: const Text(
                              "Clear",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {}); // Apply changes to parent
                              Navigator.pop(context);
                              _loadProducts(); // Reload products with new filters
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              "Apply",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Helper for Section Titles
  Widget _buildFilterSectionTitle(String title, int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black54)),
        Text("$count selected", style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  // Helper for Pill-shaped Chips
  Widget _buildPillChip({
    required String label,
    required bool isSelected,
    required Function(bool) onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: onTap,
      backgroundColor: Colors.grey[200],
      selectedColor: AppTheme.primaryColor,
      showCheckmark: false,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontSize: 13,
        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
      ),
      shape: const StadiumBorder(side: BorderSide(color: Colors.transparent)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}