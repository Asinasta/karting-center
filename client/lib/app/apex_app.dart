import 'package:flutter/material.dart';

import '../core/theme/apex_theme.dart';
import 'app_router.dart';
import 'app_scope.dart';

class ApexApp extends StatefulWidget {
  const ApexApp({
    required this.dependencies,
    super.key,
  });

  final AppDependencies dependencies;

  @override
  State<ApexApp> createState() => _ApexAppState();
}

class _ApexAppState extends State<ApexApp> {
  late final _router = createAppRouter(widget.dependencies);

  @override
  void dispose() {
    widget.dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      child: MaterialApp.router(
        title: 'Апекс',
        theme: ApexTheme.light(),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
