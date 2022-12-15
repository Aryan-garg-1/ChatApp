import SwiftUI

@main
struct ChatApp: App {
    
    @StateObject var userName = UserName()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack{
                MainView()
                    .environmentObject(userName)
            }.onAppear {
                loadAppData { result in
                    switch result {
                    case .failure(let error):
                        fatalError(error.localizedDescription)
                    case .success(let data):
                        appData = data
                    }
                }
            }

        }
    }
}
