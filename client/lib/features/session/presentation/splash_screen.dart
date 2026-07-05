import 'package:flutter/material.dart';

import '../../../core/theme/apex_tokens.dart';
import '../session_controller.dart';
import '../session_state.dart';

/// Session check on startup (FL-03). Navigation away from the splash is
/// handled by the router redirect once the session state settles.
class SplashScreen extends StatefulWidget {
  const SplashScreen({
    required this.sessionController,
    super.key,
  });

  final SessionController sessionController;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.sessionController.state is CheckingSession) {
      widget.sessionController.checkSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(ApexSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sports_motorsports, size: 64),
              SizedBox(height: ApexSpacing.md),
              Text(
                'Апекс',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: ApexSpacing.sm),
              Text('Проверяем сессию'),
              SizedBox(height: ApexSpacing.lg),
              CircularProgressIndicator(),
            ],
          ),
        ),
      ),
    );
  }
}
