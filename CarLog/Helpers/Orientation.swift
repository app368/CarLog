import SwiftUI
import UIKit

// Задача: приложение работает в портретной ориентации, а экраны графиков — в альбомной.
// Делегат сообщает системе, какие ориентации разрешены прямо сейчас
final class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock: UIInterfaceOrientationMask = .portrait

    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        AppDelegate.orientationLock
    }
}

// Задача: переключить разрешённую ориентацию и повернуть экран
enum Orientation {
    static func lock(_ mask: UIInterfaceOrientationMask) {
        AppDelegate.orientationLock = mask
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
        scene.requestGeometryUpdate(.iOS(interfaceOrientations: mask))
    }
}

extension View {
    // Задача: экран показывается в альбомной ориентации, при уходе с него — снова портретная
    func landscapeOnly() -> some View {
        onAppear { Orientation.lock(.landscape) }
            .onDisappear { Orientation.lock(.portrait) }
    }
}
