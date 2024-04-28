public extension Sequence {
    func asyncMap<T>(_ mapper: (Element) async throws -> T) async rethrows
        -> [T]
    {
        var values = [T]()
        for element in self { try await values.append(mapper(element)) }
        return values
    }
}
