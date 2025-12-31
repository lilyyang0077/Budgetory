import SwiftUI

struct TabbarView: View {
    @State private var selectedTab = 1   // 메인뷰를 기본값으로 설정 (tag = 1)

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                StaticsView()
            }
            .tabItem {
                Label("통계", systemImage: "chart.bar.fill")
            }
            .tag(0)

            NavigationStack {
                MainView()
            }
            .tabItem {
                Label("메인", systemImage: "house.fill")
            }
            .tag(1)   // ⬅ default로 선택될 탭

            NavigationStack {
                ConsumpFairyView()
            }
            .tabItem {
                Label("소비요정", systemImage: "sparkles")
            }
            .tag(2)

            NavigationStack {
                SettingView()
            }
            .tabItem {
                Label("계정 설정", systemImage: "gearshape.fill")
            }
            .tag(3)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AlarmView()) {
                    Image(systemName: "bell.fill")
                }
            }
        }
    }
}

#Preview {
    TabbarView()
}
