enum CartItemType { btc, btb, combo }

class CartItem {
  final int id;
  final CartItemType type;
  final String title;
  final String seller;
  final String image;
  final String variant;

  int qty;

  // BTC / Combo
  double? price;

  // BTB
  List<Map<String, dynamic>>? slabs;
  int selectedSlab;

  // Combo
  List<String>? comboItems;

  double gst;

  CartItem({
    required this.id,
    required this.type,
    required this.title,
    required this.seller,
    required this.image,
    required this.variant,
    required this.qty,
    this.price,
    this.slabs,
    this.selectedSlab = 0,
    this.comboItems,
    this.gst = 18,
  });

  double get unitPrice {
    switch (type) {
      case CartItemType.btc:
        return price!;
      case CartItemType.btb:
        return (slabs![selectedSlab]["price"] as num).toDouble();
      case CartItemType.combo:
        return price!;
    }
  }

  double get subtotal => unitPrice * qty;
  double get gstAmount => subtotal * gst / 100;
}
