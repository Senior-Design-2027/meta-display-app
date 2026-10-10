import MWDATCamera
import MWDATCore
import SwiftUI

@main struct GlassesRegistrationTest: App {
    
    init(){ //init sets initial values for the setup of the app.
        do {
            try Wearables.configure() // The first thing we want to do is configure the Wearables SDK so we can use it
            print("Successfully configured SDK")
        } catch {
            print("Failed to configure SDK: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL{ url in
                    Task {
                        try? await Wearables.shared.handleUrl(url)
                        //This function handles any situation in which we get sent to the Meta AI and then go back to our app. It handles the output of your interactions with the Meta AI app.
                    }
                }
        }
    }
}
//
