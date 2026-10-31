import 'package:flutter/gestures.dart'; // Обязательный импорт для PointerDeviceKind
import 'package:flutter/material.dart';
import 'screens/catalog_screen.dart';

void main() {
  runApp(const MyApp());
}

// 1. Создаем кастомный класс поведения скролла для поддержки мыши и трекпада
class MyCustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
      };
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Catalog',
      // 2. Передаем наше поведение скролла в MaterialApp
      scrollBehavior: MyCustomScrollBehavior(),
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const CatalogScreen(),
    );
  }
}