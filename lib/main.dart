import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'data/local_demo_repository.dart';
import 'features/store_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final repository = LocalDemoRepository();
  await repository.initialize();
  runApp(
    ChangeNotifierProvider(
      create: (_) => StoreController(repository)..load(),
      child: const StockFlowApp(),
    ),
  );
}
