import Foundation

extension Sequence where Element: Sendable {
    func concurrentMap<T: Sendable>(_ transform: @escaping @Sendable (Element) async throws -> T) async rethrows -> [T] {
        try await withThrowingTaskGroup(of: (offset: Int, element: T).self) { group in
            for (offset, element) in enumerated() {
                group.addTask {
                    (offset, try await transform(element))
                }
            }

            var results: [(offset: Int, element: T)] = []
            results.reserveCapacity(underestimatedCount)

            while let result = try await group.next() {
                results.append(result)
            }

            return results.sorted { $0.offset < $1.offset }.map(\.element)
        }
    }
}
