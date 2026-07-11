import Flutter
import UIKit

final class InboundKifuCoordinator: NSObject, FlutterStreamHandler {
  static let shared = InboundKifuCoordinator()

  private static let methodChannelName =
    "com.wimi321.lizzieyzy.mobile/inbound_kifu/methods"
  private static let eventChannelName =
    "com.wimi321.lizzieyzy.mobile/inbound_kifu/events"
  private static let maximumInputBytes = 16 * 1024 * 1024
  private static let maximumFileNameCharacters = 255
  private static let maximumPendingRuntimeEvents = 8
  private static let maximumPendingReads = 6
  private static let readTimeout: TimeInterval = 10
  private static let nativeReadError = "unreadable"

  private struct Descriptor {
    let url: URL
    let name: String
  }

  private struct Payload {
    let name: String?
    let data: Data?
    let action: String?
    let error: String?

    static func success(name: String, data: Data, action: String) -> Payload {
      Payload(name: name, data: data, action: action, error: nil)
    }

    static let failure = Payload(
      name: nil,
      data: nil,
      action: nil,
      error: InboundKifuCoordinator.nativeReadError
    )

    var byteCount: Int { data?.count ?? 0 }

    var channelValue: [String: Any] {
      if let error { return ["error": error] }
      guard let name, let data, let action else {
        return ["error": InboundKifuCoordinator.nativeReadError]
      }
      return [
        "name": name,
        "bytes": FlutterStandardTypedData(bytes: data),
        "action": action,
      ]
    }
  }

  private final class ReadCancellation {
    private let lock = NSLock()
    private var cancelled = false
    private var handle: FileHandle?

    func attach(_ candidate: FileHandle) -> Bool {
      lock.lock()
      defer { lock.unlock() }
      guard !cancelled else {
        try? candidate.close()
        return false
      }
      handle = candidate
      return true
    }

    func detach(_ candidate: FileHandle) {
      lock.lock()
      if handle === candidate { handle = nil }
      lock.unlock()
    }

    var isCancelled: Bool {
      lock.lock()
      defer { lock.unlock() }
      return cancelled
    }

    func cancel() {
      lock.lock()
      guard !cancelled else {
        lock.unlock()
        return
      }
      cancelled = true
      let activeHandle = handle
      handle = nil
      lock.unlock()
      try? activeHandle?.close()
    }
  }

  private let ioQueue = DispatchQueue(
    label: "com.wimi321.lizzieyzy.mobile.inbound-kifu",
    qos: .userInitiated,
    attributes: .concurrent
  )
  private let stateQueue = DispatchQueue(
    label: "com.wimi321.lizzieyzy.mobile.inbound-kifu-state"
  )
  private var initialScheduled = false
  private var initialTakeCalled = false
  private var initialPayload: Payload?
  private var pendingReads: [UUID: ReadCancellation] = [:]
  private var pendingRuntime: [Payload] = []
  private var pendingRuntimeBytes = 0
  private var eventSink: FlutterEventSink?
  private var methodChannel: FlutterMethodChannel?
  private var eventChannel: FlutterEventChannel?

  private override init() {
    super.init()
  }

  func attach(to messenger: FlutterBinaryMessenger) {
    precondition(Thread.isMainThread)
    methodChannel?.setMethodCallHandler(nil)
    eventChannel?.setStreamHandler(nil)
    eventSink = nil

    let methods = FlutterMethodChannel(
      name: Self.methodChannelName,
      binaryMessenger: messenger
    )
    methods.setMethodCallHandler { [weak self] call, result in
      guard call.method == "takeInitialKifu" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.takeInitial(result: result)
    }
    let events = FlutterEventChannel(
      name: Self.eventChannelName,
      binaryMessenger: messenger
    )
    events.setStreamHandler(self)
    methodChannel = methods
    eventChannel = events
  }

  @discardableResult
  func receive(url: URL, initial: Bool, action: String = "open") -> Bool {
    guard url.isFileURL else { return false }
    if initial {
      let claimed = stateQueue.sync {
        if !initialScheduled {
          initialScheduled = true
          return true
        }
        return false
      }
      // AppDelegate and SceneDelegate can report the same cold-start URL.
      guard claimed else { return true }
    }

    guard let descriptor = validatedDescriptor(url) else {
      resolve(Payload.failure, initial: initial)
      return true
    }
    scheduleRead(descriptor: descriptor, initial: initial, action: action)
    return true
  }

  func onListen(
    withArguments arguments: Any?,
    eventSink events: @escaping FlutterEventSink
  ) -> FlutterError? {
    eventSink = events
    for payload in pendingRuntime {
      events(payload.channelValue)
    }
    pendingRuntime.removeAll(keepingCapacity: false)
    pendingRuntimeBytes = 0
    return nil
  }

  func onCancel(withArguments arguments: Any?) -> FlutterError? {
    eventSink = nil
    return nil
  }

  private func takeInitial(result: @escaping FlutterResult) {
    stateQueue.async { [weak self] in
      self?.initialTakeCalled = true
      let payload = self?.initialPayload
      self?.initialPayload = nil
      DispatchQueue.main.async { result(payload?.channelValue) }
    }
  }

  private func scheduleRead(
    descriptor: Descriptor,
    initial: Bool,
    action: String
  ) {
    let identifier = UUID()
    let cancellation = ReadCancellation()
    let accepted = stateQueue.sync {
      guard pendingReads.count < Self.maximumPendingReads else { return false }
      pendingReads[identifier] = cancellation
      return true
    }
    guard accepted else {
      resolve(Payload.failure, initial: initial)
      return
    }

    ioQueue.async { [weak self] in
      guard let self else { return }
      let payload: Payload
      if let data = self.readBounded(descriptor.url, cancellation: cancellation),
         !data.isEmpty
      {
        payload = .success(name: descriptor.name, data: data, action: action)
      } else {
        payload = .failure
      }
      self.completeRead(identifier, payload: payload, initial: initial)
    }
    stateQueue.asyncAfter(deadline: .now() + Self.readTimeout) { [weak self] in
      guard let self,
            let cancellation = self.pendingReads.removeValue(forKey: identifier)
      else { return }
      cancellation.cancel()
      self.resolveLocked(.failure, initial: initial)
    }
  }

  private func completeRead(
    _ identifier: UUID,
    payload: Payload,
    initial: Bool
  ) {
    stateQueue.async { [weak self] in
      guard let self,
            self.pendingReads.removeValue(forKey: identifier) != nil
      else { return }
      self.resolveLocked(payload, initial: initial)
    }
  }

  private func resolve(_ payload: Payload, initial: Bool) {
    stateQueue.async { [weak self] in
      self?.resolveLocked(payload, initial: initial)
    }
  }

  private func resolveLocked(_ payload: Payload, initial: Bool) {
    dispatchPrecondition(condition: .onQueue(stateQueue))
    if initial && !initialTakeCalled {
      initialPayload = payload
      return
    }
    DispatchQueue.main.async { [weak self] in self?.deliverRuntime(payload) }
  }

  private func deliverRuntime(_ payload: Payload) {
    precondition(Thread.isMainThread)
    if let eventSink {
      eventSink(payload.channelValue)
      return
    }
    while !pendingRuntime.isEmpty &&
      (pendingRuntime.count >= Self.maximumPendingRuntimeEvents ||
        pendingRuntimeBytes + payload.byteCount > Self.maximumInputBytes)
    {
      pendingRuntimeBytes -= pendingRuntime.removeFirst().byteCount
    }
    guard payload.byteCount <= Self.maximumInputBytes else { return }
    pendingRuntime.append(payload)
    pendingRuntimeBytes += payload.byteCount
  }

  private func validatedDescriptor(_ url: URL) -> Descriptor? {
    guard url.isFileURL else { return nil }
    let name = url.lastPathComponent
    guard !name.isEmpty,
          name.utf16.count <= Self.maximumFileNameCharacters,
          name != ".",
          name != "..",
          !name.contains("/"),
          !name.contains("\\"),
          !name.unicodeScalars.contains(where: { $0.value < 0x20 })
    else { return nil }
    let extensionName = (name as NSString).pathExtension.lowercased()
    guard extensionName == "sgf" || extensionName == "gib" else { return nil }
    // Keep the original URL instance: security-scoped access is granted for
    // the URL delivered by UIKit and must be started on that same resource.
    return Descriptor(url: url, name: name)
  }

  private func readBounded(
    _ url: URL,
    cancellation: ReadCancellation
  ) -> Data? {
    let didAccess = url.startAccessingSecurityScopedResource()
    defer {
      if didAccess { url.stopAccessingSecurityScopedResource() }
    }
    do {
      let values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
      guard values.isRegularFile != false else { return nil }
      if let size = values.fileSize,
         (size <= 0 || size > Self.maximumInputBytes)
      {
        return nil
      }
      let handle = try FileHandle(forReadingFrom: url)
      guard cancellation.attach(handle) else { return nil }
      defer { try? handle.close() }
      defer { cancellation.detach(handle) }
      var output = Data()
      if let size = values.fileSize { output.reserveCapacity(size) }
      while true {
        if cancellation.isCancelled { return nil }
        let chunk = try handle.read(upToCount: 8192) ?? Data()
        if chunk.isEmpty { break }
        guard output.count <= Self.maximumInputBytes - chunk.count else {
          return nil
        }
        output.append(chunk)
      }
      return output
    } catch {
      return nil
    }
  }

}

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let url = launchOptions?[.url] as? URL {
      InboundKifuCoordinator.shared.receive(url: url, initial: true)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    if InboundKifuCoordinator.shared.receive(url: url, initial: false) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    InboundKifuCoordinator.shared.attach(
      to: engineBridge.applicationRegistrar.messenger()
    )
  }
}
