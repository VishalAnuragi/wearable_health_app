import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/shop_bloc.dart';
import 'order_history_screen.dart';

class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Store'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => BlocProvider.value(
                    value: context.read<ShopBloc>(),
                    child: const OrderHistoryScreen(),
                  ))
              );
            },
          )
        ],
      ),
      body: BlocConsumer<ShopBloc, ShopState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!), backgroundColor: Colors.red),
            );
          } else if (state.checkoutSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Order placed successfully!'), backgroundColor: Colors.green),
            );
          }
        },
        builder: (context, state) {
          if (state.isLoading && state.products.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.products.isEmpty) {
            return const Center(child: Text('No products available.'));
          }

          return ListView.builder(
            itemCount: state.products.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final product = state.products[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(product.description),
                  trailing: ElevatedButton(
                    onPressed: () => context.read<ShopBloc>().add(AddToCart(product)),
                    child: Text('\$${product.price.toStringAsFixed(2)}'),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: BlocBuilder<ShopBloc, ShopState>(
        builder: (context, state) {
          if (state.cart.isEmpty) return const SizedBox.shrink();

          final total = state.cart.fold(0.0, (sum, item) => sum + item.price);

          return FloatingActionButton.extended(
            onPressed: state.isLoading
                ? null
                : () => context.read<ShopBloc>().add(CheckoutCart()),
            icon: state.isLoading
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white))
                : const Icon(Icons.shopping_cart_checkout),
            label: Text('Checkout (${state.cart.length}) - \$${total.toStringAsFixed(2)}'),
          );
        },
      ),
    );
  }
}