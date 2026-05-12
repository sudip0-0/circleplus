import 'package:flutter/material.dart';

import 'routing/app_router.dart';
import 'theme/app_theme.dart';

class CirclePulseApp extends StatelessWidget {
  const CirclePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CirclePulse',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: AppRouter.initialScreen,
    );
  }
}
