import SwiftUI

struct CategoryEditView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [Color.blue.opacity(0.18), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                VStack(spacing: 28) {
                    headerSection

                    Spacer(minLength: 10)

                    VStack(spacing: 18) {
                        NavigationLink(destination: CategoryAddition()) {
                            CategoryMenuCard(
                                icon: "plus.circle.fill",
                                color: .green,
                                title: "카테고리 추가",
                                subtitle: "새로운 카테고리를 만들고 예산을 설정해요."
                            )
                        }

                        NavigationLink(destination: CategoryModify()) {
                            CategoryMenuCard(
                                icon: "slider.horizontal.3",
                                color: .orange,
                                title: "카테고리 수정 · 삭제",
                                subtitle: "기존 카테고리의 이름, 색, 예산을 관리해요."
                            )
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var headerSection: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.grid.3x3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 72)
                .foregroundColor(.blue)
                .shadow(color: .blue.opacity(0.4), radius: 6, x: 0, y: 4)

            Text("카테고리 편집")
                .font(.title2)
                .fontWeight(.bold)
        }
        .padding(.top, 30)
    }
}

private struct CategoryMenuCard: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.16))
                    .frame(width: 50, height: 50)
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray.opacity(0.6))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
        )
        .contentShape(RoundedRectangle(cornerRadius: 18))
    }
}

#Preview {
    CategoryEditView()
}
