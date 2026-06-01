import SwiftUI

@main
struct LocalGenApp: App {
    var body: some Scene {
        WindowGroup {
            GenerateView()
                .preferredColorScheme(.dark)
        }
    }
}
