@testable import MLXServicePackage

actor MockLLMClientService: LLMClientServiceProtocol {
    enum LoadBehavior {
        case success
        case failure(LLMClientServiceError)
    }

    private let loadBehavior: LoadBehavior
    private let responseChunks: [String]

    private var loadCallCount = 0
    private var unloadCallCount = 0
    private var generateInputs: [String] = []

    init(
        loadBehavior: LoadBehavior = .success,
        responseChunks: [String] = []
    ) {
        self.loadBehavior = loadBehavior
        self.responseChunks = responseChunks
    }

    func load(
        model: LLMModelDescriptor,
        configuration: LLMGenerationConfig
    ) async throws(LLMClientServiceError) {
        loadCallCount += 1

        switch loadBehavior {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    func unload() async {
        unloadCallCount += 1
    }

    func generate(input: String) async throws(LLMClientServiceError) -> AsyncThrowingStream<String, Error> {
        generateInputs.append(input)

        return AsyncThrowingStream { continuation in
            for chunk in responseChunks {
                continuation.yield(chunk)
            }
            continuation.finish()
        }
    }

    func loadCallCountValue() -> Int {
        loadCallCount
    }

    func unloadCallCountValue() -> Int {
        unloadCallCount
    }

    func generateInputsValue() -> [String] {
        generateInputs
    }
}
