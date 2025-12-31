import SwiftUI

struct ConsumpFairyView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                // 🌈 부드러운 파스텔 그라데이션 배경
                LinearGradient(
                    colors: [.pink.opacity(0.3), .yellow.opacity(0.2), .purple.opacity(0.25)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    // 🧚 메인 타이틀
                    VStack(spacing: 6) {
                        Text("🧚‍♀️ 소비요정 페이지")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("오늘도 현명한 소비를 위한 여정 ✨")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // 💖 카드형 버튼
                    NavigationLink(destination: ItemView()) {
                        FairyCard(title: "포인트 아이템 페이지", icon: "gift.fill", color: .pink)
                    }
                    
                    NavigationLink(destination: JournalView()) {
                        FairyCard(title: "소비일기 페이지", icon: "book.closed.fill", color: .orange)
                    }
                    
                    NavigationLink(destination: CategoryEditView()) {
                        FairyCard(title: "카테고리 수정 페이지", icon: "slider.horizontal.3", color: .purple)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
    }
}

struct FairyCard: View {
    var title: String
    var icon: String
    var color: Color
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
                .frame(width: 40, height: 40)
                .background(color)
                .clipShape(Circle())
            
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.white.opacity(0.9))
        .cornerRadius(16)
        .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 4)
    }
}

#Preview {
    ConsumpFairyView()
}
