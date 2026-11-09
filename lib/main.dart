import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _lockPhonesToPortrait();
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(
    ProviderScope(
      // Providers don't retry on their own. Screens offer explicit retries.
      retry: (retryCount, error) => null,
      child: const GarageApp(),
    ),
  );
}

/// Phones are portrait only. Tablets (shortest side 600 pt or more) keep
/// both orientations (UI/UX spec 2.4). iOS also declares this per device
/// family in Info.plist.
Future<void> _lockPhonesToPortrait() async {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return;
  final view = views.first;
  final logicalSize = view.physicalSize / view.devicePixelRatio;
  if (logicalSize.shortestSide < 600) {
    await SystemChrome.setPreferredOrientations(const [DeviceOrientation.portraitUp]);
  }
}
