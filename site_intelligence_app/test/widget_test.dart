import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:site_intelligence_app/main.dart';
import 'package:site_intelligence_app/providers/app_state_provider.dart';
import 'package:site_intelligence_app/providers/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppStateProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const SiteIntelligenceApp(),
      ),
    );
    expect(find.byType(SiteIntelligenceApp), findsOneWidget);
  });
}