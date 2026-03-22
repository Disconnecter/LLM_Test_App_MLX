import Foundation
import MLXServicePackage
import Combine

@MainActor
final class ChatViewModel: ObservableObject {
    @Published private(set) var messages: [MessageModel] = []
    @Published private(set) var state: ChatViewModelState = .idle

    private var generationTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()

    var systemPrompt: String {
        service.currentPrompt
    }

    var canSend: Bool {
        state == .ready && generationTask == nil
    }

    private let service: LLMServiceProtocol

    init(service: LLMServiceProtocol) {
        self.service = service
        subscribeToServiceState()
    }

    deinit {
        cancellables.forEach { $0.cancel() }
        generationTask?.cancel()
    }

    func loadModel() async {
        await service.load()
    }

    func unloadModel() async {
        cancelTaskIfNeeded()
        await service.unload()
        state = .idle
        messages.removeAll()
    }

    func send(message: String) {
        guard canSend else { return }
        state = .crafting
        messages.append(MessageModel(text: message, userType: .user))
        messages.append(MessageModel(text: "", userType: .assistant))
        generationTask = Task {
            await service.craftResponse(for: message)
        }
    }
}

private extension ChatViewModel {
    func subscribeToServiceState() {
        service.state
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                switch state {
                case .idle, .loadingModel:
                    self?.state = .idle

                case .ready:
                    self?.state = .ready
                    self?.cancelTaskIfNeeded()

                case .responding(let result):
                    switch result {
                    case .success(let chunk):
                        guard let lastIndex = self?.messages.lastIndex(where: { !$0.isUser }) else { return }
                        self?.messages[lastIndex].text += chunk

                    case .failure(let error):
                        self?.messages.append(MessageModel(text: "Error: \(error.localizedDescription)", userType: .system))
                        self?.state = .ready
                        self?.cancelTaskIfNeeded()
                    }

                case .error(let error):
                    self?.messages.append(MessageModel(text: "Error: \(error.localizedDescription)", userType: .system))
                    self?.state = .idle
                    self?.cancelTaskIfNeeded()
                }
            }
            .store(in: &cancellables)
    }

    func cancelTaskIfNeeded() {
        if let task = generationTask {
            task.cancel()
            generationTask = nil
        }
    }
}
