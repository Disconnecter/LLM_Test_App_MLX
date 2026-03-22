public protocol LLMServiceFactoryProtocol: Sendable {
    func makeLLMService(model: LLMModelDescriptor, configuration: LLMGenerationConfig) -> LLMServiceProtocol
}

public struct LLMServiceFactory {
    public init() {}
}

extension LLMServiceFactory: LLMServiceFactoryProtocol {
    public func makeLLMService(
        model: LLMModelDescriptor = .llama3_2_3b,
        configuration: LLMGenerationConfig
    ) -> LLMServiceProtocol {
        LLMService(client: LLMClientService(),
                   model: model,
                   configuration: configuration)
    }
}
