import 'dart:io';

import 'package:image_picker/image_picker.dart';

Future<File?> imagePicker() async {
  try {
    final picker = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picker != null) {
      return File(picker.path);
    }
    return null;
  } catch (er) {
    return null;
  }
}
