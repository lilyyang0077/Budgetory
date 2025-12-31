import SwiftUI

private func colorFromPK(_ pk: Int) -> Color {
    switch pk {
    case 1: return .red
    case 2: return .orange
    case 3: return .yellow
    case 4: return .green
    case 5: return .blue
    case 6: return .indigo
    case 7: return .purple
    default: return .gray
    }
}

struct CategoryAddition: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var selectedColorPK: Int = 1
    @State private var budgetText: String = ""
    
    @State private var isSubmitting = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // 현재 로그인한 사용자의 id (문자열)
    private var userId: String {
        UserDefaults.standard.string(forKey: "LoginId") ?? ""
    }
    
    // MARK: - 유효성 체크
    private var budgetValue: Int? {
        let cleaned = budgetText
            .replacingOccurrences(of: ",", with: "")
            .replacingOccurrences(of: " ", with: "")
        return Int(cleaned)
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        (budgetValue ?? 0) > 0
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                
                VStack(alignment: .leading, spacing: 18) {
                    // 카테고리 이름
                    VStack(alignment: .leading, spacing: 8) {
                        Text("카테고리 명")
                            .font(.headline)
                        TextField("예: 식비, 교통, 커피", text: $name)
                            .textFieldStyle(.roundedBorder)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled(true)
                    }
                    
                    // 색상 선택
                    VStack(alignment: .leading, spacing: 8) {
                        Text("태그 색상")
                            .font(.headline)
                        colorPickerRow
                    }
                    
                    // 예산 금액
                    VStack(alignment: .leading, spacing: 8) {
                        Text("예산 금액")
                            .font(.headline)
                        HStack {
                            TextField("금액 입력", text: $budgetText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                                .onChange(of: budgetText) { _, new in
                                    // 숫자/쉼표만 허용
                                    let filtered = new.filter { "0123456789,".contains($0) }
                                    if filtered != new { budgetText = filtered }
                                }
                            Text("원")
                                .foregroundColor(.gray)
                        }
                        Text("예: 150000")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                }
                .padding(16)
                .background(.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
                
                // 추가 버튼
                Button(action: categoryAdd) {
                    HStack {
                        if isSubmitting {
                            ProgressView()
                                .padding(.trailing, 6)
                        }
                        Text(isSubmitting ? "추가 중…" : "추가하기")
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isFormValid && !isSubmitting ? Color.blue : Color.gray.opacity(0.5))
                    .foregroundColor(.white)
                    .cornerRadius(14)
                }
                .disabled(!isFormValid || isSubmitting)
                .padding(.top, 8)
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .alert("알림", isPresented: $showAlert) {
            Button("확인", role: .cancel) { }
        } message: { Text(alertMessage) }
        .background(
            LinearGradient(colors: [Color.blue.opacity(0.12), .white],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
    }
    
    // MARK: - 헤더
    private var header: some View {
        VStack(spacing: 6) {
            Image(systemName: "folder.badge.plus")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)
                .foregroundColor(.blue)
            Text("새 카테고리 만들기")
                .font(.title2).bold()
        }
        .padding(.top, 10)
    }
    
    // MARK: - 색상 선택
    private var colorPickerRow: some View {
        HStack(spacing: 14) {
            ForEach(1...7, id: \.self) { pk in
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        selectedColorPK = pk
                    }
                } label: {
                    Circle()
                        .fill(colorFromPK(pk))
                        .frame(width: selectedColorPK == pk ? 44 : 36,
                               height: selectedColorPK == pk ? 44 : 36)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: selectedColorPK == pk ? 4 : 0)
                                .shadow(color: .black.opacity(selectedColorPK == pk ? 0.25 : 0),
                                        radius: selectedColorPK == pk ? 3 : 0, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - 네트워크 요청
    private func categoryAdd() {
        guard isFormValid, let budget = budgetValue else {
            alertMessage = "카테고리명과 예산 금액을 확인하세요."
            showAlert = true
            return
        }
        
        guard !userId.isEmpty else {
            alertMessage = "로그인 정보가 없습니다."
            showAlert = true
            return
        }
        
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryCategoryAdd.php") else {
            alertMessage = "URL 오류"
            showAlert = true
            return
        }
        
        isSubmitting = true
        
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "userId", value: userId),  // 문자열 id 전송
            URLQueryItem(name: "categoryName", value: name.trimmingCharacters(in: .whitespacesAndNewlines)),
            URLQueryItem(name: "tagColorPK", value: String(selectedColorPK)),  // 1~7 숫자
            URLQueryItem(name: "budgetPrice", value: String(budget))
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isSubmitting = false
                
                if let error = error {
                    alertMessage = error.localizedDescription
                    showAlert = true
                    return
                }
                guard let data = data else {
                    alertMessage = "응답이 없습니다."
                    showAlert = true
                    return
                }
                
                let str = String(decoding: data, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if str == "1" {
                    alertMessage = "새 카테고리가 추가되었습니다."
                    showAlert = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        dismiss()
                    }
                } else {
                    alertMessage = "등록에 실패했습니다. 필수 항목을 확인해주세요."
                    showAlert = true
                }
            }
        }.resume()
    }
}
