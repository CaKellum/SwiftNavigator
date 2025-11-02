import Combine
import UIKit

/// An actor that manages navigation flows for a specific raw‑representable route type.
///
/// `Navigator` takes a `UINavigationController` and a collection of
/// `NavigatorPath` instances.  Each `NavigatorPath` describes a route
/// (its path string, any preconditions, and the factory that produces a
/// view controller).  The actor provides high‑level APIs to register
/// new paths, push view controllers, present modally, or pop to a
/// particular type on the stack.  All navigation work is performed on
/// the main actor, while the rest of the navigation logic may be
/// executed off‑screen thanks to the actor isolation.
///
/// ```swift
/// let nav = Navigator(navController: myNavController)
/// nav.register(path: .detail)
/// await nav.dispatch(for: "detail?id=42")
/// ```
///
/// The generic parameter `T` must be `RawRepresentable` with a `String`
/// raw value so that a path can be described with a simple string
/// literal.  `Sendable` requirements allow the actor to be safely
/// used across concurrency domains.
///
/// - Note: All public API methods are *async* so callers can `await`
///   navigation completions.  Some methods are explicitly marked
///   `@MainActor` because the UIKit APIs they call must run on the main
///   thread.  If you call them from a background context, the `await
///   MainActor.run` calls inside the implementation ensure that the
///   UI operations are performed safely on the main thread.
public actor Navigator<T: RawRepresentable & Sendable> where T.RawValue == String {
    private let navController: UINavigationController
    private var paths = Set<NavigatorPath<T>>()

    /// The view controller at the top of the navigation stack.
    public var topViewController: UIViewController? { get async { await navController.topViewController } }

    /// The current stack of view controllers managed by the navigation controller.
    public var stack: [UIViewController] {
        get async { await navController.viewControllers }
    }

    /// Creates a new navigator for the supplied `UINavigationController`.
    ///
    /// - Parameter navController: The navigation controller that the
    ///   navigator will manage.
    init(navController: UINavigationController) { self.navController = navController }

    /// Registers a new `NavigatorPath` so that it can be used for
    /// dispatching routes.
    ///
    /// Once a path is added, subsequent calls to `dispatch(for:)` can
    /// match against the path string and invoke its route factory.
    ///
    /// - Parameter path: The `NavigatorPath` describing a
    ///   routable destination.
    public func register(path: NavigatorPath<T>) { paths.insert(path) }

    /// Removes every instance of a specific `UIViewController` subclass from the navigation stack.
    ///
    /// The method is intentionally asynchronous because it schedules its mutation on
    /// `MainActor`.  In practice the operation is instantaneous, but callers should
    /// `await` it to preserve ordering relative to other `Navigator` actions.
    ///
    /// ```swift
    /// // Example: remove all `DetailViewController` objects from the stack.
    /// await navigator.removeViewTypeFromStack(DetailViewController.self)
    /// ```
    ///
    /// - Parameter viewControllerType: The concrete `UIViewController` subclass whose instances
    ///   should be purged from the stack.  The comparison is performed with
    ///   `isKind(of:)`, so it will also match subclasses of the supplied type.
    ///
    /// - Note: The method does **not** animate the change.  It simply mutates the
    ///   underlying `UINavigationController.viewControllers` array on the main
    ///   thread.  The navigation controller will automatically update its
    ///   visual hierarchy after the mutation.
    ///
    /// - Warning: This operation should be used sparingly.  Removing view controllers
    ///   from the stack without first dismissing or popping them can lead to
    ///   unexpected navigation state.  Use it only when you’re certain the
    ///   target view controllers are no longer needed (e.g., resetting to a
    ///   clean state after a logout).
    public func removeViewTypeFromStack<V: UIViewController>(_ viewControllerType: V.Type) async {
        await MainActor.run(body: {
            navController.viewControllers.removeAll(where: { $0.isKind(of: viewControllerType) })
        })
    }

    /// Dismisses the currently presented view controller, if any.
    ///
    /// This is a convenience wrapper around
    /// `UINavigationController.dismiss`.  The call is dispatched to
    /// the main actor to guarantee that the UI transition occurs on
    /// the main thread.
    ///
    /// - Parameter animated: Whether the dismissal should be
    ///   animated.  Defaults to `true`.
    public func dissmiss(animated: Bool = true) async {
        await MainActor.run {
            guard navController.presentedViewController != nil else { return }
            navController.dismiss(animated: animated)
        }
    }

    /// Decodes a route string and pushes the associated view controller onto
    /// the navigation stack.
    ///
    /// 1. The method looks up a registered `NavigatorPath` whose raw value
    ///    matches the route string after stripping any query‐string
    ///    parameters.
    /// 2. It checks every precondition of the path; if any fails the
    ///    method returns early.
    /// 3. The path’s `action` is awaited to produce the destination
    ///    view controller.
    /// 4. Finally, on the main actor the controller is pushed.
    ///
    /// - Parameter path: The raw route string including optional
    ///   query parameters (`id=42&foo=bar`).
    public func dispatch(for path: String) async {
        guard let foundNavigatorPath = paths.first(where: { $0.path.rawValue == path.pathWithOutParameters() }) else {
            return
        }
        guard foundNavigatorPath.preconditions.map({ $0.shouldRoute(path) }).allSatisfy({$0}) else { return }
        let viewController = await foundNavigatorPath.action(path.getParameters())
        await MainActor.run {
            self.navController.pushViewController(viewController, animated: foundNavigatorPath.animated)
        }
    }
}

// MARK: Main actor functions

@MainActor
extension Navigator {

    /// Makes the navigation controller the root view controller of the
    /// supplied window and makes the window visible.
    ///
    /// This is typically called early in the app launch sequence to
    /// display the navigation hierarchy.
    ///
    /// - Parameter window: The window that will host the navigation
    ///   controller.  Must be passed in as an `inout` reference.
    public func makeKeyAndVisible(window: inout UIWindow) {
        window.rootViewController = navController
        window.makeKeyAndVisible()
    }

    /// Presents a view controller modally over the current navigation
    /// stack.
    ///
    /// The method supports the sheet presentation style on iOS 15+,
    /// allowing the caller to specify custom detents.  The
    /// configuration of `UISheetPresentationController` is applied
    /// automatically whenever the presented controller declares a sheet.
    ///
    /// - Parameters:
    ///   - viewController: The view controller to present.
    ///   - animated: Whether the presentation should be animated.
    ///   - detents: An array of detents that configure sheet height.
    ///   - completion: A closure called after the presentation finishes.
    public func present(_ viewController: UIViewController, animated: Bool = true,
                        detents: [UISheetPresentationController.Detent] = [.large()],
                        completion: @escaping @Sendable () -> Void = {}) {
        if let sheet = viewController.sheetPresentationController {
            sheet.detents = detents
            sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            sheet.prefersEdgeAttachedInCompactHeight = true
            sheet.widthFollowsPreferredContentSizeWhenEdgeAttached = true
        }
        navController.present(viewController, animated: animated, completion: completion)
    }

    // MARK: Navbar styling

    /// Sets an image as the navigation bar’s title view.
    ///
    /// The image is wrapped in a `UIImageView` and assigned directly to
    /// `navigationItem.titleView`.  Passing `nil` removes any existing
    /// image.
    ///
    /// - Parameter image: The optional `UIImage` to use.
    public func setNavBarImage(_ image: UIImage? = nil) {
        let imageView = UIImageView(image: image)
        navController.navigationItem.titleView = imageView
    }

    /// Adds a bar button item to the navigation bar.
    ///
    /// Items can be positioned at the leading, center, or trailing
    /// edge of the navigation bar.  If the `center` position is chosen,
    /// the item is added to the first center group.  The operation is
    /// performed on the main actor to guarantee UI consistency.
    ///
    /// - Parameters:
    ///   - item: The `UIBarButtonItem` to add.
    ///   - position: The desired layout position (`leading`, `center`,
    ///     or `trailing`).
    ///   - animated: Whether the change should be animated.
    public func set(item: UIBarButtonItem, position: NavigationItemPosition = .trailing, animated: Bool = true) {
        switch position {
        case .leading:
            navController.navigationItem.setLeftBarButton(item, animated: animated)
        case .center:
            navController.navigationItem.centerItemGroups.first?.barButtonItems.append(item)
        case .trailing:
            navController.navigationItem.setRightBarButton(item, animated: animated)
        }
    }

    /// Shows or hides the navigation bar.
    ///
    /// This convenience wrapper toggles the underlying
    /// `UINavigationBar.isHidden` property.  The new value is applied
    /// immediately on the main thread.
    ///
    /// - Parameter hide: `true` to hide the bar, or `false` to show it.
    public func hideNavBar(_ hide: Bool) {
        navController.navigationBar.isHidden = true
    }
}

/// Describes the position of a bar button item relative to the
/// navigation bar.
///
/// The `NavigationItemPosition` enum is public so callers may specify
/// a position when adding items programmatically.  The `center` case
/// is only supported on iOS 16+ where center item groups are available; on
/// earlier platforms the item will simply be appended to the first
/// available center group.
public enum NavigationItemPosition {
    case leading, center, trailing
}
