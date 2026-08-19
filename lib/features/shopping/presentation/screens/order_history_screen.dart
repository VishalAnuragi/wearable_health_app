import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/shop_bloc.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ShopBloc>().add(LoadOrderHistory());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Order History')),
      body: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state.isLoading && state.orderHistory.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.orderHistory.isEmpty) {
            return const Center(child: Text('No past orders found.'));
          }
          return ListView.builder(
            itemCount: state.orderHistory.length,
            itemBuilder: (context, index) {
              final order = state.orderHistory[index];
              final dateStr = DateFormat('MMM d, y - h:mm a').format(order.date.toLocal());
              return ListTile(
                leading: const Icon(Icons.receipt),
                title: Text('Order ID: ${order.id}'),
                subtitle: Text('Items: ${order.productIds.length} | $dateStr'),
              );
            },
          );
        },
      ),
    );
  }
}