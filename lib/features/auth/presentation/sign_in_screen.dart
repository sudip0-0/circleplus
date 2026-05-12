import 'package:flutter/material.dart';

import '../../../shared/widgets/empty_state.dart';

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: EmptyState(
          title: 'CirclePulse',
          message: 'Private Circles, daily Pulses, and simple Plans.',
        ),
      ),
    );
  }
}
