import Foundation

enum LLMClientServiceError: LocalizedError {
    case loadingFailed
    case modelNotLoaded
    case emptyInput
}

protocol LLMClientServiceProtocol: Sendable {
    func load(model: LLMModelDescriptor, configuration: LLMGenerationConfig) async throws(LLMClientServiceError)
    func unload() async
    func generate(input: String) async throws(LLMClientServiceError) -> AsyncThrowingStream<String, Error>
}
