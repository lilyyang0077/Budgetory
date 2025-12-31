import SwiftUI
import Charts

//월 별 막대 그래프
struct ChartBar: Codable, Identifiable {
    let id = UUID()
    let month: String
    let total: Int
    
}
//주 별 막대 그래프
struct ChartWeeklyBar: Codable, Identifiable {
    let id = UUID()
    let week_start: String
    let total: Int
    
    
}
//주 별 막대 그래프 날짜 포멧 정의하는 부분
extension ChartWeeklyBar {
    var weekRangeLabel: String {
        // "2025-11-23" → Date 변환
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: week_start) else { return week_start }

        let calendar = Calendar.current
        let endDate = calendar.date(byAdding: .day, value: 6, to: date)!

        let out = DateFormatter()
        out.dateFormat = "MM.dd"

        return "\(out.string(from: date)) ~ \(out.string(from: endDate))"
    }
}

struct CategoryMonthStatic: Codable, Identifiable {
    let id = UUID()
    let categoryPK: Int
    let categoryName: String
    let tagColorPK: Int
    let amount: Int
}
struct CategoryWeekStatic: Codable, Identifiable {
    let id = UUID()
    let categoryPK: Int
    let categoryName: String
    let tagColorPK: Int
    let amount: Int
}

struct ChartResponse: Codable {
    let monthlyTotals: [ChartBar]
}
struct ChartWeeklyResponse: Codable {
    let weeklyTotals: [ChartWeeklyBar]
}
struct CategoryMonthResponse: Codable {
    let CategoryMonthStatics: [CategoryMonthStatic]
}
struct CategoryWeekResponse: Codable {
    let CategoryWeekStatics: [CategoryWeekStatic]
}


func fetchChartData() async throws -> [ChartBar] {
    guard let url = URL(string: "https://yourserver/endpoint.php?userId=...") else { throw URLError(.badURL) }
    let (data, _) = try await URLSession.shared.data(from: url)
    let decoder = JSONDecoder()
    return try decoder.decode([ChartBar].self, from: data)
}


struct StaticsView: View {
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    @State var chartData: [ChartBar] = []
    @State var chartWeeklyData: [ChartWeeklyBar] = []
    @State private var selectedType: String = "월간"  // 현재 선택 상태
    
    @State private var selectedMonth: String = StaticsView.getCurrentMonth() // "202511"
    @State private var selectedWeekDate: Date = StaticsView.getCurrentWeek()
    @State private var categoryMonthStatics: [CategoryMonthStatic] = []
    @State private var categoryWeekStatics: [CategoryWeekStatic] = []
    @State private var isLoading: Bool = false
    
    @State private var allWeekly: [ChartWeeklyBar] = []
    @State private var currentIndex: Int = 0
    
    
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {

                // 제목
                Text("📊 소비 통계")
                    .font(.title2.bold())
                    .padding(.top, 8)

                // 월간 / 주간 토글
                HStack(spacing: 0) {

                    Button(action: {
                        selectedType = "월간"
                        loadChart()
                        fetchCategoryMonth(month: selectedMonth)
                    }) {
                        Text("월간")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedType == "월간" ? Color.blue.opacity(0.85) : Color.gray.opacity(0.15))
                            .foregroundColor(selectedType == "월간" ? .white : .black)
                    }

                    Button(action: {
                        selectedType = "주간"
                        let weekString = dateToServerString(selectedWeekDate)
                        loadWeeklyChart()
                        fetchCategoryWeek(week: weekString)
                    }) {
                        Text("주간")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(selectedType == "주간" ? Color.blue.opacity(0.85) : Color.gray.opacity(0.15))
                            .foregroundColor(selectedType == "주간" ? .white : .black)
                    }
                }
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(radius: 2)
                .onAppear {
                    loadChart()
                    loadWeeklyChart()
                }

                // 막대 그래프
                Group {
                    if selectedType == "월간" {
                        StatisticsGraphView(data: chartData)
                            .frame(height: 240)
                    } else {
                        StatisticsWeeklyGraphView(
                            data: currentSlice,
                            onSwipeLeft: { nextPage() },
                            onSwipeRight: { prevPage() }
                        )
                        .frame(height: 240)
                    }
                }
                .padding(.horizontal)

                Divider().padding(.horizontal)

                // 월/주 표시 + 이전/다음 버튼
                HStack {
                    Button(action: {
                        selectedType == "월간" ? moveMonth(-1) : moveWeek(-1)
                    }) {
                        Image(systemName: "chevron.left")
                    }

                    Spacer()

                    Text(
                        selectedType == "월간"
                        ? formatMonthText(selectedMonth)
                        : formatWeekRange(selectedWeekDate)
                    )
                    .font(.title3.bold())

                    Spacer()

                    Button(action: {
                        selectedType == "월간" ? moveMonth(1) : moveWeek(1)
                    }) {
                        Image(systemName: "chevron.right")
                    }
                }
                .padding(.horizontal)

                // 카테고리 가로 스택 바
                VStack(alignment: .leading, spacing: 12) {
                    if isLoading {
                        ProgressView("불러오는 중...")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 30)
                    } else {
                        if selectedType == "월간" {
                            StackBarView(data: categoryMonthStatics)
                        } else {
                            StackWeeklyBarView(data: categoryWeekStatics)
                        }
                    }
                }
                .padding(.horizontal)

                Spacer(minLength: 20)
            }
        }
    }

    //달 별 막대 그래프에 대한 데이터를 php로부터 받는 코드
    func loadChart() {
        print("📌 데이터 요청 시작")
        
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryStaticsMonthly.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "userId=\(userId)".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }
            
            print("📌 서버 응답:", String(decoding: data, as: UTF8.self))
            
            let decoder = JSONDecoder()
            
            if let decoded = try? decoder.decode(ChartResponse.self, from: data) {
                DispatchQueue.main.async {
                    chartData = decoded.monthlyTotals
                    print("📌 디코딩 성공 → 총 \(chartData.count)개")
                }
            } else {
                print("⛔ 합계 디코딩 실패!")
            }
            
        }.resume()
    }
    
    //주 별 막대 그래프에 대한 JSON을 php로부터 받는 코드
    func loadWeeklyChart() {
        print("📌 주간 데이터 요청 시작")

        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryStaticsWeekly.php") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = "userId=\(userId)".data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        URLSession.shared.dataTask(with: request) { data, _, _ in
            guard let data = data else { return }

            print("📌 서버 응답:", String(decoding: data, as: UTF8.self))

            let decoder = JSONDecoder()

            if let decoded = try? decoder.decode(ChartWeeklyResponse.self, from: data) {
                DispatchQueue.main.async {
                    allWeekly = decoded.weeklyTotals
                    chartWeeklyData = decoded.weeklyTotals

                    currentIndex = 0
                    print("📌 주간 통계 디코딩 성공 → \(chartWeeklyData.count)개")
                }
            } else {
                print("⛔ 주간 통계 디코딩 실패!")
            }

        }.resume()
    }

    
    //월 별 가로 그래프(카테고리별) 데이터 php로부터 받아오기
    func fetchCategoryMonth(month: String) {
        isLoading = true
        
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/MonthCategoryStatics.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body = "userId=\(userId)&lookingMonth=\(month)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
            }
            
            guard let data = data else { return }
            print("📌 서버 응답:", String(decoding: data, as: UTF8.self))
            
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(CategoryMonthResponse.self, from: data) {
                DispatchQueue.main.async {
                    categoryMonthStatics = decoded.CategoryMonthStatics
                }
            } else {
                print("⛔ 카테고리 디코딩 실패!")
            }
            
        }.resume()
    }
    //주 별 가로 그래프(카테고리별) 데이터 php로부터 받아오기
    func fetchCategoryWeek(week: String) {
        isLoading = true
        
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/WeekCategoryStatics.php") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let body = "userId=\(userId)&lookingWeek=\(week)"
        request.httpBody = body.data(using: .utf8)
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { data, _, _ in
            DispatchQueue.main.async {
                isLoading = false
            }
            
            guard let data = data else { return }
            print("📌 서버 응답:", String(decoding: data, as: UTF8.self))
            
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(CategoryWeekResponse.self, from: data) {
                DispatchQueue.main.async {
                    categoryWeekStatics = decoded.CategoryWeekStatics
                }
            } else {
                print("⛔ 카테고리 디코딩 실패!")
            }
            
        }.resume()
    }
    
    /// 현재 달 (YYYYMM) 반환
    static func getCurrentMonth() -> String {
        let now = Date()
        let f = DateFormatter()
        f.dateFormat = "yyyyMM"
        return f.string(from: now)
    }
    // 현재 주(YYYYMM) 반환
    static func getCurrentWeek() -> Date {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // ✅ 월요일 시작

        // 현재 날짜 기준 주의 월요일 구하기
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)

        // weekday: 2(월) ~ 8(일)이므로 월요일을 기준으로 조정
        let offset = (weekday == 1) ? -6 : (2 - weekday)

        return calendar.date(byAdding: .day, value: offset, to: today)!
    }

    
    func dateToServerString(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    func formatWeekRange(_ monday: Date) -> String {
        let calendar = Calendar.current
        let sunday = calendar.date(byAdding: .day, value: 6, to: monday)!

        let f = DateFormatter()
        f.dateFormat = "MM.dd"

        return "\(f.string(from: monday)) ~ \(f.string(from: sunday))"
    }



    
    /// YYYYMM → "2025년 11월" 포맷 변환
    func formatMonthText(_ m: String) -> String {
        guard m.count == 6 else { return m }
        let year = String(m.prefix(4))
        let month = String(m.suffix(2))
        return "\(year)년 \(Int(month)!)월"
    }
    
    /// 이전 / 다음 달 이동
    func moveMonth(_ offset: Int) {
        guard let date = monthToDate(selectedMonth) else { return }
        if let moved = Calendar.current.date(byAdding: .month, value: offset, to: date) {
            selectedMonth = dateToYYYYMM(moved)
            fetchCategoryMonth(month: selectedMonth)
        }
    }
    /// 이전 / 다음 주 이동
    func moveWeek(_ offset: Int) {
        let calendar = Calendar.current
        let moved = calendar.date(byAdding: .day, value: offset * 7, to: selectedWeekDate)!

        selectedWeekDate = moved
        let serverWeek = dateToServerString(moved)

        fetchCategoryWeek(week: serverWeek)
        loadWeeklyChart()
    }

    
    /// YYYYMM → Date
    func monthToDate(_ yyyymm: String) -> Date? {
        let f = DateFormatter()
        f.dateFormat = "yyyyMM"
        return f.date(from: yyyymm)
    }
    
    /// Date → yyyyMM
    func dateToYYYYMM(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMM"
        return f.string(from: date)
    }
    
    
    
    
}
extension StaticsView {
    var currentSlice: [ChartWeeklyBar] {
        let start = currentIndex
        let end = min(start + 4, allWeekly.count)
        return Array(allWeekly[start..<end])
    }

    func nextPage() {
        if currentIndex + 4 < allWeekly.count {
            currentIndex += 4
        }
    }

    func prevPage() {
        if currentIndex > 0 {
            currentIndex -= 4
        }
    }

}


#Preview {
    StaticsView()
}
