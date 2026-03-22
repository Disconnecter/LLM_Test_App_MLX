import SwiftUI
import MLXServicePackage

@main
struct LLM_AplicationApp: App {

    private let router: PushPopNavigationRouter = .init()

    var body: some Scene {
        WindowGroup {
            PromptView()
                .withStackRootView(LLMServiceFactory())
                .environmentObject(router)
        }
    }
}
