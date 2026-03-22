import SwiftUI
import MLXServicePackage

struct AppStackRouter: ViewModifier {
    @EnvironmentObject var router: PushPopNavigationRouter

    private let lLMServiceFactory: LLMServiceFactoryProtocol

    init(lLMServiceFactory: LLMServiceFactoryProtocol) {
        self.lLMServiceFactory = lLMServiceFactory
    }

    func body(content: Content) -> some View {
        NavigationStack(path: $router.paths) {
            content
                .navigationDestination(for: NavigationScreenType.self) { destination in
                    switch destination {
                    case .chat(let prompt, let llmTemperature, let maxTokens):
                        ChatView(model: ChatViewModel(service: lLMServiceFactory.makeLLMService(
                            model: .llama3_2_3b,
                            configuration: LLMGenerationConfig(systemPrompt: prompt,
                                                               maxTokens: maxTokens,
                                                               temperature: llmTemperature))))
                    }
                }
        }
    }
}

extension View {
    func withStackRootView(_ lLMServiceFactory: LLMServiceFactoryProtocol) -> some View {
        modifier(AppStackRouter(lLMServiceFactory: lLMServiceFactory))
    }
}
