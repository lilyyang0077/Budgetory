import SwiftUI

@main
struct BudgetoryApp: App {
    var body: some Scene {
        WindowGroup {
            // 루트에 NavigationStack 한 번만
            NavigationStack {
                StartView()   // Start → (2초 후) LoginView로 이동 (NavigationLink 사용)
            }
        }
    }
}


