import 'package:flutter/material.dart';

import '../error/app_failure.dart';

void showAppSnack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

void showFailureSnack(BuildContext context, AppFailure failure) {
  showAppSnack(context, failure.uiMessage);
}
