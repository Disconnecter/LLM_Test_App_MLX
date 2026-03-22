import Combine

public protocol LLMServiceProtocol: AnyObject {
    var state: AnyPublisher<LLMServiceState, Never> { get }
    var currentPrompt: String { get }

    func load() async
    func unload() async
    func craftResponse(for input: String) async
}
