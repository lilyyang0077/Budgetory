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

// MARK: - 색상 선택 뷰
struct ColorDotsPicker: View {
    @Binding var selectedPK: Int
    
    var body: some View {
        HStack(spacing: 14) {
            ForEach(1...7, id: \.self) { pk in
                Button {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.8)) {
                        selectedPK = pk
                    }
                } label: {
                    Circle()
                        .fill(colorFromPK(pk))
                        .frame(width: selectedPK == pk ? 36 : 30,
                               height: selectedPK == pk ? 36 : 30)
                        .overlay(
                            Circle()
                                .stroke(Color.white,
                                        lineWidth: selectedPK == pk ? 4 : 0)
                                .shadow(color: .black.opacity(selectedPK == pk ? 0.25 : 0),
                                        radius: selectedPK == pk ? 3 : 0, x: 0, y: 2)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - DTO & 모델
struct CategoryDTO: Codable, Identifiable {
    let id: Int
    let name: String
    let tag_color_pk: Int
    let budget_price: Int
    let created_at: String
}

struct CategoryItem: Identifiable, Hashable {
    let id: Int
    var name: String
    var tagColorPK: Int
    var budgetPrice: Int
}

// MARK: - 네트워크
private let categoryBaseURL = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP")!

// userId(String)을 사용
private func fetchCategories(userId: String) async throws -> [CategoryItem] {
    var comps = URLComponents(
        url: categoryBaseURL.appending(path: "BudgetoryCategoryList.php"),
        resolvingAgainstBaseURL: false
    )!
    comps.queryItems = [URLQueryItem(name: "userId", value: userId)]
    
    let (data, resp) = try await URLSession.shared.data(from: comps.url!)
    guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    let dtos = try JSONDecoder().decode([CategoryDTO].self, from: data)
    return dtos.map { dto in
        CategoryItem(
            id: dto.id,
            name: dto.name,
            tagColorPK: dto.tag_color_pk,
            budgetPrice: dto.budget_price
        )
    }
}

private func updateCategory(_ item: CategoryItem, userId: String) async throws {
    var request = URLRequest(url: categoryBaseURL.appending(path: "BudgetoryCategoryUpdate.php"))
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                     forHTTPHeaderField: "Content-Type")
    
    var comps = URLComponents()
    comps.queryItems = [
        .init(name: "categoryPK", value: String(item.id)),
        .init(name: "userId", value: userId),
        .init(name: "categoryName", value: item.name),
        .init(name: "tagColorPK", value: String(item.tagColorPK)),
        .init(name: "budgetPrice", value: String(item.budgetPrice))
    ]
    request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
    
    let (data, resp) = try await URLSession.shared.data(for: request)
    guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    let result = String(decoding: data, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard result == "1" else {
        throw NSError(
            domain: "API",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "수정 실패: \(result)"]
        )
    }
}

private func deleteCategory(id: Int, userId: String) async throws {
    var request = URLRequest(url: categoryBaseURL.appending(path: "BudgetoryCategoryDelete.php"))
    request.httpMethod = "POST"
    request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                     forHTTPHeaderField: "Content-Type")
    
    var comps = URLComponents()
    comps.queryItems = [
        .init(name: "categoryPK", value: String(id)),
        .init(name: "userId", value: userId)
    ]
    request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
    
    let (data, resp) = try await URLSession.shared.data(for: request)
    guard (resp as? HTTPURLResponse)?.statusCode == 200 else {
        throw URLError(.badServerResponse)
    }
    let result = String(decoding: data, as: UTF8.self)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard result == "1" else {
        throw NSError(
            domain: "API",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "삭제 실패: \(result)"]
        )
    }
}

// MARK: - 수정 시트
struct CategoryModifySheet: View {
    let original: CategoryItem
    let onSave: (CategoryItem) -> Void  // 수정된 아이템 반환
    
    @State private var name: String
    @State private var budgetText: String
    @State private var selectedColorPK: Int
    
    @Environment(\.dismiss) private var dismiss
    
    init(item: CategoryItem, onSave: @escaping (CategoryItem) -> Void) {
        self.original = item
        self.onSave = onSave
        _name = State(initialValue: item.name)
        _budgetText = State(initialValue: String(item.budgetPrice))
        _selectedColorPK = State(initialValue: item.tagColorPK)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("카테고리 이름") {
                    TextField("예: 식비", text: $name)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
                
                Section("목표 예산") {
                    TextField("예: 150000", text: $budgetText)
                        .keyboardType(.numberPad)
                        .onChange(of: budgetText) { _, new in
                            let filtered = new.filter { "0123456789,".contains($0) }
                            if filtered != new { budgetText = filtered }
                        }
                }
                
                Section("색상") {
                    ColorDotsPicker(selectedPK: $selectedColorPK)
                }
            }
            .navigationTitle("카테고리 수정")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        let cleanedBudget = budgetText
                            .replacingOccurrences(of: ",", with: "")
                            .replacingOccurrences(of: " ", with: "")
                        let budget = Int(cleanedBudget) ?? 0
                        var updated = original
                        updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        updated.tagColorPK = selectedColorPK
                        updated.budgetPrice = budget
                        onSave(updated)
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - 메인 View
struct CategoryModify: View {
    @State private var items: [CategoryItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var editingItem: CategoryItem?
    
    // 현재 로그인한 유저 id (문자열)
    private var userId: String {
        UserDefaults.standard.string(forKey: "LoginId") ?? ""
    }
    
    private let isPreview: Bool
    
    init() {
        self.isPreview = ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading && items.isEmpty {
                    ProgressView("불러오는 중…")
                } else if items.isEmpty {
                    ContentUnavailableView("카테고리가 없습니다", systemImage: "tray")
                } else {
                    List {
                        ForEach(items) { item in
                            HStack {
                                Circle()
                                    .fill(colorFromPK(item.tagColorPK))
                                    .frame(width: 14, height: 14)
                                
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .font(.headline)
                                    Text("예산 \(item.budgetPrice.formatted())원")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Button {
                                    editingItem = item
                                } label: {
                                    Image(systemName: "pencil")
                                }
                                .buttonStyle(.borderless)
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    Task {
                                        do {
                                            if !isPreview {
                                                try await deleteCategory(id: item.id, userId: userId)
                                            }
                                            items.removeAll { $0.id == item.id }
                                        } catch {
                                            errorMessage = error.localizedDescription
                                        }
                                    }
                                } label: {
                                    Label("삭제", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("카테고리 수정")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        load()
                    } label: {
                        Label("새로고침", systemImage: "arrow.clockwise")
                    }
                    .disabled(isPreview)
                }
            }
            .task {
                if !isPreview {
                    load()
                }
            }
            .alert("오류", isPresented: .constant(errorMessage != nil)) {
                Button("확인") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
            .sheet(item: $editingItem) { item in
                CategoryModifySheet(item: item) { updated in
                    Task {
                        do {
                            if !isPreview {
                                try await updateCategory(updated, userId: userId)
                            }
                            if let idx = items.firstIndex(where: { $0.id == updated.id }) {
                                items[idx] = updated
                            }
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                }
            }
        }
    }
    
    private func load() {
        guard !userId.isEmpty else {
            errorMessage = "로그인 정보가 없습니다."
            return
        }
        Task {
            isLoading = true
            defer { isLoading = false }
            do {
                items = try await fetchCategories(userId: userId)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - 프리뷰
struct CategoryModify_Previews: PreviewProvider {
    static var previews: some View {
        CategoryModify()
    }
}
