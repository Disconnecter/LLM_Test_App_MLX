import SwiftUI

struct ChatView: View {
    @StateObject private var model: ChatViewModel

    @State private var userMessage: String = ""

    var body: some View {
        VStack {
            Text(model.systemPrompt)

            ScrollView {
                LazyVStack() {
                    ForEach(model.messages) { message in
                        MessageView(message: message)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)

            HStack {
                TextField("Enter your message", text: $userMessage)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                    .onSubmit {
                        submitMessage()
                    }

                Button(action: {
                    submitMessage()
                }) {
                    if model.canSend {
                        Image(systemName: "paperplane.fill")
                            .foregroundColor(.blue)
                            .padding()
                    } else {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
                .disabled(userMessage.isEmpty || !model.canSend)
            }
        }
        .navigationTitle("Chat with LLM")
        .padding()
        .task {
            await model.loadModel()
        }
        .onDisappear {
            Task {
                await model.unloadModel()
            }
        }
    }

    init(model: ChatViewModel) {
        _model = StateObject(wrappedValue: model)
    }
}

private extension ChatView {
    func submitMessage() {
        guard !userMessage.isEmpty, model.canSend else {
            return
        }
        model.send(message: userMessage)
        userMessage = ""
    }
}
