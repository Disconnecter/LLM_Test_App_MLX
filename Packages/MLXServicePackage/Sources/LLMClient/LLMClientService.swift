import Foundation
import MLXLMCommon
import os

actor LLMClientService {
    private var session: ChatSession?
    private let logger = Logger(subsystem: "LLMClientService", category: "LLMClientService")
}

extension LLMClientService: LLMClientServiceProtocol {
    func load(model: LLMModelDescriptor,
              configuration: LLMGenerationConfig) async throws(LLMClientServiceError) {
        await unload()
        do {
            logger.info("Starting to load model \(model.identifier)")
            let modelContext = try await loadModel(id: model.identifier)
            logger.info("Successfully loaded model \(model.identifier)")

            let generateParameters = GenerateParameters(maxTokens: configuration.maxTokens,
                                                        temperature: configuration.temperature)

            session = ChatSession(modelContext,
                                  instructions: configuration.systemPrompt,
                                  generateParameters: generateParameters)
            logger.info("Chat session initialized for model \(model.identifier)")
        } catch {
            logger.error("Failed to load model \(model.identifier): \(error.localizedDescription)")
            throw .loadingFailed
        }
    }
    
    func unload() async {
        session = nil
    }
    
    func generate(input: String) async throws(LLMClientServiceError) -> AsyncThrowingStream<String, Error> {
        guard !input.isEmpty else {
            throw .emptyInput
        }

        guard let session else {
            throw .modelNotLoaded
        }

        return session.streamResponse(to: input)
    }
}
