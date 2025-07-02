//
//  WindowSceneCoordinator.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//

import UIKit
import SwiftUI

class WindowSceneCoordinator: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        AppTheme.apply()
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)

        // Swap from HomeViewController to SwiftUI root
        let rootVC = UIHostingController(rootView: MainHomeView())

        window?.rootViewController = rootVC
        window?.makeKeyAndVisible()
    }
}
