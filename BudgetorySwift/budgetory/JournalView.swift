import SwiftUI

struct Journal: Codable {
    var journalPK: Int
    var title: String?
    var contents: String?
    var journalDate: Date = Date()
}

struct JournalItem: View {
    var journal: Journal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            // 제목 + 날짜
            HStack {
                Text(journal.title ?? "제목 없음")
                    .font(.headline)
                    .foregroundColor(.primary)

                Spacer()

                Text(journal.journalDate, formatter: dateFormatter)
                    .font(.caption)
                    .foregroundColor(.gray)
            }

            // 내용
            Text(journal.contents ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
        .frame(minHeight: 140)
        .background(
            ZStack {
                // 배경색
                Color(red: 1.0, green: 0.99, blue: 0.93)

                // 가로줄
                VStack(spacing: 26) {
                    ForEach(0..<5) { _ in
                        Rectangle()
                            .fill(Color.blue.opacity(0.08))
                            .frame(height: 1)
                    }
                }
                .padding(.top, 18)
            }
        )
        .overlay(
            // 왼쪽 붉은 세로줄
            Rectangle()
                .fill(Color.red.opacity(0.35))
                .frame(width: 1)
                .padding(.leading, 10),
            alignment: .leading
        )
        .cornerRadius(2)
        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 3)
        .padding(.vertical, 6)
    }
}




struct Journals: Codable {
    var journals: [Journal]
}


struct JournalView: View {
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    @State var journals: Journals = Journals(journals: [])

    var body: some View {
            NavigationStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {

                        // 제목
                        Text("소비 일기✏️")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .padding(.top, 10)

                        // 설명
                        Text("충동적 소비를 한 날의 일기를 작성하며 자신의 소비를 되돌아 보아요!")
                            .font(.subheadline)
                            .foregroundColor(.gray)

                        // 글쓰기 버튼
                        NavigationLink(destination: JournalDateChoose()) {
                            Text("글쓰기")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        .padding(.vertical, 10)

                        // 카드 리스트
                        VStack(spacing: 12) {
                            ForEach(journals.journals, id: \.journalPK) { journal in
                                NavigationLink(destination: JournalDetailView(journal: journal)) {
                                    JournalItem(journal: journal)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                }
                .background(Color(red: 0.97, green: 0.99, blue: 1.0)
)
                .navigationTitle("소비일기")
                .navigationBarTitleDisplayMode(.inline)
                .onAppear {
                    loadJournalList()
                }
            }
        }

    func loadJournalList() {
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryJournalList.php") else {
            print("url error")
            return
        }

        let body = "userId=\(userId)"
        let encodedData = body.data(using: .utf8)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encodedData

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("error: \(error)")
                return
            }
            guard let data = data else { return }

            print(String(decoding: data, as: UTF8.self))

            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            decoder.dateDecodingStrategy = .formatted(formatter)

            if let decoded = try? decoder.decode(Journals.self, from: data) {
                DispatchQueue.main.async {
                    journals = decoded
                }
            }
        }.resume()
    }
}


#Preview {
    JournalView()
}


// 날짜 표시용 포매터
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
