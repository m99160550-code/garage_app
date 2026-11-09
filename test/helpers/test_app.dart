import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:tdc_garage/app.dart';
import 'package:tdc_garage/features/launch/presentation/launch_screen.dart';
import 'package:tdc_garage/features/session/application/session_providers.dart';
import 'package:tdc_garage/features/session/data/session_repository.dart';

/// The full app with a test session repository (no retries, like main.dart).
Widget buildTestApp(SessionRepository repository, {List<Override> overrides = const []}) => ProviderScope(
  retry: (retryCount, error) => null,
  overrides: [sessionRepositoryProvider.overrideWithValue(repository), ...overrides],
  child: const GarageApp(),
);

/// Lets the launch screen's minimum display time pass and settle.
Future<void> finishLaunch(WidgetTester tester) async {
  await tester.pump(LaunchScreen.minimumDisplay);
  await tester.pumpAndSettle();
}

/// Runs a test on an iPhone-sized screen (390 × 844 pt).
void usePhoneScreen(WidgetTester tester) => useScreen(tester, const Size(390, 844));

/// Runs a test on an iPad in landscape (1024 × 768 pt).
void useTabletScreen(WidgetTester tester) => useScreen(tester, const Size(1024, 768));

void useScreen(WidgetTester tester, Size logicalSize) {
  tester.view.physicalSize = logicalSize * 2;
  tester.view.devicePixelRatio = 2;
  addTearDown(tester.view.reset);
}
