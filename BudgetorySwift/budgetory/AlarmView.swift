import SwiftUI

private let baseURL = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP")!

struct AlarmDTO: Codable, Identifiable {
    let alarmPK: Int
    let categoryName: String
    let month: String
    let totalExpense: Int
    let budgetPrice: Int
    var isRead: Int
    let createdAt: String
    var id: Int { alarmPK }
}

// MARK: API
func fetchAlarms(userId: String) async throws -> [AlarmDTO] {
    var c = URLComponents(url: baseURL.appending(path: "BudgetoryAlarmList.php"), resolvingAgainstBaseURL: false)!
    c.queryItems = [.init(name: "userId", value: userId)]
    let (data, _) = try await URLSession.shared.data(from: c.url!)
    return try JSONDecoder().decode([AlarmDTO].self, from: data)
}

func generateAlarms(userId: String) async throws {
    var c = URLComponents(url: baseURL.appending(path: "BudgetoryAlarmGenerate.php"), resolvingAgainstBaseURL: false)!
    c.queryItems = [URLQueryItem(name: "userId", value: userId)]
    let (_, resp) = try await URLSession.shared.data(from: c.url!)
    guard let http = resp as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
        throw URLError(.badServerResponse)
    }
}

func markAlarmRead(alarmPK: Int) async throws {
    var r = URLRequest(url: baseURL.appending(path: "BudgetoryAlarmMarkRead.php"))
    r.httpMethod = "POST"
    r.httpBody = "alarmPK=\(alarmPK)".data(using: .utf8)
    _ = try await URLSession.shared.data(for: r)
}

// MARK: View
struct AlarmView: View {
    @State private var alarms: [AlarmDTO] = []
    @State private var errorMsg: String?
    private let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""

    var body: some View {
        NavigationStack {
            List {
                ForEach(alarms.filter { $0.isRead == 0 || $0.isRead == 1 }) { a in
                    VStack(alignment:.leading) {
                        Text("[\(a.categoryName)]").bold()
                        Text("예산 초과 \(a.totalExpense) / \(a.budgetPrice)")
                        Text(a.createdAt).font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(8)
                    .background(a.isRead == 1 ? Color.gray.opacity(0.2) : Color.white)
                    .cornerRadius(8)
                    .onTapGesture {
                        markAsRead(a)
                    }
                }
            }
            .navigationTitle("예산 알림")
            .task { await load() }
            .alert("오류", isPresented: .constant(errorMsg != nil)) {
                Button("확인") { errorMsg = nil }
            } message: { Text(errorMsg ?? "") }
        }
    }

    // 클릭 시 읽음 처리
    func markAsRead(_ alarm: AlarmDTO) {
        guard let index = alarms.firstIndex(where: { $0.id == alarm.id }) else { return }
        alarms[index].isRead = 1 // UI 색상 반영
        Task {
            try? await markAlarmRead(alarmPK: alarm.alarmPK)
        }
    }

    // 로드: 알람 생성 후 가져오기
    func load() async {
        guard !userId.isEmpty else { return }
        do {
            try await generateAlarms(userId: userId) // 서버 갱신
            alarms = try await fetchAlarms(userId: userId) // 최신 알람 가져오기
        } catch {
            errorMsg = "알람 로드 실패"
        }
    }
}
