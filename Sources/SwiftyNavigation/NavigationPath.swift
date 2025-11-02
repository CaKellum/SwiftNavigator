import Foundation
import UIKit

/// A protocol that allows a type to register all of its navigation paths.
/// Implementers should asynchronously register each path and return `true`
/// if all registrations succeeded, or `false` otherwise.
///
/// This protocol enables decoupled path registration logic that can be
/// performed at app startup or on demand.
public protocol PathRegistrar {
    /// Registers all paths belonging to the conforming type.
    /// - Returns: `true` if registration succeeded, otherwise `false`.
    func registerAll() async -> Bool
}

/// Base protocol for types that represent a navigation path.
/// Conformers are identifiable, hashable, equatable, and sendable.
protocol PathConforming: Identifiable, Hashable, Sendable, Equatable {}

/// A generic type representing a navigation path.
///
/// The type parameter `T` must be a `RawRepresentable` whose raw value
/// is a `String`, providing a stable string identifier for the path.
/// Each `NavigatorPath` carries:
///   - A unique identifier.
///   - An array of `PathPrecondition`s that may short‑circuit routing.
///   - The path itself (`T`).
///   - Whether the navigation should be animated.
///   - An action closure that creates the target `UIViewController`
///     asynchronously based on a dictionary of string parameters.
public struct NavigatorPath<T: RawRepresentable & Sendable>: PathConforming where T.RawValue == String {
    /// A unique identifier for this navigation path.
    public let id: UUID = UUID()

    /// Preconditions that must be satisfied before the path can be taken.
    public let preconditions: Set<PathPrecondition>

    /// The underlying path value.
    public let path: T

    /// Specifies whether navigation should be animated.
    public let animated: Bool

    /// An asynchronous closure that receives a dictionary of
    /// named string parameters and returns the `UIViewController`
    /// to navigate to.
    public let action: @Sendable (_ parameters: [String: String]) async -> UIViewController

    /// Creates a new `NavigatorPath`.
    /// - Parameters:
    ///   - path: The path value.
    ///   - preconditions: Optional preconditions that gate navigation.
    ///   - animated: Whether navigation should be animated. Defaults to `true`.
    ///   - action: A closure that produces the destination view controller.
    public init(path: T,
                preconditions: Set<PathPrecondition> = [],
                animated: Bool = true,
                action: @Sendable @escaping (_: [String: String]) async -> UIViewController) {
        self.preconditions = preconditions
        self.path = path
        self.animated = animated
        self.action = action
    }

    /// Hashes the instance by combining the raw value of the path
    /// and the animated flag.
    /// - Parameter hasher: The hasher to use.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(path.rawValue)
        hasher.combine(animated)
    }

    /// Two `NavigatorPath` values are equal if their underlying paths are equal.
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.path == rhs.path }
}
