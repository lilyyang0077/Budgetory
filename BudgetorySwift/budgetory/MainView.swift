import SwiftUI

struct RecentRecord: Codable {
    var incomeConsumePK: Int
    var type: Int
    var title: String?
    var amount: Int?
    var consumptionAt: Date
    var categoryPK: Int?
    var createdAt: Date
}

//리스트로 출력할 부분 구조체
struct RecentRecordItem: View {
    @State var recentRecordData : RecentRecord
    var body: some View {
        HStack(spacing: 10) {
            // 유형 표시
            Text(recentRecordData.type == 0 ? "지출" : "수입")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(recentRecordData.type == 0 ? .red : .green)
                .frame(width: 40)

            // 내역 + 금액 (금액은 내역 아래에 표시)
            VStack(alignment: .leading, spacing: 4) {
                Text(recentRecordData.title ?? "제목 없음")
                    .font(.body)
                    .fontWeight(.semibold)
                
                Text("₩\(recentRecordData.amount ?? 0)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            Spacer()

            // 오른쪽에 createdAt (편집일)
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(recentRecordData.createdAt, formatter: dateFormatterFull)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color.white)
    }
}

struct RecentRecords: Codable {
    var recentRecords: [RecentRecord]
}

//메인뷰 부분
struct MainView: View {
    @State private var id: String = ""
    @State var recentRecords: RecentRecords = RecentRecords(recentRecords: [RecentRecord]())
    @State var date: Date = Date()
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 40) {
                
                // MARK: - 달력 섹션
                VStack(alignment: .leading, spacing: 16) {
                    Text("날짜 선택")
                        .font(.title3)
                        .bold()
                        .padding(.horizontal)
                    
                    DatePicker(selection: $date, displayedComponents: [.date]) {
                        EmptyView()
                    }
                    .datePickerStyle(.graphical)
                    .padding(.horizontal)
                    
                    HStack {
                        Spacer()
                        NavigationLink(destination: SpecificDateDetails(selectedDate: date)) {
                            Text("해당 날짜 상세 내역 보기")
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                        .id(date)
                        .padding(.trailing, 20)
                    }
                }
                
                Divider()
                    .padding(.horizontal)
                
                // MARK: - 최근 기록 섹션
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("최근 기입한 내역")
                            .font(.title2)
                            .bold()
                        Spacer()
                        NavigationLink(destination: addConsumeIncome()) { // 소비/수입 추가 버튼
                            Text("소비/수입 추가하러 가기")
                                .font(.callout)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.horizontal)
                    
                    // 리스트형 표 스타일
                    VStack(spacing: 0) {
                        // 헤더
                        HStack {
                            Text("유형").frame(width: 50, alignment: .leading)
                            Text("내역").frame(maxWidth: .infinity, alignment: .leading)
                            Text("편집일").frame(width: 130, alignment: .trailing)
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        // 내용
                        ForEach(recentRecords.recentRecords, id: \.incomeConsumePK) { record in
                            RecentRecordItem(recentRecordData: record)
                            Divider()
                        }
                    }
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .gray.opacity(0.2), radius: 2, x: 0, y: 1)
                    .padding(.horizontal)
                }
                .onAppear {
                    loadRecentRecords()
                }
            }
            .padding(.vertical, 20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("오늘의 소비")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink(destination: AlarmView()) {
                    Image(systemName: "bell.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
            }
        }
    }
    
    // MARK: - 데이터 로드
    private func loadRecentRecords() {
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryRecentAct.php") else {
            print("url error")
            return
        }
        let body = "userId=\(userId)"
        let encodedData = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encodedData
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                print("error: \(error)")
                return
            }
            guard let data = data else { return }
            do {
                let decoder = JSONDecoder()
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                decoder.dateDecodingStrategy = .formatted(formatter)
                
                let jsonRecentRecordData = try decoder.decode(RecentRecords.self, from: data)
                DispatchQueue.main.async {
                    recentRecords = jsonRecentRecordData
                }
            } catch {
                print("❌ 디코딩 실패:", error)
                print(String(decoding: data, as: UTF8.self))
            }
        }.resume()
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()

private let dateFormatterFull: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm"
    return formatter
}()
