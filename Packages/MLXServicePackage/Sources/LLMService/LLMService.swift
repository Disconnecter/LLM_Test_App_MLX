import Combine
import os

private enum ServiceState: Equatable {
    case loading
    case ready
    case notLoaded

    var description: String {
        switch self {
        case .loading:
            return "loading"
        case .ready:
            return "ready"
        case .notLoaded:
            return "not loaded"
        }
    }
}

final class LLMService {
    let currentState: CurrentValueSubject<LLMServiceState, Never> = CurrentValueSubject(.idle)
    let currentPrompt: String

    private let logger = Logger(subsystem: "LLMService", category: "LLMService")
    private let client: LLMClientServiceProtocol
    private let model: LLMModelDescriptor
    private let configuration: LLMGenerationConfig

    private var serviceState: ServiceState = .notLoaded

    init(client: LLMClientServiceProtocol,
         model: LLMModelDescriptor,
         configuration: LLMGenerationConfig) {
        self.client = client
        self.model = model
        self.configuration = configuration
        self.currentPrompt = configuration.systemPrompt ?? ""
    }
}

extension LLMService: LLMServiceProtocol {
    var state: AnyPublisher<LLMServiceState, Never> {
        currentState.eraseToAnyPublisher()
    }
    
    func load() async {
        if serviceState == .ready || serviceState == .loading {
            logger.warning("Attempted to load model when one is \(self.serviceState.description)")
            return
        }

        serviceState = .loading
        currentState.send(.loadingModel)
        do {
            try await client.load(model: model, configuration: configuration)
            serviceState = .ready
            currentState.send(.ready)
        } catch {
            serviceState = .notLoaded
            currentState.send(.error(.loadingFailed))
        }
    }

    func unload() async {
        if serviceState == .notLoaded || serviceState == .loading  {
            logger.warning("Attempted to unload model when none is loaded")
            return
        }

        await client.unload()
        serviceState = .notLoaded
        currentState.send(.idle)
    }

    func craftResponse(for input: String) async {
        do {
            let stream = try await client.generate(input: input)
            for try await chunk in stream {
                try Task.checkCancellation()
                logger.info("Received chunk: \(chunk)")
                currentState.send(.responding(.success(chunk)))
            }
            try Task.checkCancellation()
            currentState.send(.ready)
        } catch is CancellationError {
            logger.error("Generation cancelled")
        } catch let error as LLMClientServiceError {
            logger.error("Error generating response: \(error.localizedDescription)")
            switch error {
            case .emptyInput:
                currentState.send(.error(.emptyInput))

            case .modelNotLoaded:
                currentState.send(.error(.modelNotLoaded))

            default:
                break
            }
        } catch {
            logger.error("Error generating response: \(error.localizedDescription)")
            currentState.send(.responding(.failure(error)))
        }
    }
}
