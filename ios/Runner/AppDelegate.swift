import AVFoundation
import CallKit
import Flutter
import flutter_callkit_incoming
import Photos
import PushKit
import UIKit

/// RT-013: CallKit decline/timeout while Flutter is not listening.
private enum CallKitKilledSignaling {
  static let pendingKey = "flutter.lgbtfinder_callkit_pending_actions"
  static let tokenKey = "flutter.lgbtfinder_bg_auth_token"
  static let originKey = "flutter.lgbtfinder_bg_api_origin"

  static func enqueueAndPost(kind: String, call: Call) {
    guard let callId = serverCallId(call) else { return }
    var actions = readPending()
    if let index = actions.firstIndex(where: { $0["callId"] == callId }) {
      let current = actions[index]["kind"]
      if current == "decline" && kind == "timeout" {
        // A decline already queued for this call wins.
      } else {
        actions[index] = ["callId": callId, "kind": kind]
      }
    } else {
      actions.append(["callId": callId, "kind": kind])
    }
    writePending(actions)
    postAll()
  }

  private static func serverCallId(_ call: Call) -> String? {
    let uuid = call.data.uuid.trimmingCharacters(in: .whitespacesAndNewlines)
    if Int(uuid) != nil { return uuid }
    let extra = call.data.extra
    let raw = (extra["call_id"] ?? extra["callId"]) as? String
    let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return Int(trimmed) != nil ? trimmed : nil
  }

  private static func readPending() -> [[String: String]] {
    guard let raw = UserDefaults.standard.string(forKey: pendingKey),
          let data = raw.data(using: .utf8),
          let decoded = try? JSONSerialization.jsonObject(with: data) as? [Any]
    else {
      return []
    }
    var actions: [[String: String]] = []
    for item in decoded {
      guard let row = item as? [String: Any] else { continue }
      let callId = (row["callId"] as? String) ?? ""
      let kind = (row["kind"] as? String) ?? ""
      if callId.isEmpty || kind.isEmpty { continue }
      actions.append(["callId": callId, "kind": kind])
    }
    return actions
  }

  private static func writePending(_ actions: [[String: String]]) {
    if actions.isEmpty {
      UserDefaults.standard.removeObject(forKey: pendingKey)
      return
    }
    guard let data = try? JSONSerialization.data(withJSONObject: actions),
          let raw = String(data: data, encoding: .utf8)
    else {
      return
    }
    UserDefaults.standard.set(raw, forKey: pendingKey)
  }

  private static func postAll() {
    let defaults = UserDefaults.standard
    let token = defaults.string(forKey: tokenKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    var origin = defaults.string(forKey: originKey)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    while origin.hasSuffix("/") { origin.removeLast() }
    guard !token.isEmpty, !origin.isEmpty, let _ = URL(string: origin) else { return }
    let snapshot = readPending()
    guard !snapshot.isEmpty else { return }
    let task = UIApplication.shared.beginBackgroundTask(withName: "callkit-terminal") {}
    let group = DispatchGroup()
    let lock = NSLock()
    var remaining = snapshot
    for action in snapshot {
      guard let callId = action["callId"], let kind = action["kind"] else { continue }
      let path: String
      let reason: String
      if kind == "decline" {
        path = "/api/calls/\(callId)/reject"
        reason = "User rejected the call"
      } else if kind == "timeout" {
        path = "/api/calls/\(callId)/end"
        reason = "CallKit timeout"
      } else {
        continue
      }
      guard let url = URL(string: origin + path) else { continue }
      var request = URLRequest(url: url)
      request.httpMethod = "POST"
      request.timeoutInterval = 12
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
      request.setValue("application/json", forHTTPHeaderField: "Accept")
      request.setValue("application/json", forHTTPHeaderField: "Content-Type")
      request.httpBody = try? JSONSerialization.data(withJSONObject: ["reason": reason])
      group.enter()
      URLSession.shared.dataTask(with: request) { _, response, _ in
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        if shouldDrop(status) {
          lock.lock()
          remaining.removeAll { $0["callId"] == callId && $0["kind"] == kind }
          lock.unlock()
        }
        group.leave()
      }.resume()
    }
    group.notify(queue: .main) {
      lock.lock()
      writePending(remaining)
      lock.unlock()
      UIApplication.shared.endBackgroundTask(task)
    }
  }

  private static func shouldDrop(_ status: Int) -> Bool {
    if (200..<300).contains(status) { return true }
    return status == 400 || status == 403 || status == 404 || status == 409 || status == 422
  }
}

@main
@objc class AppDelegate: FlutterAppDelegate, PKPushRegistryDelegate, CallkitIncomingAppDelegate {
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

  public func onAccept(_ call: Call, _ action: CXAnswerCallAction) {
    action.fulfill()
  }

  public func onDecline(_ call: Call, _ action: CXEndCallAction) {
    CallKitKilledSignaling.enqueueAndPost(kind: "decline", call: call)
    action.fulfill()
  }

  public func onEnd(_ call: Call, _ action: CXEndCallAction) {
    action.fulfill()
  }

  public func onTimeOut(_ call: Call) {
    CallKitKilledSignaling.enqueueAndPost(kind: "timeout", call: call)
  }

  public func didActivateAudioSession(_ audioSession: AVAudioSession) {}

  public func didDeactivateAudioSession(_ audioSession: AVAudioSession) {}
}
