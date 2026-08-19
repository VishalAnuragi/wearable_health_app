class Order {
  final String id;
  final List<String> productIds;
  final DateTime date;

  Order({required this.id, required this.productIds, required this.date});

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      productIds: List<String>.from(json['product_ids']),
      date: DateTime.parse(json['date']),
    );
  }
}