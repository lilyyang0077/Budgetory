import SwiftUI

struct LoginView: View {
    @State private var id: String = ""
    @State private var pwd: String = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var goMain = false   // 성공 시 메인 탭으로
    
    
    var body: some View {
        VStack(spacing: 40) {
            VStack(spacing: 10) {
                Image(systemName: "wallet.pass")
                    .resizable().scaledToFit().frame(width: 80, height: 80)
                    .foregroundColor(.blue)
                Text("Budgetory").font(.largeTitle).bold()
            }
            .padding(.top, 60)

            VStack(spacing: 20) {
                TextField("아이디 입력", text: $id)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                //UserDefaults.standard.set(id, forKey: "id")
                SecureField("비밀번호 입력", text: $pwd)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
            }
            .padding(.horizontal, 30)

            if let message = errorMessage {
                Text(message)
                    .foregroundColor(.red)
                    .font(.callout)
                    .padding(.horizontal, 30)
                    .transition(.opacity)
            }

            // 로그인 버튼
            Button {
                login()
            } label: {
                HStack {
                    if isLoading { ProgressView() }
                    Text(isLoading ? "로그인 중..." : "로그인").bold()
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(isLoading ? Color.gray : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
                .shadow(radius: 5)
            }
            .disabled(isLoading || id.isEmpty || pwd.isEmpty)
            .padding(.horizontal, 30)

            // 회원가입으로 가는 일반 NavigationLink
            HStack {
                Text("계정이 없으신가요?").foregroundColor(.gray)
                NavigationLink("회원가입") {
                    SignupView()
                }
                .foregroundColor(.blue).bold()
            }

            // 숨김 NavigationLink: 로그인 성공 시 자동 이동
            NavigationLink("", destination: TabbarView(), isActive: $goMain)
                .hidden()

            Spacer()
        }
        .padding(.bottom, 24)
        .navigationTitle("로그인")
    }

    private func login() {
        errorMessage = nil
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryLogin.php") else {
            errorMessage = "URL이 올바르지 않습니다."
            return
        }

        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "pwd", value: pwd)
        ]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)

        isLoading = true
        URLSession.shared.dataTask(with: request) { data, _, error in
            DispatchQueue.main.async {
                isLoading = false
                if let error = error { errorMessage = "네트워크 오류: \(error.localizedDescription)"; return }
                guard let data = data else { errorMessage = "응답 데이터가 없습니다."; return }

                let str = String(decoding: data, as: UTF8.self)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if str == "1" {
                    goMain = true       // 자동 네비게이션
                    UserDefaults.standard.set(id, forKey: "LoginId")
                } else {
                    errorMessage = "아이디 혹은 비밀번호가 잘못되었습니다."
                }
            }
        }.resume()
    }
}

#Preview {
    NavigationStack { LoginView() }
}

