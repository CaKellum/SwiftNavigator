import Foundation

/// A convenient set of extensions on ``String`` for dealing with URLs
/// and query‑string parameters.
///
/// The helpers are deliberately lightweight – they use the standard
/// `URL` and `URLComponents` APIs, so they behave exactly the same as
/// anything you’d accomplish with `URLQueryItem` or `URLComponents`
/// directly.  The extensions are useful in a navigation‑routing context
/// where a route string may need query parameters appended or parsed
/// back into a dictionary.
///
/// The API is intentionally **immutable**: none of the helpers mutate
/// the original string; instead each one returns a new string that
/// reflects the requested change.

public extension String {
    /// An empty string literal.
    ///
    /// Use ``String.empty`` instead of `""` when you need a named
    /// constant that conveys the intent of “no value”.
    ///
    /// ```swift
    /// let maybeEmpty = optionalString ?? String.empty
    /// ```
    static let empty = ""

    /// Appends a set of query parameters to a URL represented by the
    /// receiver.
    ///
    /// If the string is not a valid URL, the original string is returned.
    /// The function builds a ``URLQueryItem`` array, uses
    /// ``URL.appending(queryItems:)`` – a small helper that internally
    /// leverages ``URLComponents`` – and returns the resulting absolute
    /// string.
    ///
    /// - Parameters:
    ///   - parameters: A dictionary of *key*‑*value* pairs to encode.
    ///
    /// - Returns: A new string representing the original URL with the
    ///   supplied query‑string items appended.
    ///
    /// - Note: This helper does **not** modify any existing query
    ///   items; it simply creates a new query string on top of the
    ///   original value.
    func add(parameters: [String: String]) -> String {
        guard let url = URL(string: self) else { return self }
        let items = parameters.map { key, value in URLQueryItem(name: key, value: value) }
        return url.appending(queryItems: items).absoluteString
    }

    /// Appends a single query‑string parameter to a URL represented by
    /// the receiver.
    ///
    /// It is a thin wrapper around ``String.add(parameters:)`` that
    /// avoids creating an intermediate `Dictionary`.  If the string
    /// cannot be parsed as a URL the original value is returned.
    ///
    /// - Parameters:
    ///   - key:   The name of the query item.
    ///   - value: The string value to encode.
    ///
    /// - Returns: A new string that contains the original URL plus the
    ///   supplied query argument.
    func add(parameter key: String, with value: String) -> String {
        guard let url = URL(string: self) else { return self }
        let item = URLQueryItem(name: key, value: value)
        return url.appending(queryItems: [item]).absoluteString
    }

    /// Parses the query string of the receiver and returns a
    /// ``[String:String]`` dictionary.
    ///
    /// The helper uses ``URLComponents`` internally so percent‑encoded
    /// characters are decoded automatically.  If the string is not a
    /// valid URL or has no query part, an empty dictionary is returned.
    ///
    /// Example:
    /// ```swift
    /// let route = "/user?id=123&filter=active"
    /// let params = route.getParameters()   // ["id":"123","filter":"active"]
    /// ```
    ///
    /// - Returns: A mapping of query‑string keys to values.  The values
    ///   are always simple strings; missing keys are ignored.
    func getParameters() -> [String: String] {
        guard let url = URL(string: self) else { return [:] }
        let items: [String] = url.query(percentEncoded: false)?
            .split(separator: "&")
            .map { String($0) } ?? []
        var params = [String: String]()
        for item in items {
            let parts = item.split(separator: "=").map { String($0) }
            guard let key = parts.first else { continue }
            params[key] = parts.last ?? .empty
        }
        return params
    }

    /// Returns the path component of a URL that is represented by the
    /// receiver, **without** any query‑string or fragment.
    ///
    /// For a non‑URL string, the original value is returned unchanged.
    ///
    /// Example:
    /// ```swift
    /// let route = "/profile?tab=info"
    /// let path  = route.pathWithOutParameters()   // "/profile"
    /// ```
    ///
    /// - Returns: The path portion of the URL (`/profile` in the example above).
    func pathWithOutParameters() -> String {
        guard let url = URL(string: self) else { return self }
        return url.path(percentEncoded: false)
    }
}
