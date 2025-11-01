import Foundation

public extension String {
    static let empty = ""

    func add(parameters: [String: String]) -> String {
        guard let url = URL(string: self) else { return self }
        let items = parameters.map({ key, value in URLQueryItem(name: key, value: value) })
        return url.appending(queryItems: items).absoluteString
    }

    func add(parameter key: String, with value: String) -> String {
        guard let url = URL(string: self) else { return self }
        let item = URLQueryItem(name: key, value: value)
        return url.appending(queryItems: [item]).absoluteString
    }

    func getParameters() -> [String: String] {
        guard let url = URL(string: self) else { return [: ] }
        let items: [String] = url.query(percentEncoded: false)?.split(separator: "&").map({ String($0) }) ?? []
        var params = [String: String]()
        for item in items {
            let parts = item.split(separator: "=").map({ String($0) })
            guard let key = parts.first else { continue }
            params[key] = parts.last ?? .empty
        }
        return params
    }

    func pathWithOutParameters() -> String {
        guard let url = URL(string: self) else { return self }
        return url.path(percentEncoded: false)
    }
}
