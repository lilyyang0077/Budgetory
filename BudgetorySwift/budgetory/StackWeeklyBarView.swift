import SwiftUI
import Charts

struct StackWeeklyBarView: View {
    let data: [CategoryWeekStatic]

    
    
    // 카테고리별 색상
    private let tagColors: [Int: Color] = [
        1: .red,
        2: .orange,
        3: .yellow,
        4: .green,
        5: .blue,
        6: .indigo,
        7: .purple
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {

            Text("카테고리별 소비 비율")
                .font(.headline)

            // 1) amount > 0 인 카테고리만 사용
            let filtered = data.filter { $0.amount > 0 }
            let totalAmount = filtered.map { $0.amount }.reduce(0, +)

            if filtered.isEmpty {
                Text("데이터 없음")
                    .foregroundColor(.gray)
            }

            ZStack(alignment: .trailing) {

                //가로 스택바 (회색 배경 제거 완료)
                Chart {
                    ForEach(filtered) { item in
                        BarMark(
                            x: .value("Amount", item.amount),
                            y: .value("카테고리", "전체")
                        )
                        .foregroundStyle(colorFor(item.tagColorPK))
                    }
                }
                .frame(height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .chartYAxis(.hidden)
                .chartXAxis {
                    // 3) 0만 보이도록 설정
                    AxisMarks(values: [0]) { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }

                //4) 오른쪽 끝에 총 소비금액 표시
                Text("\(totalAmount)원")
                    .font(.caption2)            // 더 작은 텍스트
                    .foregroundColor(.gray)
                    .offset(y: 17)
            }

            //범례
            VStack(alignment: .leading, spacing: 10) {
                ForEach(filtered) { item in
                    HStack {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(colorFor(item.tagColorPK))
                            .frame(width: 16, height: 16)

                        Text("\(item.categoryName)")
                            .font(.subheadline)

                        Spacer()

                        Text("\(item.amount)원")
                            .bold()
                    }
                }
            }
        }
        .padding(.vertical)
    }

    // 색상 선택 함수
    private func colorFor(_ tagColorPK: Int) -> Color {
        tagColors[tagColorPK] ?? .gray
    }
}
