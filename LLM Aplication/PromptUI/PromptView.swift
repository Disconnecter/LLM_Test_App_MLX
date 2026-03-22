import SwiftUI

struct PromptView: View {
    @State private var llmTemperature: Float = 0.7
    @State private var maxToken: Int = 1024
    @State private var promptText: String = ""

    @EnvironmentObject var navigationRouter: PushPopNavigationRouter

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Enter your prompt", text: $promptText)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.vertical)
                .onSubmit {
                    submit()
                }

            HStack {
                VStack {
                    Text("LLM Temperature: \(llmTemperature.formatted())")

                    Slider(value: $llmTemperature,
                           in: 0.0...1.0,
                           step: 0.1,
                           label: {}
                    )
                    .padding(.vertical)
                }
                .frame(minWidth: 0, maxWidth: .infinity)
                .padding()

                VStack {
                    Text("Max Tokens: \(maxToken)")
                    HStack(spacing: 0) {
                        TextField("Max Tokens",
                                  value: $maxToken,
                                  formatter: NumberFormatter())
                        Stepper(value: $maxToken,
                                in: 1...4096,
                                step: 10,
                                label: {}
                        )
                    }
                    .padding()
                }
                .frame(minWidth: 0, maxWidth: .infinity)
            }

            Button(action: {
                submit()
            }) {
                Text("Submit")
                    .padding()
                    .cornerRadius(10)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
    }
}

private extension PromptView {
    func submit() {
        navigationRouter.push(.chat(prompt: promptText, llmTemperature: llmTemperature, maxTokens: maxToken))
    }
}

