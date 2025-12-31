import SwiftUI

//SwiftUI 타입체크 오류(크기가 커서 타임아웃)가 나서 분리된 구조로 만듦.

struct SettingView: View {
    @State private var showProfile = false
    @State private var showLogoutAlert = false
    @State private var showDeleteAlert = false
    @State private var isNotificationOn = true

    @State private var firstName = ""
    @State private var lastName = ""
    @State private var userId = ""
    @State private var userPassword = ""
    @State private var gender = 0
    @State private var birth = ""

    private let baseURL = "http://124.56.5.77/sheep/BudgetoryPHP"

    var maskedPassword: String {
        String(repeating: "•", count: max(6, userPassword.count))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundView

                VStack(spacing: 24) {
                    HeaderSection()

                    AccountSection(
                        firstName: firstName,
                        lastName: lastName,
                        userId: userId,
                        password: maskedPassword,
                        gender: gender,
                        birth: birth,
                        showProfile: $showProfile
                    )

                    NotificationSection(isNotificationOn: $isNotificationOn)

                    DangerSection(
                        showLogoutAlert: $showLogoutAlert,
                        showDeleteAlert: $showDeleteAlert
                    )

                    Spacer()
                }
                .padding(.top, 16)
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadUserInfo() }
            .alert("로그아웃 하시겠어요?", isPresented: $showLogoutAlert) {
                Button("취소", role: .cancel) {}
                Button("로그아웃", role: .destructive) { logout() }
            }
            .alert("정말 탈퇴하시겠어요?\n모든 데이터가 삭제됩니다.", isPresented: $showDeleteAlert) {
                Button("취소", role: .cancel) {}
                Button("탈퇴", role: .destructive) { deleteAccount() }
            }
            .sheet(isPresented: $showProfile) {
                UserProfile(
                    userId: userId,
                    firstName: firstName,
                    lastName: lastName,
                    gender: gender,
                    birth: birth
                )
            }
        }
    }
}

private var backgroundView: some View {
    LinearGradient(
        colors: [Color.blue.opacity(0.12), .white],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    .ignoresSafeArea()
}

struct HeaderSection: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("계정 설정")
                .font(.largeTitle).bold()
            Text("내 정보와 앱 설정을 관리하세요")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
    }
}

struct AccountSection: View {
    let firstName: String
    let lastName: String
    let userId: String
    let password: String
    let gender: Int
    let birth: String

    @Binding var showProfile: Bool

    var genderText: String {
        switch gender {
        case 1: return "여성"
        case 2: return "남성"
        default: return "선택 안 함"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {

            Text("내 계정")
                .font(.headline)

            infoRow(title: "이름", value: "\(lastName) \(firstName)")
            infoRow(title: "아이디", value: userId)
            infoRow(title: "비밀번호", value: password)
            infoRow(title: "성별", value: genderText)
            infoRow(title: "생년월일", value: birth)

            Button {
                showProfile = true
            } label: {
                Text("내 정보 수정 / 확인")
                    .font(.subheadline).bold()
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue.opacity(0.15))
                    .foregroundColor(.blue)
                    .cornerRadius(12)
            }

        }
        .padding(20)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        .padding(.horizontal, 20)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
        }
        .font(.subheadline)
    }
}

struct NotificationSection: View {
    @Binding var isNotificationOn: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            Text("알림 설정")
                .font(.headline)

            Toggle(isOn: $isNotificationOn) {
                Text("기기 알림 받기")
            }
            .tint(.blue)

        }
        .padding(20)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 4)
        .padding(.horizontal, 20)
    }
}

struct DangerSection: View {
    @Binding var showLogoutAlert: Bool
    @Binding var showDeleteAlert: Bool

    var body: some View {
        VStack(spacing: 14) {

            Button {
                showLogoutAlert = true
            } label: {
                NavigationLink("로그아웃"){
                    LoginView()
                }
                .font(.headline)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }

            Button {
                showDeleteAlert = true
            } label: {
                NavigationLink("회원 탈퇴"){
                    LoginView()
                }
                .font(.headline)
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.white)
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.05), radius: 4)
            }
        }
        .padding(.horizontal, 20)
    }
}

extension SettingView {
    private func loadUserInfo() async {
        guard let uid = UserDefaults.standard.string(forKey: "LoginId"),
              !uid.isEmpty else {
            print("LoginId 없음")
            return
        }

        var comps = URLComponents(string: "\(baseURL)/BudgetoryGetUserInfo.php")!
        comps.queryItems = [URLQueryItem(name: "userId", value: uid)]
        guard let url = comps.url else {
            print("URL 생성 실패")
            return
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            // 서버 확인
            if let raw = String(data: data, encoding: .utf8) {
                print("UserGetInfo 응답:", raw)
            }

            let decoder = JSONDecoder()
            let info = try decoder.decode(UserInfoResponse.self, from: data)

            await MainActor.run {
                self.firstName = info.firstName
                self.lastName = info.lastName
                self.userId = info.id
                self.userPassword = info.password
                self.gender = info.gender
                self.birth = info.birth
            }
        } catch {
            print("유저 정보 파싱 실패:", error.localizedDescription)
        }
    }
}

extension SettingView {
    private func logout() {
        UserDefaults.standard.removeObject(forKey: "LoginId")
    }
}

extension SettingView {
    private func deleteAccount() {
        guard let uid = UserDefaults.standard.string(forKey: "LoginId") else { return }

        guard let url = URL(string: "\(baseURL)/BudgetoryDeleteUser.php?userId=\(uid)") else { return }

        Task {
            do {
                let (_, _) = try await URLSession.shared.data(from: url)
                UserDefaults.standard.removeObject(forKey: "LoginId")
            } catch {
                print("탈퇴 실패:", error.localizedDescription)
            }
        }
    }
}

private struct UserInfoResponse: Decodable {
    let id: String
    let firstName: String
    let lastName: String
    let password: String
    let gender: Int
    let birth: String
}
