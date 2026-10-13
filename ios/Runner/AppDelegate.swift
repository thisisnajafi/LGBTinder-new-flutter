import Flutter
import flutter_callkit_incoming
import Photos
import PushKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate {
  private var screenshotChannel: FlutterMethodChannel?
  private var screenshotObserver: NSObjectProtocol?
  private var voipRegistry: PKPushRegistry?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    // PushKit must be registered while the process starts so a killed app can
    // show CallKit. The registry is retained or iOS drops the delegate.
    let registry = PKPushRegistry(queue: DispatchQueue.main)
    registry.delegate = self
    registry.desiredPushTypes = [.voIP]
    voipRegistry = registry

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

  func pushRegistry(
    _ registry: PKPushRegistry,
    didUpdate credentials: PKPushCredentials,
    for type: PKPushType
  ) {
    guard type == .voIP else { return }
    let deviceToken = credentials.token.map { String(format: "%02x", $0) }.joined()
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP(deviceToken)
  }

  func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
    guard type == .voIP else { return }
    SwiftFlutterCallkitIncomingPlugin.sharedInstance?.setDevicePushTokenVoIP("")
  }

  func pushRegistry(
    _ registry: PKPushRegistry,
    didReceiveIncomingPushWith payload: PKPushPayload,
    for type: PKPushType,
    completion: @escaping () -> Void
  ) {
    guard type == .voIP else {
      completion()
      return
    }

    let body = payload.dictionaryPayload
    let rawId = body["id"] as? String ?? ""
    let id = UUID(uuidString: rawId)?.uuidString ?? UUID().uuidString
    let nameCaller = body["nameCaller"] as? String ?? "Incoming call"
    let handle = body["handle"] as? String ?? ""
    let isVideo = (body["isVideo"] as? Bool) ?? (body["isVideo"] as? NSNumber)?.boolValue ?? false
    let data = flutter_callkit_incoming.Data(
      id: id,
      nameCaller: nameCaller,
      handle: handle,
      type: isVideo ? 1 : 0
    )
    var extra: [String: Any] = [:]
    for (key, value) in body {
      if let key = key as? String {
        extra[key] = value
      }
    }
    data.extra = extra as NSDictionary

    guard let plugin = SwiftFlutterCallkitIncomingPlugin.sharedInstance else {
      completion()
      return
    }
    plugin.showCallkitIncoming(data, fromPushKit: true, completion: completion)
  }
}
