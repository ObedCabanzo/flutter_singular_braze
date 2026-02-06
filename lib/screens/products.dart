import 'package:flutter/material.dart';
import 'package:singular_flutter_sdk/singular.dart';

class ProductsScreen extends StatelessWidget {
  final String? productId;

  const ProductsScreen({super.key, this.productId});

  @override
  Widget build(BuildContext context) {
    // Registrar evento de vista
    Singular.eventWithArgs("Products Screen Viewed", {
      "product_id": productId ?? 'all'
    });

    final List<Map<String, dynamic>> products = [
      {
        'id': '1',
        'name': 'Producto A',
        'price': '\$99.99',
        'icon': Icons.laptop,
        'color': Colors.blue,
      },
      {
        'id': '2',
        'name': 'Producto B',
        'price': '\$149.99',
        'icon': Icons.phone_android,
        'color': Colors.green,
      },
      {
        'id': '3',
        'name': 'Producto C',
        'price': '\$79.99',
        'icon': Icons.headphones,
        'color': Colors.orange,
      },
      {
        'id': '4',
        'name': 'Producto D',
        'price': '\$199.99',
        'icon': Icons.watch,
        'color': Colors.purple,
      },
    ];

    // Filtrar si hay un productId específico
    final filteredProducts = productId != null
        ? products.where((p) => p['id'] == productId).toList()
        : products;

    return Scaffold(
      appBar: AppBar(
        title: Text(productId != null ? 'Producto $productId' : 'Productos'),
        backgroundColor: Colors.green,
      ),
      body: filteredProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.search_off, size: 80, color: Colors.grey),
                  const SizedBox(height: 20),
                  Text(
                    'Producto no encontrado',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundColor: product['color'],
                      child: Icon(
                        product['icon'],
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    title: Text(
                      product['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      product['price'],
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_shopping_cart),
                      onPressed: () {
                        Singular.eventWithArgs("Product Add To Cart", {
                          "product_id": product['id'],
                          "product_name": product['name'],
                          "price": product['price'],
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product['name']} añadido al carrito'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                    onTap: () {
                      Singular.eventWithArgs("Product Clicked", {
                        "product_id": product['id'],
                        "product_name": product['name'],
                      });
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text(product['name']),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                product['icon'],
                                size: 80,
                                color: product['color'],
                              ),
                              const SizedBox(height: 16),
                              Text('Precio: ${product['price']}'),
                              const SizedBox(height: 8),
                              const Text(
                                'Descripción del producto aquí. Este es un producto de alta calidad.',
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cerrar'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product['name']} comprado'),
                                  ),
                                );
                              },
                              child: const Text('Comprar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
