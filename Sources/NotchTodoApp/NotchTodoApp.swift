import AppKit

@main
enum NotchTodoApp {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let delegate = AppController()
        application.delegate = delegate

        withExtendedLifetime(delegate) {
            application.run()
        }
    }
}
