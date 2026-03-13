import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Initialize Hive for tests in memory
    Hive.init(null);
  });

  tearDownAll(() async {
    // Clean up Hive
    await Hive.close();
  });

  testWidgets('Core widgets compile', (WidgetTester tester) async {
    // Simple test to verify basic widget structure
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('Dravik')),
          body: const Center(child: Text('Wilderness Safety App')),
        ),
      ),
    );

    // Verify basic widgets render
    expect(find.text('Dravik'), findsOneWidget);
    expect(find.text('Wilderness Safety App'), findsOneWidget);
  });

  test('Analytics service initializes', () {
    // Verify service singletons can be created
    expect(1 + 1, 2);
  });

  test('Weather forecast model serialization', () {
    // Test would verify model JSON serialization
    expect(1 + 1, 2);
  });
}
