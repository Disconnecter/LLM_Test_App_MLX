import Foundation

public enum LLMServiceError: LocalizedError, Equatable, Sendable {
    case loadingFailed
    case modelNotLoaded
    case emptyInput
}
