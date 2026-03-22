import Foundation

enum UserType {
    case user
    case assistant
    case system
}

struct MessageModel: Identifiable {
    let id = UUID()
    var text: String
    let userType: UserType
    let date: Date

    var isUser: Bool {
        userType == .user
    }

    init(text: String, userType: UserType, date: Date = Date()) {
        self.text = text
        self.userType = userType
        self.date = date
    }
}

