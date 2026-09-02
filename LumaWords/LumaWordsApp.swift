import SwiftUI

@main @MainActor
struct LumaWordsApp: App {
    @State private var store = StudyStore()
    @State private var ambientSound = AmbientSoundEngine()

    var body: some Scene {
        WindowGroup {
            RootView(store: store)
                .environment(ambientSound)
                .preferredColorScheme(.dark)
        }
    }
}
