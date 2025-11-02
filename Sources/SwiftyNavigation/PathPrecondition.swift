import Foundation

/// A condition used to determine whether a given route should be passed to a path handler.
///
/// `PathPrecondition` conforms to `PathConforming` and implements `Hashable` & `Equatable`.
/// Each instance has a unique `id`, a human‑readable `name`, and a `shouldRoute` closure that
/// evaluates a `String` route and returns `true` if the route should be processed.
///
/// The closure is marked `@Sendable` so it can be safely executed in concurrent contexts.
public struct PathPrecondition: PathConforming {
    /// A unique identifier for the precondition.
    /// Automatically generated when the struct is created.
    public var id: UUID = UUID()

    /// A descriptive name that identifies the precondition.
    public var name: String

    /// Checks whether the supplied route string should be routed.
    /// The closure must be `@Sendable` to guarantee thread safety.
    public var shouldRoute: @Sendable (_ route: String) async -> Bool

    /// Creates a new `PathPrecondition`.
    /// - Parameters:
    ///   - name: A name that describes the precondition.
    ///   - shouldRoute: A closure that receives a route string and returns `true` if the
    ///     route meets the precondition’s criteria.
    public init(name: String, shouldRoute: @Sendable @escaping (_: String) async -> Bool) {
        self.name = name
        self.shouldRoute = shouldRoute
    }

    /// Hashes the instance, including the unique `id` and `name`.
    /// - Parameter hasher: The hasher to use when combining the values that make up this instance.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    /// Determines equality by comparing the `name` of two `PathPrecondition` instances.
    /// Two instances are considered equal if their names match, regardless of `id`.
    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.name == rhs.name }
}
