import SwiftUI

struct MessageView: View {
    let message: MessageModel

    var messageColor : Color {
        message.isUser ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2)
    }

    var body: some View {
        HStack {
            switch message.userType {
            case .system:
                Text("System: \(message.text)")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)

                default:

                if message.isUser { Spacer() }

                VStack(alignment: !message.isUser ? .leading : .trailing) {
                    Text(message.text)
                        .padding()
                        .background(messageColor)
                        .cornerRadius(10)
                    Text(message.date, style: .time)
                }

                if !message.isUser { Spacer() }
            }

        }
        .padding(.horizontal)
    }
}
