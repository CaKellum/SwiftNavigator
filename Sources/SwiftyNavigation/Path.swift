import Foundation
import UIKit

public struct Path: Identifiable, Hashable, Sendable, Equatable {
    public let id: UUID = UUID()
    public let preconditions: [PathPrecondition]
    public let path: String
    public let animated: Bool
    public let action: @Sendable (_ parameters: [String: String]) async -> UIViewController

    public init(path: String, preconditions: [PathPrecondition] = [],
                animated: Bool = true, action: @Sendable @escaping (_: [String : String]) async -> UIViewController) {
        self.preconditions = preconditions
        self.path = path
        self.animated = animated
        self.action = action
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(path)
        hasher.combine(animated)
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { lhs.path == rhs.path }
}
