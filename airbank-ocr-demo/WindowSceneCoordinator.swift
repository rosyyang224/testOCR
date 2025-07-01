//
//  WindowSceneCoordinator.swift
//  airbank-ocr-demo
//
//  Created by Rosemary Yang on 7/1/25.
//  Copyright © 2025 Marek Přidal. All rights reserved.
//


import UIKit

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
        let rootVC = HomeViewController()
        let navController = UINavigationController(rootViewController: rootVC)
        navController.tabBarItem = UITabBarItem(title: "Upload", image: UIImage(systemName: "photo"), selectedImage: UIImage(systemName: "photo.fill"))

        let tabController = UITabBarController()
        tabController.viewControllers = [navController]

        window?.rootViewController = tabController
        window?.makeKeyAndVisible()
    }

}
