import SwiftUI

struct UserProfile: View {
    let userId: String      // 로그인 ID
    
    // 서버에서 받아온 원본 데이터
    let originalFirstName: String
    let originalLastName: String
    let originalGender: Int     // 0,1,2
    let originalBirth: String   // YYYY-MM-DD
    
    // 수정 가능한 값들
    @State private var editedFullName: String = ""
    @State private var editedGender: Int = 0
    @State private var editedBirth: Date = Date()
    @State private var newPassword: String = ""
    
    // 알림
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    @Environment(\.dismiss) private var dismiss   // 시트 닫기
    
    private let baseURL = "http://124.56.5.77/sheep/BudgetoryPHP"
    
    init(userId: String, firstName: String, lastName: String, gender: Int, birth: String) {
        self.userId = userId
        self.originalFirstName = firstName
        self.originalLastName = lastName
        self.originalGender = gender
        self.originalBirth = birth
        
        _editedFullName = State(initialValue: "\(lastName) \(firstName)")
        _editedGender = State(initialValue: gender)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        _editedBirth = State(initialValue: formatter.date(from: birth) ?? Date())
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                
                Text("내 정보 수정")
                    .font(.title2).bold()
                    .padding(.top, 24)
                
                // 이름
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("이름")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        TextField("예: 홍 길동", text: $editedFullName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal, 24)
                
                // 성별
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("성별")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        Picker(selection: $editedGender) {
                            Text("선택 안 함").tag(0)
                            Text("여성").tag(1)
                            Text("남성").tag(2)
                        } label: { EmptyView() }
                        .pickerStyle(.segmented)
                    }
                }
                .padding(.horizontal, 24)
                
                // 생일
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("생일")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        DatePicker(
                            "생일 선택",
                            selection: $editedBirth,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.compact)
                    }
                }
                .padding(.horizontal, 24)
                
                // 비밀번호 변경
                Section {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("새 비밀번호")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                        
                        SecureField("변경 시에만 입력", text: $newPassword)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer().frame(height: 20)
                
                // 저장 버튼
                Button(action: saveChanges) {
                    Text("저장하기")
                        .font(.headline)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 60)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(14)
                }
                .padding(.bottom, 30)
                
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 저장 로직
    private func saveChanges() {
        let full = editedFullName.trimmingCharacters(in: .whitespaces)
        let (first, last) = splitName(full)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let birthString = formatter.string(from: editedBirth)
        
        Task {
            let ok = await updateUser(
                first: first,
                last: last,
                gender: editedGender,
                birth: birthString,
                password: newPassword
            )
            
            await MainActor.run {
                if ok {
                    // 성공 시 바로 시트 닫기
                    dismiss()
                } else {
                    alertMessage = "저장에 실패했습니다."
                    showAlert = true
                }
            }
        }
    }
    
    // "성 이름" → firstname / lastname 분리
    private func splitName(_ full: String) -> (first: String, last: String) {
        let parts = full.split(separator: " ").map { String($0) }
        
        if parts.count >= 2 {
            return (parts.dropFirst().joined(separator: " "), parts.first!)
        } else {
            return (full, "")
        }
    }
    
    // MARK: - 서버로 수정 요청
    private func updateUser(first: String, last: String, gender: Int, birth: String, password: String) async -> Bool {
        
        guard let url = URL(string: "\(baseURL)/BudgetoryUpdateUser.php") else { return false }
        
        var params: [String: String] = [
            "userId": userId,
            "firstName": first,
            "lastName": last,
            "gender": "\(gender)",
            "birth": birth
        ]
        
        if !password.isEmpty {
            params["password"] = password
        }
        
        let body = params
            .map { key, value in
                let encoded = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
                return "\(key)=\(encoded)"
            }
            .joined(separator: "&")
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/x-www-form-urlencoded; charset=utf-8",
                     forHTTPHeaderField: "Content-Type")
        req.httpBody = body.data(using: .utf8)
        
        do {
            let (data, _) = try await URLSession.shared.data(for: req)
            let result = String(decoding: data, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            print("Update 응답:", result)
            return result == "1"
        } catch {
            print("Update 실패:", error.localizedDescription)
            return false
        }
    }
}
