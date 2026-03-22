public enum LLMModelDescriptor: Sendable {
    case llama3_2_3b
}

extension LLMModelDescriptor {
    var identifier: String {
        switch self {
        case .llama3_2_3b:
            "mlx-community/Llama-3.2-3B-Instruct-4bit"
        }
    }
}
