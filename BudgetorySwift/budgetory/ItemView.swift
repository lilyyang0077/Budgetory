import SwiftUI

// MARK: - 아이템 모델
struct PointItem: Identifiable, Hashable {
    let id = UUID()
    let pointPK: Int          // DB Point.pointPK
    let name: String
    let description: String
    let price: Int            // 절대값(양수) 포인트 가격
    let type: ItemType
    let overlayImageName: String   // PNG 파일 이름 (hat, ribbon, ym, gt 등)
    
    enum ItemType {
        case hat
        case clothes
        case accessory
    }
}

// MARK: - 포인트 내역 DTO
struct PointHistoryEntry: Identifiable, Codable {
    let pointActivityPK: Int
    let activityDate: String
    let activityStatus: Int
    let pointPK: Int
    let name: String
    let amount: Int
    let category: Int
    
    var id: Int { pointActivityPK }
    
    var isPlus: Bool { amount > 0 }
    var displayAmount: String {
        let sign = amount > 0 ? "+" : ""
        return "\(sign)\(amount) P"
    }
}

// MARK: - 서버에서 내려오는 UserItem + Point 조인 결과용 DTO
struct UserItemDTO: Codable {
    let userItemPK: Int
    let pointPK: Int
    let name: String
    let amount: Int
    let category: Int
    let isEquipped: Int
}

// category → ItemType 매핑
private func itemType(from category: Int) -> PointItem.ItemType {
    // DB 주석 기준:
    // 0-0: 모자, 0-1: 티셔츠, 0-3: 악세사리
    switch category {
    case 0:
        return .hat
    case 1:
        return .clothes
    case 3:
        return .accessory
    default:
        return .accessory
    }
}

// point / name → 이미지 이름 매핑
private func overlayImageName(for dto: UserItemDTO) -> String {
    switch dto.pointPK {
        // pointPK 기준 매핑
    case 1:  return "hat"
    case 2:  return "ribbon"
    case 3:  return "ym"
    case 4:  return "gt"
    case 8:  return "cape"
    case 9:  return "crown"
    case 10: return "fish"
    case 11: return "glasses"
    case 12: return "sunglasses"
    case 13: return "wing"
        
    default:
        // 이름 기반 fallback
        if dto.name.contains("모자") { return "hat" }
        if dto.name.contains("노란 목도리") { return "ym" }
        if dto.name.contains("초록 티셔츠") { return "gt" }
        if dto.name.contains("왕관") || dto.name.lowercased().contains("crown") { return "crown" }
        if dto.name.contains("안경") || dto.name.lowercased().contains("glasses") { return "glasses" }
        if dto.name.contains("선글라스") || dto.name.lowercased().contains("sunglasses") { return "sunglasses" }
        if dto.name.contains("물고기 핀") || dto.name.lowercased().contains("fish") { return "fish" }
        if dto.name.contains("망토") || dto.name.lowercased().contains("cape") { return "cape" }
        if dto.name.contains("날개") || dto.name.lowercased().contains("wing") { return "wing" }
        if dto.name.contains("머리핀") || dto.name.contains("리본") { return "ribbon" }
        return "hat"
    }
}

// MARK: - 포인트/고양이 상점 뷰

struct ItemView: View {
    // 내 포인트 (DB에서 불러옴)
    @State private var myPoints: Int = 0
    @State private var showInventory = false
    @State private var showHistory = false
    @State private var showRewardList = false
    
    // 상점(쇼핑 가능한) 아이템들
    @State private var shopItems: [PointItem] = []
    
    // 내가 가진 아이템들 (UserItem 기반)
    @State private var ownedItems: [PointItem] = []
    
    // 고양이가 장착한 아이템들 (3슬롯)
    @State private var equippedHat: PointItem?
    @State private var equippedClothes: PointItem?
    @State private var equippedAccessory: PointItem?
    
    @State private var alertMessage: String?
    @State private var isLoading = false
    
    private let baseURL = "http://124.56.5.77/sheep/BudgetoryPHP"
    
    var body: some View {
        ZStack {
            // 배경
            LinearGradient(
                colors: [Color.purple.opacity(0.20), Color.blue.opacity(0.18), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // 상단: 고양이 + 포인트 + 인벤토리 버튼
                topSection
                
                // 아이템 상점
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("포인트 상점")
                            .font(.headline)
                        Spacer()
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    if shopItems.isEmpty {
                        Text("준비된 아이템이 없어요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 20)
                    } else {
                        ScrollView {
                            VStack(spacing: 12) {
                                ForEach(shopItems) { item in
                                    ShopItemCard(
                                        item: item,
                                        isOwned: ownedItems.contains(where: { $0.pointPK == item.pointPK }),
                                        canAfford: myPoints >= item.price,
                                        onBuy: { buy(item) }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 16)
                        }
                    }
                }
                
                Spacer()
            }
        }
        .sheet(isPresented: $showHistory) {
            PointHistoryView()
        }
        .sheet(isPresented: $showInventory) {
            Inventory(
                ownedItems: ownedItems,
                equippedHat: $equippedHat,
                equippedClothes: $equippedClothes,
                equippedAccessory: $equippedAccessory
            )
            .presentationDetents([.fraction(0.4)])
            .presentationDragIndicator(.visible)
        }
        .navigationTitle("포인트 아이템")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAllFromDB()
        }
        .alert("알림", isPresented: Binding(
            get: { alertMessage != nil },
            set: { _ in alertMessage = nil }
        )) {
            Button("확인", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
    
    // MARK: - 상단 영역 (고양이 + 포인트 + 인벤토리)
    private var topSection: some View {
        VStack(spacing: 16) {
            CatView(
                hat: equippedHat,
                clothes: equippedClothes,
                accessory: equippedAccessory
            )
            .frame(maxWidth: .infinity)
            
            VStack(spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "star.circle.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 20))
                    Text("내 포인트")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Text("\(myPoints) P")
                    .font(.title2).bold()
                    .foregroundColor(.primary)
                
                // 버튼들 가로로 나란히
                HStack(spacing: 10) {
                    
                    Button {
                        showHistory = true
                    } label: {
                        Text("포인트 내역")
                            .font(.caption).bold()
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .cornerRadius(14)
                    }
                    
                    Button {
                        showInventory = true
                    } label: {
                        Text("인벤토리")
                            .font(.caption).bold()
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color.white.opacity(0.9))
                            .foregroundColor(.purple)
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
            }
        }
        .padding(.top, 16)
    }
    
    // MARK: - 전체 로딩 (포인트, 상점, 인벤토리)
    private func loadAllFromDB() async {
        let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
        guard !userId.isEmpty else {
            await MainActor.run {
                alertMessage = "로그인 정보가 없습니다."
            }
            return
        }
        
        await MainActor.run { isLoading = true }
        defer {
            Task { @MainActor in isLoading = false }
        }
        
        do {
            async let pointsTask = fetchUserPoint(userId: userId)
            async let inventoryTask = fetchInventory(userId: userId)
            async let shopTask = fetchShopItems()
            
            let (points, inventoryResult, shop) = try await (pointsTask, inventoryTask, shopTask)
            
            await MainActor.run {
                myPoints = points
                shopItems = shop
                ownedItems = inventoryResult.items
                equippedHat = inventoryResult.equippedHat
                equippedClothes = inventoryResult.equippedClothes
                equippedAccessory = inventoryResult.equippedAccessory
            }
        } catch {
            await MainActor.run {
                alertMessage = "데이터 불러오기 실패: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - 구매 로직 (DB 연동)
    private func buy(_ item: PointItem) {
        Task {
            let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
            guard !userId.isEmpty else {
                await MainActor.run { alertMessage = "로그인 정보가 없습니다." }
                return
            }
            
            // 이미 보유
            if ownedItems.contains(where: { $0.pointPK == item.pointPK }) {
                await MainActor.run { alertMessage = "이미 가지고 있는 아이템이에요." }
                return
            }
            // 포인트 부족
            if myPoints < item.price {
                await MainActor.run { alertMessage = "포인트가 부족해요." }
                return
            }
            
            do {
                let success = try await requestBuyItem(userId: userId, pointPK: item.pointPK)
                if success {
                    // 성공 시 서버 상태를 다시 불러오기
                    await loadAllFromDB()
                    await MainActor.run {
                        alertMessage = "'\(item.name)' 아이템을 구매했어요!"
                    }
                } else {
                    await MainActor.run {
                        alertMessage = "구매에 실패했습니다."
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "구매 중 오류가 발생했습니다: \(error.localizedDescription)"
                }
            }
        }
    }
    
    // MARK: - 네트워크: 내 포인트 조회
    /// GET userId → plain text 포인트
    private func fetchUserPoint(userId: String) async throws -> Int {
        guard let url = URL(string: "\(baseURL)/BudgetoryUserPoint.php?userId=\(userId)") else {
            throw URLError(.badURL)
        }
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        let str = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return Int(str) ?? 0
    }
    
    // MARK: - 네트워크: 인벤토리(UserItem + Point) 조회
    /// GET userId → JSON UserItemDTO[]
    private func fetchInventory(userId: String) async throws
    -> (items: [PointItem], equippedHat: PointItem?, equippedClothes: PointItem?, equippedAccessory: PointItem?) {
        
        var comps = URLComponents(string: "\(baseURL)/BudgetoryUserItemList.php")!
        comps.queryItems = [URLQueryItem(name: "userId", value: userId)]
        let (data, response) = try await URLSession.shared.data(from: comps.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let dtos = try JSONDecoder().decode([UserItemDTO].self, from: data)
        
        let items: [PointItem] = dtos.map { dto in
            PointItem(
                pointPK: dto.pointPK,
                name: dto.name,
                description: "가격: \(dto.amount)P",
                price: abs(dto.amount),
                type: itemType(from: dto.category),
                overlayImageName: overlayImageName(for: dto)
            )
        }
        
        var hat: PointItem?
        var clothes: PointItem?
        var accessory: PointItem?
        
        // 장착 상태 세팅
        for dto in dtos where dto.isEquipped == 1 {
            if let item = items.first(where: { $0.pointPK == dto.pointPK }) {
                switch item.type {
                case .hat:       hat = item
                case .clothes:   clothes = item
                case .accessory: accessory = item
                }
            }
        }
        
        return (items, hat, clothes, accessory)
    }
    
    // MARK: - 네트워크: 상점 아이템 목록
    /// 예시 PHP: BudgetoryPointShopList.php → JSON Point 목록
    /// (status=1, category가 0-x 인 아이템만 내려줌
    private func fetchShopItems() async throws -> [PointItem] {
        guard let url = URL(string: "\(baseURL)/BudgetoryPointShopList.php") else {
            throw URLError(.badURL)
        }
        
        struct ShopDTO: Codable {
            let pointPK: Int
            let name: String
            let amount: Int
            let category: Int
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let dtos = try JSONDecoder().decode([ShopDTO].self, from: data)
        
        // PointItem 배열로 변환
        var items = dtos.map { dto in
            PointItem(
                pointPK: dto.pointPK,
                name: dto.name,
                description: " ",
                price: abs(dto.amount),                // 가격(양수)
                type: itemType(from: dto.category),
                overlayImageName: {
                    let tempDTO = UserItemDTO(
                        userItemPK: 0,
                        pointPK: dto.pointPK,
                        name: dto.name,
                        amount: dto.amount,
                        category: dto.category,
                        isEquipped: 0
                    )
                    return overlayImageName(for: tempDTO)
                }()
            )
        }
        
        // 커스텀 우선순위
        let priority: [Int: Int] = [
            11: 1,  // glasses
            1: 2,
            10: 3,  // fish
            2: 4,
            3: 5,
            12: 6,  // sunglasses
            9: 7,   // crown
            4: 8,
            8: 9,   // cape
            13: 10,  // wing
        ]
        
        items.sort { lhs, rhs in
            let p0 = priority[lhs.pointPK] ?? 999
            let p1 = priority[rhs.pointPK] ?? 999
            
            if p0 != p1 {
                return p0 < p1          // 우선순위 낮은 숫자 먼저
            } else {
                return lhs.price < rhs.price   // 같은 우선순위면 가격 낮은 순
            }
        }
        
        return items
    }
    
    // MARK: - 네트워크: 아이템 구매
    /// POST: userId, pointPK  → "1" (성공) / "0" (실패)
    private func requestBuyItem(userId: String, pointPK: Int) async throws -> Bool {
        guard let url = URL(string: "\(baseURL)/BudgetoryBuyItem.php") else {
            throw URLError(.badURL)
        }
        
        var comps = URLComponents()
        comps.queryItems = [
            URLQueryItem(name: "userId", value: userId),
            URLQueryItem(name: "pointPK", value: String(pointPK))
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8",
                         forHTTPHeaderField: "Content-Type")
        request.httpBody = comps.percentEncodedQuery?.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }
        
        let result = String(decoding: data, as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return result == "1"
    }
}

// MARK: - 고양이 뷰 (3슬롯 레이어)
private struct CatView: View {
    let hat: PointItem?
    let clothes: PointItem?
    let accessory: PointItem?
    
    // 아이템별 크기
    private let scaleMap: [String: CGFloat] = [
        "glasses": 0.52,
        "cape": 0.93,
        "gt": 0.38,
        "crown": 0.32,
        "ribbon": 0.38,
        "ym": 0.51,
        "hat": 0.65,
        "wing": 1.15,
        "sunglasses": 0.48,
        "fish": 0.20
    ]
    
    // 아이템별 위치
    private let offsetMap: [String: CGSize] = [
        "glasses": CGSize(width: 0.0,   height: -28.0),
        "cape":    CGSize(width: 0.0,   height:  70.0),
        "gt":    CGSize(width: -2.5,   height:  40.0),
        "crown":   CGSize(width: 8.7,   height: -81.0),
        "ribbon":  CGSize(width: 11.4,  height: -74.6),
        "ym":      CGSize(width: -3.2,  height: 40.6),
        "hat":     CGSize(width: 1.7,   height: -80.5),
        "wing":    CGSize(width: -1.2,  height:  -2.0),
        "sunglasses": CGSize(width: 0.0, height: -35.0),
        "fish":    CGSize(width: 30.3,  height: -69.1)
    ]
    
    var body: some View {
            ZStack {
                Image("cat")
                    .resizable()
                    .scaledToFit()
                
                // 옷
                if let clothes {
                    overlayImage(for: clothes)
                }
                // 악세서리
                if let accessory {
                    overlayImage(for: accessory)
                }
                // 모자
                if let hat {
                    overlayImage(for: hat)
                }
            }
            .frame(width: 260, height: 260)
        }

    private func overlayImage(for item: PointItem) -> some View {
            let key = item.overlayImageName.lowercased()
            let scale = scaleMap[key] ?? 1.0
            let offset = offsetMap[key] ?? .zero
            
            return Image(item.overlayImageName)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .offset(offset)
        }
    }

// MARK: - 상점 아이템 카드
private struct ShopItemCard: View {
    let item: PointItem
    let isOwned: Bool
    let canAfford: Bool
    let onBuy: () -> Void
    
    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.95))
                    .frame(width: 100, height: 100)
                    .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
                
                Image(item.overlayImageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text(item.name)
                    .font(.title3).bold()
                
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.system(size: 16))
                    Text("\(item.price)")
                        .font(.title3).bold()
                }
            }
            Spacer()
            Button(action: onBuy) {
                Text(isOwned ? "보유함" : "구매")
                    .font(.headline)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 18)
                    .background(
                        isOwned ? Color.gray.opacity(0.3)
                        : (canAfford ? Color.blue : Color.gray.opacity(0.4))
                    )
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
            .disabled(isOwned || !canAfford)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }
}

// MARK: - 프리뷰
#Preview {
    NavigationStack {
        ItemView()
    }
}
