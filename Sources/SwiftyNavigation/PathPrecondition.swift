import Foundation

public struct PathPrecondition: Identifiable, Hashable, Equatable, Sendable {
    public var id: UUID = UUID()
    public var name: String
    public var shouldRoute: @Sendable (_ route: String) -> Bool

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }

    public static func ==(lhs: Self, rhs: Self) -> Bool { lhs.name == rhs.name }
}

