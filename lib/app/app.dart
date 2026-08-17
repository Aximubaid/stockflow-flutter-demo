import 'package:flutter/material.dart';

import '../features/app_shell.dart';
import 'theme.dart';

class StockFlowApp extends StatelessWidget {
  const StockFlowApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StockFlow',
    debugShowCheckedModeBanner: false,
    theme: StockFlowTheme.light,
    home: const AppShell(),
  );
}
