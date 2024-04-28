import Fluent

extension Page where T: Encodable {
    public func asyncMap<U>(_ mapper: (T) async throws -> (U)) async rethrows
        -> Page<U>
    { try await .init(items: items.asyncMap(mapper), metadata: metadata) }
}
