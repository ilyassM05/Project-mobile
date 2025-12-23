import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:elearning_dapp/main.dart';

void main() {
  testWidgets('App loads and shows login screen', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that the login screen elements are present
    expect(find.text('E-Learning DApp'), findsOneWidget);
    expect(find.text('Decentralized Learning Platform'), findsOneWidget);
    expect(find.byType(TextFormField), findsWidgets);
  });
}
