import UIKit

class WindowSceneCoordinator: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else { return }

        window = UIWindow(windowScene: windowScene)
        let rootVC = ImageUploadController()
        let navController = UINavigationController(rootViewController: rootVC)
        navController.tabBarItem = UITabBarItem(title: "Upload", image: UIImage(systemName: "photo"), selectedImage: UIImage(systemName: "photo.fill"))

        let tabController = UITabBarController()
        tabController.viewControllers = [navController]

        window?.rootViewController = tabController
        window?.makeKeyAndVisible()
    }
}
