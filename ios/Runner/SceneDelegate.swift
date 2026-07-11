import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  override func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    let contexts = connectionOptions.urlContexts.sorted {
      $0.url.absoluteString < $1.url.absoluteString
    }
    for (index, context) in contexts.enumerated() {
      InboundKifuCoordinator.shared.receive(
        url: context.url,
        initial: index == 0
      )
    }
    super.scene(
      scene,
      willConnectTo: session,
      options: connectionOptions
    )
  }

  override func scene(
    _ scene: UIScene,
    openURLContexts URLContexts: Set<UIOpenURLContext>
  ) {
    var hasUnhandledURL = false
    for context in URLContexts {
      if !InboundKifuCoordinator.shared.receive(url: context.url, initial: false) {
        hasUnhandledURL = true
      }
    }
    if hasUnhandledURL {
      super.scene(scene, openURLContexts: URLContexts)
    }
  }
}
