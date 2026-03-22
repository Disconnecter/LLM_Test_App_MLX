import Foundation
@testable import MLXServicePackage

enum RecordedServiceState: Equatable {
    case idle
    case loadingModel
    case ready
    case chunk(String)
    case responseFailure(String)
    case error(LLMServiceError)
}

final class StateRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private var storedValues: [RecordedServiceState] = []

    func append(_ value: RecordedServiceState) {
        lock.lock()
        storedValues.append(value)
        lock.unlock()
    }

    var values: [RecordedServiceState] {
        lock.lock()
        defer { lock.unlock() }
        return storedValues
    }
}
