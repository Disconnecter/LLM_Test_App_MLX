import Combine
import Foundation
import Testing
import MLXServicePackage
@testable import LLM_Aplication

@Suite("ChatViewModelTests")
@MainActor
struct ChatViewModelTests {
    @Test
    func init_exposesPromptAndStartsIdle() {
        let service = MockLLMService(currentPrompt: "System prompt")
        let sut = ChatViewModel(service: service)

        #expect(sut.systemPrompt == "System prompt")
        #expect(sut.state == .idle)
        #expect(sut.messages.isEmpty)
        #expect(sut.canSend == false)
    }

    @Test
    func loadModel_forwardsToService() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        await sut.loadModel()

        #expect(service.loadCallCount == 1)
    }

    @Test
    func readyState_enablesSending() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        service.emit(.ready)
        await drainMainQueue()

        #expect(sut.state == .ready)
        #expect(sut.canSend)
    }

    @Test
    func send_whenReady_appendsMessagesAndInvokesService() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        service.emit(.ready)
        await drainMainQueue()

        sut.send(message: "Hello")
        await eventually { service.craftInputs == ["Hello"] }

        #expect(sut.state == .crafting)
        #expect(recordedMessages(from: sut.messages) == [
            RecordedMessage(text: "Hello", role: .user),
            RecordedMessage(text: "", role: .assistant)
        ])
        #expect(sut.canSend == false)
    }

    @Test
    func send_whenNotReady_isIgnored() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        sut.send(message: "Hello")
        await Task.yield()

        #expect(service.craftInputs.isEmpty)
        #expect(sut.messages.isEmpty)
        #expect(sut.state == .idle)
    }

    @Test
    func respondingSuccess_appendsChunkToAssistantMessage() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        service.emit(.ready)
        await drainMainQueue()

        sut.send(message: "Hello")
        await eventually { service.craftInputs == ["Hello"] }

        service.emit(.responding(.success("Hi there")))
        await drainMainQueue()

        #expect(recordedMessages(from: sut.messages) == [
            RecordedMessage(text: "Hello", role: .user),
            RecordedMessage(text: "Hi there", role: .assistant)
        ])
        #expect(sut.state == .crafting)
    }

    @Test
    func respondingFailure_appendsSystemErrorAndReturnsReady() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)
        let expectedError = TestError.streamFailure

        service.emit(.ready)
        await drainMainQueue()

        sut.send(message: "Hello")
        await eventually { service.craftInputs == ["Hello"] }

        service.emit(.responding(.failure(expectedError)))
        await drainMainQueue()

        #expect(recordedMessages(from: sut.messages) == [
            RecordedMessage(text: "Hello", role: .user),
            RecordedMessage(text: "", role: .assistant),
            RecordedMessage(text: "Error: \(expectedError.localizedDescription)", role: .system)
        ])
        #expect(sut.state == .ready)
        #expect(sut.canSend)
    }

    @Test
    func serviceError_appendsSystemErrorAndReturnsIdle() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        service.emit(.error(.loadingFailed))
        await drainMainQueue()

        #expect(recordedMessages(from: sut.messages) == [
            RecordedMessage(
                text: "Error: \(LLMServiceError.loadingFailed.localizedDescription)",
                role: .system
            )
        ])
        #expect(sut.state == .idle)
        #expect(sut.canSend == false)
    }

    @Test
    func unloadModel_clearsMessagesAndReturnsToIdle() async {
        let service = MockLLMService()
        let sut = ChatViewModel(service: service)

        service.emit(.ready)
        await drainMainQueue()

        sut.send(message: "Hello")
        await eventually { service.craftInputs == ["Hello"] }

        await sut.unloadModel()

        #expect(service.unloadCallCount == 1)
        #expect(sut.messages.isEmpty)
        #expect(sut.state == .idle)
        #expect(sut.canSend == false)
    }
}

private extension ChatViewModelTests {
    func drainMainQueue() async {
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                continuation.resume()
            }
        }
    }

    func eventually(
        timeout: Duration = .seconds(1),
        interval: Duration = .milliseconds(10),
        condition: () -> Bool
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + timeout

        while !condition() && clock.now < deadline {
            try? await Task.sleep(for: interval)
        }
    }

    func recordedMessages(from messages: [MessageModel]) -> [RecordedMessage] {
        messages.map {
            RecordedMessage(text: $0.text, role: RecordedRole($0.userType))
        }
    }
}

private final class MockLLMService: LLMServiceProtocol {
    private let stateSubject: CurrentValueSubject<LLMServiceState, Never>
    private let lock = NSLock()

    private(set) var currentPrompt: String

    private var storedLoadCallCount = 0
    private var storedUnloadCallCount = 0
    private var storedCraftInputs: [String] = []

    var state: AnyPublisher<LLMServiceState, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    var loadCallCount: Int {
        lock.withLock {
            storedLoadCallCount
        }
    }

    var unloadCallCount: Int {
        lock.withLock {
            storedUnloadCallCount
        }
    }

    var craftInputs: [String] {
        lock.withLock {
            storedCraftInputs
        }
    }

    init(
        currentPrompt: String = "Test prompt",
        initialState: LLMServiceState = .idle
    ) {
        self.currentPrompt = currentPrompt
        self.stateSubject = CurrentValueSubject(initialState)
    }

    func load() async {
        lock.withLock {
            storedLoadCallCount += 1
        }
    }

    func unload() async {
        lock.withLock {
            storedUnloadCallCount += 1
        }
    }

    func craftResponse(for input: String) async {
        lock.withLock {
            storedCraftInputs.append(input)
        }
    }

    func emit(_ state: LLMServiceState) {
        stateSubject.send(state)
    }
}

private struct RecordedMessage: Equatable {
    let text: String
    let role: RecordedRole
}

private enum RecordedRole: Equatable {
    case user
    case assistant
    case system

    init(_ userType: UserType) {
        switch userType {
        case .user:
            self = .user
        case .assistant:
            self = .assistant
        case .system:
            self = .system
        }
    }
}

private enum TestError: LocalizedError {
    case streamFailure

    var errorDescription: String? {
        switch self {
        case .streamFailure:
            "Stream failure"
        }
    }
}
