import Combine
import UIKit

public actor Navigator<T: RawRepresentable & Sendable> where T.RawValue == String {
    private let navController: UINavigationController
    private var paths = Set<NavigatorPath<T>>()

    public var topViewController: UIViewController? { get async { await navController.topViewController } }
    public var stack: [UIViewController] { get async { await navController.viewControllers } }

    init(navController: UINavigationController) { self.navController = navController }

    public func register(path: NavigatorPath<T>) { paths.insert(path) }

    public func dissmiss(animated: Bool = true) async {
        await MainActor.run {
            guard navController.presentedViewController != nil else { return }
            navController.dismiss(animated: animated)
        }
    }

    public func dispatch(for path: String) async {
        guard let foundNavigatorPath = paths.first(where: { $0.path.rawValue == path.pathWithOutParameters() }) else {
            return
        }
        guard foundNavigatorPath.preconditions.map({ $0.shouldRoute(path) }).allSatisfy({$0}) else { return }
        let vc = await foundNavigatorPath.action(path.getParameters())
        await MainActor.run { self.navController.pushViewController(vc, animated: foundNavigatorPath.animated) }
    }
}

// MARK: Main actor functions

@MainActor
extension Navigator {

    public func makeKeyAndVisible(window: inout UIWindow) {
        window.rootViewController = navController
        window.makeKeyAndVisible()
    }

    public func present(vc: UIViewController, animated: Bool = true,
                        detents: [UISheetPresentationController.Detent] = [.large()],
                        completion: @escaping @Sendable () -> Void = {}) {
        if let sheet = vc.sheetPresentationController {
            sheet.detents = detents
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        navController.present(vc, animated: animated, completion: completion)
    }

    public func setNavBarImage(_ image: UIImage? = nil) {
        let imageView = UIImageView(image: image)
        navController.navigationItem.titleView = imageView
    }

    public func hideNavBar(_ hide: Bool) {
        navController.navigationBar.isHidden = true
    }
}
