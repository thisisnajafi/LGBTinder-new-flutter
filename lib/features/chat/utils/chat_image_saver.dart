import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/cache/image_cache_service.dart';
import '../../../core/services/app_logger.dart';
import 'chat_local_media.dart';

class ChatImageSaveResult {
  final bool saved;
  final bool denied;

  const ChatImageSaveResult({
    required this.saved,
    this.denied = false,
  });
}

typedef ChatImageSaveHandler = Future<ChatImageSaveResult> Function(String url);

/// Downloads (if needed) and writes a chat photo to the device gallery.
class ChatImageGallerySaver {
  ChatImageGallerySaver._();

  static const MethodChannel _channel =
      MethodChannel('com.lgbtfinder/gallery_save');

  static Future<ChatImageSaveResult> save(String url) async {
    try {
      final denied = await _ensurePermission();
      if (denied) {
        return const ChatImageSaveResult(saved: false, denied: true);
      }

      final path = ChatLocalMedia.isLocalPath(url)
          ? ChatLocalMedia.toFilePath(url)
          : (await LgbtfinderImageCacheManager().getSingleFile(url)).path;

      final ok = await _channel.invokeMethod<bool>('saveImage', {'path': path});
      return ChatImageSaveResult(saved: ok == true);
    } on MissingPluginException catch (e) {
      AppLogger.warning(
        'Gallery save plugin missing',
        tag: 'Chat',
        error: e,
      );
      return const ChatImageSaveResult(saved: false);
    } on PlatformException catch (e) {
      if (e.code == 'DENIED') {
        return const ChatImageSaveResult(saved: false, denied: true);
      }
      AppLogger.warning('Save chat image failed', tag: 'Chat', error: e);
      return const ChatImageSaveResult(saved: false);
    } catch (e) {
      AppLogger.warning('Save chat image failed', tag: 'Chat', error: e);
      return const ChatImageSaveResult(saved: false);
    }
  }

  static Future<bool> _ensurePermission() async {
    if (Platform.isAndroid) {
      final sdk = (await DeviceInfoPlugin().androidInfo).version.sdkInt;
      if (sdk > 29) return false;
      var status = await Permission.storage.status;
      if (status.isDenied) {
        status = await Permission.storage.request();
      }
      return status.isDenied || status.isPermanentlyDenied;
    }

    return false;
  }
}
