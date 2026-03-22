public enum LLMServiceState: Sendable {
    case idle
    case loadingModel
    case ready
    case responding(Result<String, Error>)
    case error(LLMServiceError)
}
