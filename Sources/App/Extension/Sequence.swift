public extension Sequence {
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows
        -> [T]
    {
        var values = [T]()
        for element in self { try await values.append(transform(element)) }
        return values
    }

    func concurrentMap<T>(
        withPriority priority: TaskPriority? = nil,
        _ transform: @escaping (Element) async throws -> T
    ) async rethrows -> [T] {
        let tasks = map { element in
            Task(priority: priority) { try await transform(element) }
        }

        return try await tasks.asyncMap { task in try await task.value }
    }
}
