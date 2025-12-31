import SwiftUI

struct StartView: View {
    @State private var goLogin = false

    var body: some View {
        NavigationStack {
            ZStack {
                VStack {
                    Spacer()
                    Text("Budgetory")
                        .font(.largeTitle).bold()
                    Spacer()
                }

                // 숨김 NavigationLink: isActive 토글로 자동 이동
                NavigationLink("", destination: LoginView(), isActive: $goLogin)
                    .hidden()
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    goLogin = true
                }
            }
        }
    }
}

#Preview {
    StartView()
}
