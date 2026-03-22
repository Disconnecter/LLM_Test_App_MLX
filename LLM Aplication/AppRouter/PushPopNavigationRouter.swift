import Combine

final class PushPopNavigationRouter: ObservableObject {
    @Published var paths: [NavigationScreenType] = []

    func push(_ destination: NavigationScreenType) {
        paths.append(destination)
    }

    func pop() {
        if !paths.isEmpty {
            paths.removeLast()
        }
    }
}
