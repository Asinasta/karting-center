import 'package:flutter/material.dart';

import 'app/apex_app.dart';
import 'app/app_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  ErrorWidget.builder = (details) {
    return Material(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Ошибка интерфейса:\n${details.exception}',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
        ),
      ),
    );
  };
  runApp(ApexApp(dependencies: AppDependencies.create()));
}
