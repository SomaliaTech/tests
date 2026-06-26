import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class ToastHelper {
  static void showSuccess(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('Success'),
      description: Text(message),
      type: ToastificationType.success,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }

  static void showError(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('Error'),
      description: Text(message),
      type: ToastificationType.error,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 4),
      alignment: Alignment.topRight,
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }

  static void showInfo(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('Info'),
      description: Text(message),
      type: ToastificationType.info,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }

  static void showWarning(BuildContext context, String message) {
    toastification.show(
      context: context,
      title: const Text('Warning'),
      description: Text(message),
      type: ToastificationType.warning,
      style: ToastificationStyle.fillColored,
      autoCloseDuration: const Duration(seconds: 3),
      alignment: Alignment.topRight,
      borderRadius: BorderRadius.circular(12),
      boxShadow: highModeShadow,
    );
  }
}
