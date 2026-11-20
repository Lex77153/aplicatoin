import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AppStorage {
  static const String keyDarkMode = 'app_theme_dark_mode';
  static const String keyUserName = 'user_display_name';
  static const String keyNotes = 'notes_json_list';
  static const String defaultUserName = 'Guest User';

  static late final SharedPreferences prefs;
  static late final ValueNotifier<bool> darkMode;

  static Future<void> init() async {
    prefs = await SharedPreferences.getInstance();
    darkMode = ValueNotifier<bool>(prefs.getBool(keyDarkMode) ?? false);
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // обязательно перед async-работой
  await AppStorage.init(); // читаем тему с диска до первого кадра
  runApp(const MinimalBazarApp());
}

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class AppColors {
  final Color background;
  final Color surface;
  final Color primary;
  final Color accent;
  final Color muted;
  final Color border;

  const AppColors({
    required this.background,
    required this.surface,
    required this.primary,
    required this.accent,
    required this.muted,
    required this.border,
  });

  static const AppColors light = AppColors(
    background: Color(0xFFFAFAFA),
    surface: Colors.white,
    primary: Color(0xFF111111),
    accent: Color(0xFF0066CC),
    muted: Color(0xFF767676),
    border: Color(0xFFE5E5E5),
  );

  static const AppColors dark = AppColors(
    background: Color(0xFF0F0F10),
    surface: Color(0xFF1A1A1C),
    primary: Color(0xFFF2F2F2),
    accent: Color(0xFF4DA3FF),
    muted: Color(0xFF9A9AA0),
    border: Color(0xFF2E2E32),
  );

  static AppColors of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? dark : light;
}

ThemeData buildAppTheme(Brightness brightness) {
  final c = brightness == Brightness.dark ? AppColors.dark : AppColors.light;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    scaffoldBackgroundColor: c.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: c.primary,
      brightness: brightness,
      primary: c.primary,
      onPrimary: c.surface,
      surface: c.surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: c.surface,
      foregroundColor: c.primary,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: Colors.transparent,
    ),
  );
}

class MinimalBazarApp extends StatelessWidget {
  const MinimalBazarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: AppStorage.darkMode,
      builder: (context, isDark, _) {
        return MaterialApp(
          title: 'Altyn Bazar',
          debugShowCheckedModeBanner: false,
          scrollBehavior: AppScrollBehavior(),
          theme: buildAppTheme(Brightness.light),
          darkTheme: buildAppTheme(Brightness.dark),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          home: const ProductExplorerScreen(),
        );
      },
    );
  }
}

class Product {
  final int id;
  final String title;
  final double price;
  final String description;
  final String category;
  final String imageUrl;
  final double rating;
  final int reviewCount;

  Product({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.category,
    required this.imageUrl,
    required this.rating,
    required this.reviewCount,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final ratingMap = json['rating'] as Map<String, dynamic>?;

    return Product(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      category: json['category']?.toString() ?? '',
      imageUrl: json['image']?.toString() ?? '',
      rating: (ratingMap?['rate'] as num?)?.toDouble() ?? 0.0,
      reviewCount: (ratingMap?['count'] as num?)?.toInt() ?? 0,
    );
  }

  String get categoryLabel {
    switch (category.toLowerCase()) {
      case "men's clothing":
        return 'Ерлер киімі';
      case "women's clothing":
        return 'Әйелдер киімі';
      case 'jewelery':
        return 'Зергерлік бұйымдар';
      case 'electronics':
        return 'Электроника';
      default:
        return category;
    }
  }
}

class NoteItem {
  final String id;
  final String title;
  final String dateText;
  final bool isCompleted;

  const NoteItem({
    required this.id,
    required this.title,
    required this.dateText,
    this.isCompleted = false,
  });

  NoteItem copyWith({bool? isCompleted}) {
    return NoteItem(
      id: id,
      title: title,
      dateText: dateText,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'dateText': dateText,
        'isCompleted': isCompleted,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) {
    return NoteItem(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      dateText: json['dateText']?.toString() ?? '',
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class ProductExplorerScreen extends StatefulWidget {
  const ProductExplorerScreen({super.key});

  @override
  State<ProductExplorerScreen> createState() => _ProductExplorerScreenState();
}

class _ProductExplorerScreenState extends State<ProductExplorerScreen> {
  static const String _apiUrl = 'https://fakestoreapi.com/products';

  List<Product> _products = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http
          .get(Uri.parse(_apiUrl))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List decodedList = jsonDecode(response.body);
        final parsedProducts = decodedList
            .map((item) => Product.fromJson(item as Map<String, dynamic>))
            .toList();

        if (!mounted) return;
        setState(() {
          _products = parsedProducts;
          _isLoading = false;
        });
      } else {
        throw Exception('HTTP ошибка: ${response.statusCode}');
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Уақыт шектеуі асып кетті (Timeout).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Желі байланысы жоқ (Offline).';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Altyn Bazar',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notes & Settings',
            icon: const Icon(Icons.edit_note_rounded, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotesVaultScreen()),
              );
            },
          ),
          const SizedBox(width: 4),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: c.border, height: 1),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final c = AppColors.of(context);

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: c.primary,
          strokeWidth: 2,
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.wifi_off_rounded, size: 40, color: c.muted),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: c.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _fetchProducts,
                style: ElevatedButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.surface,
                ),
                child: const Text('Retry Connection'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      color: c.primary,
      backgroundColor: c.surface,
      onRefresh: _fetchProducts,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _products.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final product = _products[index];
          return _ProductCard(
            product: product,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(product: product),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Row(
          children: [
            Hero(
              tag: 'product_image_${product.id}',
              child: Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Image.network(
                  product.imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) =>
                      Icon(Icons.broken_image, color: c.muted),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.categoryLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.primary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text(
                            '${product.rating}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
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

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late final List _gallerySlides = [
    {'url': widget.product.imageUrl, 'scale': 1.0, 'angle': 0.0},
    {'url': widget.product.imageUrl, 'scale': 1.25, 'angle': 0.04},
    {'url': widget.product.imageUrl, 'scale': 0.85, 'angle': -0.04},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (page >= 0 && page < _gallerySlides.length) {
      _pageController.animateToPage(
        page,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _showShareDeepLinkSheet() {
    final String deepLink = 'narxoz://store/product/${widget.product.id}';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.of(context).surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final c = AppColors.of(sheetContext);

        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Deep Link',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.primary,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: c.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: c.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        deepLink,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                          color: c.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy_rounded,
                          size: 20, color: c.primary),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: deepLink));
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Сілтеме буферге көшірілді'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final c = AppColors.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, size: 22),
            onPressed: _showShareDeepLinkSheet,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: c.border, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.white, 
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: _gallerySlides.length,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    itemBuilder: (context, index) {
                      final slide = _gallerySlides[index];
                      final imageWidget = Transform.rotate(
                        angle: slide['angle'] as double,
                        child: Transform.scale(
                          scale: slide['scale'] as double,
                          child: Padding(
                            padding: const EdgeInsets.all(32.0),
                            child: Image.network(
                              slide['url'] as String,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      );

                      if (index == 0) {
                        return Hero(
                          tag: 'product_image_${product.id}',
                          child: imageWidget,
                        );
                      }
                      return imageWidget;
                    },
                  ),
                  Positioned(
                    top: 14,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: c.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: c.border),
                      ),
                      child: Text(
                        '${_currentPage + 1} / ${_gallerySlides.length}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: c.primary,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage > 0)
                    Positioned(
                      left: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () => _goToPage(_currentPage - 1),
                          icon: const Icon(Icons.chevron_left_rounded,
                              size: 28),
                          style: IconButton.styleFrom(
                            foregroundColor: c.primary,
                            backgroundColor: c.background.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                  if (_currentPage < _gallerySlides.length - 1)
                    Positioned(
                      right: 8,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: IconButton(
                          onPressed: () => _goToPage(_currentPage + 1),
                          icon: const Icon(Icons.chevron_right_rounded,
                              size: 28),
                          style: IconButton.styleFrom(
                            foregroundColor: c.primary,
                            backgroundColor: c.background.withOpacity(0.85),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 14,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_gallerySlides.length, (index) {
                        final isSelected = _currentPage == index;
                        return GestureDetector(
                          onTap: () => _goToPage(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeOut,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 6,
                            width: isSelected ? 20 : 6,
                            decoration: BoxDecoration(
                              color: isSelected ? c.primary : c.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
            Container(color: c.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.categoryLabel.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: c.muted,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: c.primary,
                      height: 1.25,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '\$${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: c.primary,
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${product.rating} (${product.reviewCount})',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: c.muted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Сипаттама',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: c.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    product.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: c.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          border: Border(top: BorderSide(color: c.border, width: 1)),
        ),
        child: SafeArea(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Себетке қосылды'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Себетке қосу (Add to Cart)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NotesVaultScreen extends StatefulWidget {
  const NotesVaultScreen({super.key});

  @override
  State<NotesVaultScreen> createState() => _NotesVaultScreenState();
}

class _NotesVaultScreenState extends State<NotesVaultScreen> {
  late final TextEditingController _nameController;
  final TextEditingController _noteController = TextEditingController();

  late String _displayName;
  late List<NoteItem> _notes;

  @override
  void initState() {
    super.initState();

    final savedName = AppStorage.prefs.getString(AppStorage.keyUserName);
    _displayName = savedName ?? AppStorage.defaultUserName;
    _nameController = TextEditingController(text: savedName ?? '');
    _notes = _readNotes();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  List<NoteItem> _readNotes() {
    final raw = AppStorage.prefs.getString(AppStorage.keyNotes);
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((item) => NoteItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveNotes() async {
    final encoded = jsonEncode(_notes.map((n) => n.toJson()).toList());
    await AppStorage.prefs.setString(AppStorage.keyNotes, encoded);
  }

  Future<void> _toggleTheme(bool value) async {
    AppStorage.darkMode.value = value; // мгновенно меняем тему в UI
    await AppStorage.prefs.setBool(AppStorage.keyDarkMode, value);
  }

  Future<void> _saveName() async {
    FocusScope.of(context).unfocus();
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      _showMessage('Алдымен атыңызды енгізіңіз');
      return;
    }

    await AppStorage.prefs.setString(AppStorage.keyUserName, name);
    if (!mounted) return;
    setState(() => _displayName = name);
    _showMessage('Аты сақталды');
  }

  void _addNote() {
    final title = _noteController.text.trim();
    if (title.isEmpty) return;

    final note = NoteItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      dateText: _formatNow(),
    );

    setState(() => _notes.insert(0, note));
    _noteController.clear();
    _saveNotes();
  }

  void _toggleNote(String id) {
    final index = _notes.indexWhere((n) => n.id == id);
    if (index == -1) return;

    setState(() {
      _notes[index] =
          _notes[index].copyWith(isCompleted: !_notes[index].isCompleted);
    });
    _saveNotes();
  }

  void _deleteNote(String id) {
    setState(() => _notes.removeWhere((n) => n.id == id));
    _saveNotes();
  }

  String _formatNow() {
    final d = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(d.day)}.${two(d.month)}.${d.year}  ${two(d.hour)}:${two(d.minute)}';
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final doneCount = _notes.where((n) => n.isCompleted).length;
    final initial = _displayName.trim().isEmpty
        ? '?'
        : _displayName.trim()[0].toUpperCase();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notes & Settings Vault',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: c.border, height: 1),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(16),
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: c.border),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: c.primary,
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: c.surface,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Сәлем,',
                              style: TextStyle(fontSize: 12, color: c.muted),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: c.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  child: ValueListenableBuilder<bool>(
                    valueListenable: AppStorage.darkMode,
                    builder: (context, isDark, _) {
                      return Row(
                        children: [
                          Icon(
                            isDark
                                ? Icons.dark_mode_rounded
                                : Icons.light_mode_rounded,
                            color: c.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Қараңғы режим (Dark Mode)',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: c.primary,
                              ),
                            ),
                          ),
                          Switch(value: isDark, onChanged: _toggleTheme),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _SectionCard(
                  title: 'Профиль',
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _nameController,
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _saveName(),
                          cursorColor: c.primary,
                          style: TextStyle(fontSize: 14, color: c.primary),
                          decoration:
                              _inputDecoration(c, 'Пайдаланушы аты'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saveName,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: c.primary,
                            foregroundColor: c.surface,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Сақтау'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                _SectionCard(
                  title: 'Жазбалар ($doneCount / ${_notes.length})',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _noteController,
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addNote(),
                              cursorColor: c.primary,
                              style:
                                  TextStyle(fontSize: 14, color: c.primary),
                              decoration:
                                  _inputDecoration(c, 'Жаңа жазба...'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _addNote,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: c.primary,
                                foregroundColor: c.surface,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              child: const Text('Қосу'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (_notes.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: Center(
                            child: Text(
                              'Әзірге жазбалар жоқ. Біріншісін қосыңыз.',
                              style: TextStyle(fontSize: 13, color: c.muted),
                            ),
                          ),
                        )
                      else
                        for (final note in _notes)
                          _NoteTile(
                            key: ValueKey(note.id),
                            note: note,
                            onToggle: () => _toggleNote(note.id),
                            onDelete: () => _deleteNote(note.id),
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

InputDecoration _inputDecoration(AppColors c, String hint) {
  OutlineInputBorder outline(Color color, double width) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: color, width: width),
      );

  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: c.muted, fontSize: 14),
    filled: true,
    fillColor: c.background,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: outline(c.border, 1),
    enabledBorder: outline(c.border, 1),
    focusedBorder: outline(c.primary, 1.2),
  );
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;

  const _SectionCard({this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: c.primary,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _NoteTile extends StatelessWidget {
  final NoteItem note;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _NoteTile({
    super.key,
    required this.note,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.border),
      ),
      child: Row(
        children: [
          Checkbox(
            value: note.isCompleted,
            activeColor: c.primary,
            checkColor: c.surface,
            onChanged: (_) => onToggle(),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  note.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: note.isCompleted ? c.muted : c.primary,
                    decoration: note.isCompleted
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note.dateText,
                  style: TextStyle(fontSize: 11, color: c.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Жою',
            icon: Icon(Icons.delete_outline_rounded, color: c.muted, size: 22),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}