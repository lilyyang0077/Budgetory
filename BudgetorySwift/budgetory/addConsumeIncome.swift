import SwiftUI


struct UsersCategory: Codable {
    var categoryPK: Int
    var categoryName: String
    var tagColorPK: Int
    
}
struct UsersCategoryItem: View {
    @State var usersCategoryData : UsersCategory
    var body: some View {
        HStack{
            Text(usersCategoryData.categoryName)
        }
    }
}

struct UsersCategories: Codable {
    var UsersCategory: [UsersCategory]
}


struct addConsumeIncome: View {
    @State private var selectedType: String = "소비"  // 현재 선택 상태
    @State private var consumeIncomeAt: Date = Date()
    @State private var dateString: String = ""
    @State private var consumeIncomeAmount: String = ""
    @State private var consumeIncomeComment: String = ""
    @State private var consumeIncomeMemo: String = ""
    @State private var selectedCategory: String = "선택하세요"
    @State private var impulseCheck: Bool = false
    @State var isSucceedCI: Bool = false
    @State var errorMessage: String?
    @Environment(\.dismiss) private var dismiss
    
    //현재 로그인 되어 있는 user의 id.
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    
    @State var usersCategories: UsersCategories = UsersCategories(UsersCategory: [])
    let categories = ["식비", "교통비", "쇼핑", "문화생활", "기타"] //
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                // 상단 토글형 선택 영역
                HStack(spacing: 0) {
                    Button(action: {
                        selectedType = "소비"
                    }) {
                        Text("소비")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == "소비" ? Color.blue.opacity(0.8) : Color.gray.opacity(0.15))
                            .foregroundColor(selectedType == "소비" ? .white : .black)
                    }
                    
                    Button(action: {
                        selectedType = "수입"
                    }) {
                        Text("수입")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(selectedType == "수입" ? Color.blue.opacity(0.8) : Color.gray.opacity(0.15))
                            .foregroundColor(selectedType == "수입" ? .white : .black)
                    }
                    
                }
                .cornerRadius(12)
                .padding(.horizontal)
                .shadow(radius: 3)
                
                
                // 날짜 선택
                HStack() {
                    Text("날짜")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.leading)
                        .padding(.leading, 20)
                    Spacer()
                    DatePicker(selection: $consumeIncomeAt, label: {})
                }
                .datePickerStyle(.compact)
                .padding(.trailing, 20)
                
                Divider()
                
                // 카테고리 선택
                VStack(alignment: .leading, spacing: 8) {
                    Text("카테고리")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    Menu {
                        ForEach(usersCategories.UsersCategory, id: \.categoryPK) { category in
                            Button(category.categoryName) {
                                selectedCategory = category.categoryName
                            }
                        }
                    } label: {
                        HStack {
                            Text(selectedCategory)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .foregroundColor(.gray)
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                }
                .padding(.horizontal)
                
                Divider()
                
                // 금액 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("금액")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("0", text: $consumeIncomeAmount)
                        .keyboardType(.numberPad)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                
                // 내역명 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("내역명")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("내역명을 입력하세요", text: $consumeIncomeComment)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                Divider()
                //impulseCheck 부분
                HStack {
                    
                    Button(action: {
                        impulseCheck.toggle()
                        print("impulseCheck =", impulseCheck)//콘솔 확인용
                    }) {
                        HStack {
                            Image(systemName: impulseCheck ? "checkmark.square.fill" : "square")
                                .foregroundColor(impulseCheck ? .blue : .gray)
                            Text("충동")
                                .foregroundColor(.primary)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text("소비가 충동적이었다면 해당 소비와 관련된 충동 소비 일기를 작성할 수 있어요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                Divider()
                // 메모 입력
                VStack(alignment: .leading, spacing: 8) {
                    Text("메모")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                    TextField("메모를 입력하세요", text: $consumeIncomeMemo, axis: .vertical)
                        .lineLimit(4, reservesSpace: true)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                
                //필수 항목 누락 시 에러 메시지 뜨기.
                if let e = errorMessage {
                    Text(e).foregroundColor(.red).font(.callout)
                }
                
                NavigationLink(destination: TabbarView(), isActive: $isSucceedCI, label: {})
                // “추가하기” 버튼
                Button{
                    guard let url=URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryAddCI.php")
                    else{
                        print("url error")
                        return
                    }
                    let calendar = Calendar.current
                    let dateWithZeroSeconds = calendar.date(bySetting: .second, value: 0, of: consumeIncomeAt)!
                    let dateString = dateFormatter.string(from: consumeIncomeAt)
                    let body="selectedType=\(selectedType)&consumeIncomeDate=\(dateString)&selectedCategory=\(selectedCategory)&consumeIncomeAmount=\(consumeIncomeAmount)&consumeIncomeComment=\(consumeIncomeComment)&consumeIncomeMemo=\(consumeIncomeMemo)&impulseCheck=\(impulseCheck)&userId=\(userId)"
                    let encodedData=body.data(using: String.Encoding.utf8)
                    
                    var request=URLRequest(url: url)
                    request.httpMethod="POST"
                    request.httpBody=encodedData
                    
                    URLSession.shared.dataTask(with: request) { (data, response, error) in
                        if let error=error{
                            print("error: \(error)")
                            return
                        }
                        guard let data=data else{
                            return
                        }
                        
                        let str = String(decoding: data, as: UTF8.self)
                        
                        print("data ? \(str)")
                        if str == "1" {
                            print("소비/수입 내역 추가 성공")
                            
                            // 알람 서버 갱신 호출
                            guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryAlarmGenerate.php?userId=\(userId)") else { return }
                            URLSession.shared.dataTask(with: url) { data, response, error in
                                if let error = error {
                                    print("알람 갱신 실패: \(error)")
                                } else {
                                    print("알람 갱신 완료")
                                }
                            }.resume()
                            
                            DispatchQueue.main.async { isSucceedCI = true }
                        }
                        else{
                            print("소비/수입 내역 추가 실패")
                            errorMessage = "필수 항목이 누락되었습니다."
                        }
                    }.resume()
                    
                } label: {
                    Text("추가하기")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.9))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
                .padding(.top, 10)
            }
            .padding(.vertical)
            .onAppear { loadCategory() }
        }
        .navigationTitle("소비 / 수입 추가하기")
        .navigationBarTitleDisplayMode(.inline)
    }
    // 데이터 불러오는 부분.
    func loadCategory() {
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/GetCategory.php") else {
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
            
            print("data ? \(String(decoding: data, as: UTF8.self))")
            
            let decoder = JSONDecoder()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            decoder.dateDecodingStrategy = .formatted(formatter)
            
            if let jsonUserCategoryData = try? decoder.decode(UsersCategories.self, from: data) {
                DispatchQueue.main.async {
                    usersCategories = jsonUserCategoryData
                }
            }
        }.resume()
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    return formatter
}()

#Preview {
    addConsumeIncome()
}
