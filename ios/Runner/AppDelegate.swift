import Flutter
import Photos
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var screenshotChannel: FlutterMethodChannel?
  private var screenshotObserver: NSObjectProtocol?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let galleryChannel = FlutterMethodChannel(
        name: "com.lgbtfinder/gallery_save",
        binaryMessenger: controller.binaryMessenger
      )
      galleryChannel.setMethodCallHandler { call, result in
        guard call.method == "saveImage" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String,
              let image = UIImage(contentsOfFile: path) else {
          result(FlutterError(code: "BAD_PATH", message: "Missing image path", details: nil))
          return
        }
        let finish: (Bool, Error?) -> Void = { success, error in
          DispatchQueue.main.async {
            if let error = error {
              result(
                FlutterError(
                  code: "SAVE_FAILED",
                  message: error.localizedDescription,
                  details: nil
                )
              )
            } else {
              result(success)
            }
          }
        }
        if #available(iOS 14, *) {
          PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
            guard status == .authorized || status == .limited else {
              DispatchQueue.main.async {
                result(FlutterError(code: "DENIED", message: "Photo access denied", details: nil))
              }
              return
            }
            PHPhotoLibrary.shared().performChanges({
              PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: finish)
          }
        } else {
          PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else {
              DispatchQueue.main.async {
                result(FlutterError(code: "DENIED", message: "Photo access denied", details: nil))
              }
              return
            }
            PHPhotoLibrary.shared().performChanges({
              PHAssetChangeRequest.creationRequestForAsset(from: image)
            }, completionHandler: finish)
          }
        }
      }

      let shotChannel = FlutterMethodChannel(
        name: "com.lgbtfinder/screenshot_protection",
        binaryMessenger: controller.binaryMessenger
      )
      screenshotChannel = shotChannel
      shotChannel.setMethodCallHandler { [weak self] call, result in
        switch call.method {
        case "enable":
          self?.startScreenshotObserver()
          result(nil)
        case "disable":
          self?.stopScreenshotObserver()
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
    return launched
  }

  private func startScreenshotObserver() {
    stopScreenshotObserver()
    screenshotObserver = NotificationCenter.default.addObserver(
      forName: UIApplication.userDidTakeScreenshotNotification,
      object: nil,
      queue: .main
    ) { [weak self] _ in
      self?.screenshotChannel?.invokeMethod("screenshotTaken", arguments: nil)
    }
  }

  private func stopScreenshotObserver() {
    if let observer = screenshotObserver {
      NotificationCenter.default.removeObserver(observer)
      screenshotObserver = nil
    }
  }
}
