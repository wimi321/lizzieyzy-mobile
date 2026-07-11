import 'package:flutter/widgets.dart';
import 'package:lizzieyzy_mobile/app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const initialRoute = String.fromEnvironment(
    'LIZZIEYZY_INITIAL_ROUTE',
    defaultValue: AppRoutes.root,
  );
  runApp(const LizzieYzyApp(initialRoute: initialRoute));
}
