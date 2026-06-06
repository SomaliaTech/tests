import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

void showSnackbar(BuildContext context, String content, String type) {
  toastification.show(
    context: context,
    type: type == "Success"
        ? ToastificationType.success
        : type == "Warning"
        ? ToastificationType.warning
        : type == "Error"
        ? ToastificationType.error
        : null,
    style: ToastificationStyle.fillColored,
    title: Text(type),
    description: Text(content),
    autoCloseDuration: const Duration(seconds: 3),
  );
}
