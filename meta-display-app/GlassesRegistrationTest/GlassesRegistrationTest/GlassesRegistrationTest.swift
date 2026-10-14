import MWDATCamera
import MWDATCore
import SwiftUI

@main struct GlassesRegistrationTest: App {
    
    init(){ //init sets initial values for the setup of the app.
        do {
            try Wearables.configure() // The first thing we want to do is configure the Wearables SDK so we can use it
            print("Successfully configured SDK")
            
            startRegistration()
            
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

//APP REGISTRATION: This section of code registers your app with the Meta AI app. --------------------------------------------------------------
func startRegistration() {
    Task { //Code from Claude
        do {
            //Opens Meta AI app and has user register the glasses
            //OUTPUT must be fed to handleUrl -> done by func handleWearablesCallback(url)
            try await Wearables.shared.startRegistration()
        } catch {
            let ns = error as NSError
                print("describing: \(String(describing: error))")
                print("localized: \(error.localizedDescription)")
                print("domain: \(ns.domain), code: \(ns.code), userInfo: \(ns.userInfo)")
        }
    }
}
