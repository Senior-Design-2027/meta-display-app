import SwiftUI
import MWDATCore
import MWDATCamera

struct ContentView: View {
    
    /*'Wearables' is an Enumeration (custom data type) in MWDATCore. Interacting with it is how you register the device and handle permissions.*/
    /*'Wearables.shared' is the shared instance of the Device Access Toolkit. Assigning it to a variable so it's easier to work with*/
    let wearables = Wearables.shared
    
    //These variables are like static class variables.
    @State private var registrationStatus: RegistrationState = .available
    @State private var cameraStatus: PermissionStatus = .denied //Set the permission status of the camera to "denied" by default (so the user can authorize it in the app).
    @State private var errorMessage: String? //Error message is an optional because it can be nil if no error
    
    var body: some View {
        
        Text("Hello, world!")
            .padding()
        
        //Button("Register glasses") { startRegistration() }
        //    .padding()
        
        Button("Get Camera Permission") {requestCameraPermission()}
            .padding()
        
    }
    
    //FUNCTIONS ==============================================================

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
    
    //UNREGISTRATION: This section of code unregisters your app with the Meta AI app. --------------------------------------------------------------
    func endRegistration() {
        Task {
            do{
                try await wearables.startUnregistration()
              //Opens Meta AI app and has user register the glasses
              //OUTPUT must be fed to handleUrl -> done by func handleWearablesCallback(url)
            } catch {
                errorMessage = "Unregistration failed: \(error.localizedDescription)"
            }
        }

    }
    
    //CHECK REGISTRATION STATUS
    func observeRegistrationStatus() async {
        for await state in wearables.registrationStateStream() {
            registrationStatus = state
            // Check camera permission whenever registration state changes
            if state == .registered {
                await checkCameraPermission()
            }
        }
    }

    //REQUEST PERMISSION TO USE METAGLASSES CAMERA ---------------------------
    func requestCameraPermission(){
        Task { /*A TASK is a unit of asynchronous work. You put what to do in the successful case under 'do' and you put what to do if the Task fails in 'catch'.*/
            do {
                cameraStatus = try await Wearables.shared.requestPermission(.camera)
                /*TRY is used to call functions/methods that can potentially throw errors.
                 AWAIT tells the code to suspend/not move on to below lines until the current line returns its result.*/
            } catch {
                errorMessage = "Camera permission failed: \(error.localizedDescription)"
            }
        }
    }
    
    //CHECK THE CURRENT PERMISSIONS ON CAMERA USE ----------------------------
    func checkCameraPermission() async {
        do {
            //Request permission to use camera in the Meta AI app and change cameraStatus to equal the user's output.
            cameraStatus = try await wearables.checkPermissionStatus(.camera)
            if cameraStatus == .granted { errorMessage = nil }
            print("Permission granted")
        } catch {
            let nsError = error as NSError
                if nsError.domain == "MWDATCore.PermissionError" && nsError.code == 1 {
                        return  // silently ignore
                    }
                    if registrationStatus == .registered {
                        errorMessage = "Permission check failed: \(error.localizedDescription)"
            }
        }
    }
}


