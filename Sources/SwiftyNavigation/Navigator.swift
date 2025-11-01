import Combine
import UIKit

public protocol NavigatorDelegate {
    func navigator(_ navigator: Navigator, shouldDispatch path: Path) -> Bool
    func navigator(_ navigator: Navigator, willDispatch path: Path)
    func navigator(_ navigator: Navigator, didDispatch path: Path)
    func navigator(_ navigator: Navigator, failedToDispatch path: String)
}

public actor Navigator {
    private let navController: UINavigationController
    public var delegate: (any NavigatorDelegate)?
    private var paths = Set<Path>()

    var topViewController: UIViewController? { get async { await navController.topViewController } }
    var stack: [UIViewController] { get async { await navController.viewControllers } }

    init(navController: UINavigationController) { self.navController = navController }

    public func register(path: Path) { paths.insert(path) }

    public func dissmiss(animated: Bool = true) async {
        await MainActor.run {
            guard navController.presentedViewController != nil else { return }
            navController.dismiss(animated: animated)
        }
    }

    public func dispatch(for path: String) async {
        guard let foundPath = paths.first(where: { $0.path == path.pathWithOutParameters() }) else {
            delegate?.navigator(self, failedToDispatch: path)
            return
        }
        guard delegate?.navigator(self, shouldDispatch: foundPath) ?? true else { return }
        guard foundPath.preconditions.map({ $0.shouldRoute(path) }).allSatisfy({$0}) else { return }
        delegate?.navigator(self, willDispatch: foundPath)
        let vc = await foundPath.action(path.getParameters())
        await MainActor.run { self.navController.pushViewController(vc, animated: foundPath.animated) }
        delegate?.navigator(self, didDispatch: foundPath)
    }
}

// MARK: Main actor functions

@MainActor
extension Navigator {
    public static let shared = Navigator(navController: UINavigationController())

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
}
