import Foundation

enum NavigationScreenType: Hashable {
    case chat(prompt: String, llmTemperature: Float, maxTokens: Int)
}
