import 'dart:async';
import 'package:flutter/material.dart';

void main() {
  runApp(const ProfileApp());
}

class ProfileApp extends StatelessWidget {
  const ProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Profile Card',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProfileScreen(),
    );
  }
}

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Исходные данные
  static const int _initialLikes = 120;
  static const bool _initialIsFollowing = false;
  static const bool _initialIsLiked = false;

  int _likesCount = _initialLikes;
  bool _isFollowing = _initialIsFollowing;
  bool _isLiked = _initialIsLiked;

  bool _isProcessingLike = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _toggleFollow() {
    if (!mounted) return;
    setState(() {
      _isFollowing = !_isFollowing;
    });
  }
  void _toggleLike() {
    if (_isProcessingLike || !mounted) return;

    setState(() {
      _isProcessingLike = true;
      _isLiked = !_isLiked;
      if (_isLiked) {
        _likesCount++;
      } else {
        _likesCount--;
      }
    });

    // Безопасный таймер для предотвращения спама
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() {
          _isProcessingLike = false;
        });
      }
    });
  }
  void _resetState() {
    _debounceTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _likesCount = _initialLikes;
      _isFollowing = _initialIsFollowing;
      _isLiked = _initialIsLiked;
      _isProcessingLike = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile Card'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset',
            onPressed: _resetState,
          ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 4,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://i.ibb.co.com/hJFkGxtD/B7-FF2738-6072-48-E1-A82-C-F500-D5045-E45.png', // Вставьте ссылку на ваше фото
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Имя и информация
                  const Text(
                    'Daniyal Bazarbek',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Flutter Developer | Tech Enthusiast',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: Icon(
                          _isLiked ? Icons.favorite : Icons.favorite_border,
                          color: _isLiked ? Colors.red : Colors.grey,
                          size: 30,
                        ),
                        onPressed: _isProcessingLike ? null : _toggleLike,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_likesCount Likes',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            _isFollowing ? Colors.grey[300] : Colors.deepPurple,
                        foregroundColor:
                            _isFollowing ? Colors.black87 : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        _isFollowing ? 'Following' : 'Follow',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Кнопка Reset
                  TextButton.icon(
                    onPressed: _resetState,
                    icon: const Icon(Icons.restore, size: 18),
                    label: const Text('Reset Profile State'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}