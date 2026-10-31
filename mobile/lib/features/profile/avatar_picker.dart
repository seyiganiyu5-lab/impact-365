import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/repository.dart';
import '../../widgets/common.dart';

/// A problem we can explain to the member in their language.
class AvatarPickError implements Exception {
  AvatarPickError(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Image type from the picker, or from the file name as a fallback.
String? avatarContentType(String? mimeType, String fileName) {
  final m = (mimeType ?? '').toLowerCase();
  if (m == 'image/jpeg' || m == 'image/png' || m == 'image/webp') return m;
  final name = fileName.toLowerCase();
  if (name.endsWith('.jpg') || name.endsWith('.jpeg')) return 'image/jpeg';
  if (name.endsWith('.png')) return 'image/png';
  if (name.endsWith('.webp')) return 'image/webp';
  return null;
}

/// Opens the camera or gallery, then uploads the (resized) photo.
/// Returns the new URL, or null when the member cancelled.
Future<String?> pickAndUploadAvatar(
  BuildContext context, {
  required bool camera,
}) async {
  final l = context.l10n;
  final XFile? file;
  try {
    file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      preferredCameraDevice: CameraDevice.front,
      // Small square-ish photo: quick to upload, sharp in the app.
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 85,
      requestFullMetadata: false,
    );
  } on PlatformException catch (e) {
    if (e.code.contains('access_denied')) {
      throw AvatarPickError(l.photoPermission);
    }
    rethrow;
  }
  if (file == null) return null;

  final type = avatarContentType(file.mimeType, file.name);
  if (type == null) throw AvatarPickError(l.photoUnsupported);
  final bytes = await file.readAsBytes();
  if (bytes.length > Repo.avatarMaxBytes) {
    throw AvatarPickError(l.photoTooBig);
  }
  return Repo.uploadAvatar(bytes, contentType: type);
}
