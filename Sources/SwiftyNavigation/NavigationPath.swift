import Foundation
import UIKit

// idea being that you can store
public protocol PathRegistrar {
    func registerAll() async -> Bool
}

protocol PathConforming: Identifiable, Hashable, Sendable, Equatable {}

public struct NavigatorPath<T: RawRepresentable & Sendable>: PathConforming where T.RawValue == String {
    public let id: UUID = UUID()
    public let preconditions: [PathPrecondition]
    public let path: T
    public let animated: Bool
    public let action: @Sendable (_ parameters: [String: String]) async -> UIViewController

    public init(path: T, preconditions: [PathPrecondition] = [],
                animated: Bool = true, action: @Sendable @escaping (_: [String: String]) async -> UIViewController) {
        self.preconditions = preconditions
        self.path = path
        self.animated = animated
        self.action = action
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(path.rawValue)
        hasher.combine(animated)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.path == rhs.path }
}
