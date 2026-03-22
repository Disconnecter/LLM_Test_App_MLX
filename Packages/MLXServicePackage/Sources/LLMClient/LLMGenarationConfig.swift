public struct LLMGenerationConfig: Sendable {
    let systemPrompt: String?
    let maxTokens: Int
    let temperature: Float

    public init(systemPrompt: String? = nil, maxTokens: Int, temperature: Float) {
        self.systemPrompt = systemPrompt
        self.maxTokens = maxTokens
        self.temperature = temperature
    }
}
