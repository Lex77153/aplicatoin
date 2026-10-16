import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}
class ItemModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String priceOrDate;
  final String category;
  bool isFavorite;

  ItemModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.priceOrDate,
    required this.category,
    this.isFavorite = false,
  });
}

//MAIN APPLICATION
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kazakhstan Discovery App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

//MAIN SCREEN WITH TABS
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  
  final List<ItemModel> _items = [
    ItemModel(
      id: '1',
      title: 'Traditional Kymyz (1L)',
      description: 'Authentic fermented mare’s milk rich in vitamins and health benefits, traditionally prepared according to ancient nomadic recipes.',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ48f5edhlk-CJlTSWoTL86eZ0s5sXsOMnPLo2E7ZJdnA&s=10',
      priceOrDate: '2,500 KZT',
      category: 'Beverage',
    ),
    ItemModel(
      id: '2',
      title: 'Traditional Kurt',
      description: 'Traditional dried salty cheese balls made from natural dairy, a staple nomadic snack packed with protein and rich flavor.',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcRlndsnJ55SFaFRibL1JAi2CZIHA_wqggy40u9HVdx9N7PClyiwPW2TYl0rb6IQCYHyQ3YV7k1dnlvLYHDYP78tqoSiDJzisYtdTflkTzSGJg&s=10',
      priceOrDate: '500 KZT',
      category: 'Snack',
    ),
    ItemModel(
      id: '3',
      title: 'EXPO Astana Wins Global Innovation Award',
      description: 'Astana International Financial Centre and green energy tech initiatives recognized globally for driving sustainable development in Central Asia.',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQBtIqspL__0yVpxCaJKtCd12sBxxN3x6laGo6IN7SKlg&s=10',
      priceOrDate: 'Oct 16, 2026',
      category: 'News',
    ),
    ItemModel(
      id: '4',
      title: 'Charyn Canyon Tourism Boom',
      description: 'Record number of international and local travelers visit the breathtaking Valley of Castles at Charyn Canyon this autumn season.',
      imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTMcZfdi7KfTSV7nQCNlVXXOjRa4SlZTxpdzu0DY6ZSFQ&s=10',
      priceOrDate: 'Oct 15, 2026',
      category: 'News',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final favorites = _items.where((item) => item.isFavorite).toList();

    final List<Widget> tabs = [
      FeedTab(
        items: _items,
        onItemTap: (item) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailScreen(),
              settings: RouteSettings(arguments: item),
            ),
          );
          setState(() {});
        },
        onFavoriteToggle: (item) {
          setState(() {
            item.isFavorite = !item.isFavorite;
          });
        },
      ),
      FavoritesTab(
        favorites: favorites,
        onItemTap: (item) async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DetailScreen(),
              settings: RouteSettings(arguments: item),
            ),
          );
          setState(() {});
        },
      ),
      const ProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.feed), label: 'Feed'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Favorites'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

//FEED
class FeedTab extends StatelessWidget {
  final List<ItemModel> items;
  final Function(ItemModel) onItemTap;
  final Function(ItemModel) onFavoriteToggle;

  const FeedTab({
    super.key,
    required this.items,
    required this.onItemTap,
    required this.onFavoriteToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kazakhstan Feed')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              ),
              title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(item.priceOrDate, style: const TextStyle(color: Colors.grey)),
              trailing: IconButton(
                icon: Icon(
                  item.isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: item.isFavorite ? Colors.red : null,
                ),
                onPressed: () => onFavoriteToggle(item),
              ),
              onTap: () => onItemTap(item),
            ),
          );
        },
      ),
    );
  }
}

// FAVORITES
class FavoritesTab extends StatelessWidget {
  final List<ItemModel> favorites;
  final Function(ItemModel) onItemTap;

  const FavoritesTab({
    super.key,
    required this.favorites,
    required this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Favorites')),
      body: favorites.isEmpty
          ? const Center(
              child: Text(
                'No favorite items saved yet!',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) {
                final item = favorites[index];
                return ListTile(
                  leading: Image.network(item.imageUrl, width: 50, height: 50, fit: BoxFit.cover),
                  title: Text(item.title),
                  subtitle: Text(item.priceOrDate),
                  onTap: () => onItemTap(item),
                );
              },
            ),
    );
  }
}

//PROFILE
class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage('https://i.ibb.co.com/hJFkGxtD/B7-FF2738-6072-48-E1-A82-C-F500-D5045-E45.png'),
            ),
            const SizedBox(height: 16),
            const Text('Daniyal Meiram', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text('daniyal.m@narxoz.kz', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('App Settings'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

//DETAIL SCREEN
class DetailScreen extends StatelessWidget {
  static const routeName = '/detail';

  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final item = ModalRoute.of(context)!.settings.arguments as ItemModel;

    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(
              item.imageUrl,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Chip(
                        label: Text(item.category),
                        backgroundColor: Colors.blue[100],
                      ),
                      Text(
                        item.priceOrDate,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    item.title,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.description,
                    style: const TextStyle(fontSize: 16, color: Colors.black87, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  
                  // Back Button with Nav
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Back to Feed'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
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
  }
}