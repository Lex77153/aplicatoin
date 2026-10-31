import 'package:flutter/material.dart';
import '../models/product.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({Key? key}) : super(key: key);

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  // Начальный набор данных с картинками
  final List<Product> _products = [
    Product(
      id: '1',
      title: 'Wireless Headphones',
      category: 'Electronics',
      rating: 4.5,
      price: 59.99,
      imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
    ),
    Product(
      id: '2',
      title: 'Smart Watch',
      category: 'Accessories',
      rating: 4.2,
      price: 129.99,
      imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
    ),
    Product(
      id: '3',
      title: 'Running Shoes',
      category: 'Sports',
      rating: 4.8,
      price: 89.99,
      imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
    ),
    Product(
      id: '4',
      title: 'Minimalist Backpack',
      category: 'Fashion',
      rating: 4.6,
      price: 45.00,
      imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
    ),
  ];

  bool _isGridView = false; // Переключатель между List и Grid


  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    setState(() {
      final newId = DateTime.now().millisecondsSinceEpoch.toString();
      _products.insert(
        0,
        Product(
          id: newId,
          title: 'Polaroid OneStep 2',
          category: 'Electronics',
          rating: 5.0,
          price: 19.99,
          imageUrl: 'https://images.unsplash.com/photo-1526170375885-4d8ecf77b99f?w=500',
        ),
      );
    });
  }

  // Полное восстановление исходного каталога[cite: 1]
  void _resetCatalog() {
    setState(() {
      _products.clear();
      _products.addAll([
        Product(
          id: '1',
          title: 'Wireless Headphones',
          category: 'Electronics',
          rating: 4.5,
          price: 59.99,
          imageUrl: 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
        ),
        Product(
          id: '2',
          title: 'Smart Watch',
          category: 'Accessories',
          rating: 4.2,
          price: 129.99,
          imageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=500',
        ),
        Product(
          id: '3',
          title: 'Running Shoes',
          category: 'Sports',
          rating: 4.8,
          price: 89.99,
          imageUrl: 'https://images.unsplash.com/photo-1542291026-7eec264c27ff?w=500',
        ),
        Product(
          id: '4',
          title: 'Minimalist Backpack',
          category: 'Fashion',
          rating: 4.6,
          price: 45.00,
          imageUrl: 'https://images.unsplash.com/photo-1553062407-98eeb64c6a62?w=500',
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Catalog & Infinite Feed'),
        actions: [
          // Кнопка переключения вида List / Grid[cite: 1]
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
        ],
      ),
      body: _products.isEmpty
          ? _buildEmptyState() // Пустое состояние, если 0 элементов[cite: 1]
          : RefreshIndicator(
              onRefresh: _handleRefresh, // Логика Pull-to-Refresh[cite: 1]
              child: _isGridView ? _buildGridView() : _buildListView(),
            ),
    );
  }

  // Вид режима списка (ListView.separated)[cite: 1]
  Widget _buildListView() {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(), // Включает скролл для Pull-to-Refresh
      itemCount: _products.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildDismissibleItem(product, index);
      },
    );
  }

  // Вид режима сетки (GridView.builder)[cite: 1]
  Widget _buildGridView() {
    return GridView.builder(
      physics: const AlwaysScrollableScrollPhysics(), // Включает скролл для Pull-to-Refresh
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72, // Защита от RenderFlex overflow[cite: 1]
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildDismissibleItem(product, index, isGrid: true);
      },
    );
  }

  // Обертка Dismissible для Swipe-to-Delete[cite: 1]
  Widget _buildDismissibleItem(Product product, int index, {bool isGrid = false}) {
    return Dismissible(
      key: ValueKey(product.id), // Обязательный ValueKey[cite: 1]
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red, // Красный фон при свайпе[cite: 1]
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        final removedProduct = product;
        final removedIndex = index;

        setState(() {
          _products.removeAt(index);
        });

        // SnackBar с кнопкой UNDO[cite: 1]
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${removedProduct.title} deleted'),
            action: SnackBarAction(
              label: 'UNDO',
              onPressed: () {
                setState(() {
                  _products.insert(removedIndex, removedProduct); // Возврат элемента[cite: 1]
                });
              },
            ),
          ),
        );
      },
      child: isGrid ? _buildGridCard(product) : _buildListTile(product),
    );
  }

  // Карточка для ListView с картинкой
  Widget _buildListTile(Product product) {
    return ListTile(
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8.0),
        child: Image.network(
          product.imageUrl,
          width: 50,
          height: 50,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
        ),
      ),
      title: Text(product.title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text('${product.category} • ⭐ ${product.rating}'),
      trailing: Text(
        '\$${product.price.toStringAsFixed(2)}',
        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
      ),
    );
  }

  // Карточка для GridView с картинкой
  Widget _buildGridCard(Product product) {
    return Card(
      elevation: 2,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product.imageUrl,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(product.category, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '\$${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    Text('⭐ ${product.rating}', style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Экран пустого состояния (Empty State)[cite: 1]
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.inbox, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Catalog is Empty', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _resetCatalog, // Кнопка восстановления[cite: 1]
            child: const Text('Reset Catalog'),
          ),
        ],
      ),
    );
  }
}