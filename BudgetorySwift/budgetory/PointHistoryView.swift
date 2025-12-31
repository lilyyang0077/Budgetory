import SwiftUI

struct PointActivity: Codable {
    var pointActivityPK: Int = 0
    var point: Int = 0
    var pointType: Int = 0
    var pointDate: Date = Date()
}

struct PointActivityItem: View {
    @State var pointActivityData: PointActivity
    
    // pointType에 따라 문구 결정. db에 저장된 거에 따라 달라짐 주의!!(Point 테이블은 DB 통일해야 할 듯.)
    var pointDescription: String {
        switch pointActivityData.pointType {
        case 5:
            return "웰컴 포인트에요!"
        case 6:
            return "소비 일기를 작성하였습니다."
        case 7:
            return "예산 내에서 소비를 했어요!"
        default:
            return "아이템을 구매했어요"
        }
    }
    
    // 포인트 색상 및 부호 결정
    var pointColor: Color {
        switch pointActivityData.pointType {
        case 5,6,7:
            return .yellow
        default:
            return .red
        }
    }
    
    var pointPrefix: String {
        switch pointActivityData.pointType {
        case 5,6,7:
            return "+"
        default:
            return ""//포인트가 차감되는 경우 이미 수에 -가 붙어 있음. 그래서 prefix로 부호 리턴 안 함.
        }
    }
    
    
    var formattedDateTime: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy/MM/dd"
        let datePart = f.string(from: pointActivityData.pointDate)

        f.dateFormat = "HH:mm"
        let timePart = f.string(from: pointActivityData.pointDate)

        return "\(datePart)\n\(timePart)"
    }

    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(pointPrefix)\(pointActivityData.point)P")
                    .font(.title3)
                    .bold()
                    .foregroundColor(pointColor)
                Spacer()
                Text(formattedDateTime)       // ← 날짜 + 시간
                    .font(.caption)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.trailing)
            }
            Text(pointDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 6)
    }
}

struct PointActivities: Codable {
    var pointActivities: [PointActivity]
}

struct PointHistoryView: View {
    @State var pointActivities: PointActivities = PointActivities(pointActivities: [PointActivity]())
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    
    var body: some View {
        VStack {
            Text("포인트 내역 페이지")
                .font(.title3)
                .bold()
                .padding(.bottom, 10)
            
            if pointActivities.pointActivities.isEmpty{
                Text("포인트 내역이 없습니다.\n 활동을 통해 포인트를 받아보세요!")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            else{
                List(pointActivities.pointActivities, id: \.pointActivityPK) { contents in
                    PointActivityItem(pointActivityData: contents)
                }
            }
        }
        .padding(.top, 30)
        .onAppear {
            guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryPointActivity.php") else {
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
                
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .formatted({
                    let f = DateFormatter()
                    f.dateFormat = "yyyy-MM-dd HH:mm:ss"
                    return f
                }())
                
                do {
                    let jsonData = try decoder.decode(PointActivities.self, from: data)
                    DispatchQueue.main.async {
                        pointActivities = jsonData
                    }
                } catch {
                    print("디코딩 실패:", error)
                    print(String(decoding: data, as: UTF8.self))
                }
            }.resume()
        }
    }
}

#Preview {
    PointHistoryView()
}
