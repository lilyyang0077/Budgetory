import SwiftUI


struct SignupView: View {
    @State var firstName = ""
    @State var lastName = ""
    @State var userId = ""
    @State var password = ""
    @State var birthday = ""
    @State var gender = ""
    @State var message = ""
    
    @State var isRegistered:Bool = false
    @State var errorMessage: String?
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("성", text: $lastName)
                    .textFieldStyle(.roundedBorder)
                TextField("이름", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                TextField("아이디", text: $userId)
                    .textFieldStyle(.roundedBorder)
                SecureField("비밀번호", text: $password)
                    .textFieldStyle(.roundedBorder)
                TextField("생일 (YYYY-MM-DD)", text: $birthday)
                    .textFieldStyle(.roundedBorder)
                TextField("성별", text: $gender)
                    .textFieldStyle(.roundedBorder)
                
                //NavigationLink(destination: LoginView(), isActive: $isRegistered, label: {})
                Button("회원가입 완료") {
                    guard let url=URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetorySignup.php")
                    else{
                        print("url error")
                        return
                    }
                    let body="firstName=\(firstName)&lastName=\(lastName)&userId=\(userId)&password=\(password)&birthday=\(birthday)&gender=\(gender)"
                    
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
                        if str.trimmingCharacters(in: .whitespacesAndNewlines) == "1"{
                            print("회원가입 성공")
                            isRegistered=true
                            DispatchQueue.main.async {
                                dismiss()   // 저장 후 뒤로가기
                            }
                            
                        }
                        else{
                            print("회원가입 실패")
                            errorMessage = "필수항목을 입력하세요."
                        }
                    }.resume()
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                
                Text(message)
                    .foregroundColor(.gray)
            }
            .padding()
            // ✅ 회원가입 성공 시 MainView로 이동
            .navigationTitle("회원가입")
        }
    }
}

#Preview {
    SignupView()
}
