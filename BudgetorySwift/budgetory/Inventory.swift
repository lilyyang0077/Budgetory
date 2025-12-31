import SwiftUI

struct Inventory: View {
    let ownedItems: [PointItem]
    
    @Binding var equippedHat: PointItem?
    @Binding var equippedClothes: PointItem?
    @Binding var equippedAccessory: PointItem?
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.blue.opacity(0.12), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(alignment: .leading, spacing: 14) {
                Text("내 인벤토리")
                    .font(.title3)
                    .bold()
                    .padding(.top, 14)
                
                if ownedItems.isEmpty {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "bag")
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                        Text("아직 구매한 아이템이 없어요.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(ownedItems) { item in
                                inventoryItemRow(item)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private func inventoryItemRow(_ item: PointItem) -> some View {
        HStack {
            // 썸네일
            ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)

                        Image(item.overlayImageName)
                            .resizable()
                            .scaledToFit()
                            .padding(6)
                    }
                    .frame(width: 50, height: 50)
            // 아이템 이름
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
            }
            Spacer()
            
            Button {
                toggleEquip(item)
            } label: {
                Text(isEquipped(item) ? "해제" : "장착")
                    .font(.caption).bold()
                    .padding(.vertical, 5)
                    .padding(.horizontal, 14)
                    .background(isEquipped(item) ? Color.gray : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.96))
                .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        )
    }
    
    // MARK: - 장착 여부 체크
    private func isEquipped(_ item: PointItem) -> Bool {
        switch item.type {
        case .hat:
            return equippedHat?.pointPK == item.pointPK
        case .clothes:
            return equippedClothes?.pointPK == item.pointPK
        case .accessory:
            return equippedAccessory?.pointPK == item.pointPK
        }
    }
    
    // MARK: - 장착 / 해제 토글
    private func toggleEquip(_ item: PointItem) {
        switch item.type {
        case .hat:
            if isEquipped(item) {
                equippedHat = nil          // 이미 장착 → 해제
            } else {
                equippedHat = item         // 새로 장착
            }
            
        case .clothes:
            if isEquipped(item) {
                equippedClothes = nil
            } else {
                equippedClothes = item
            }
            
        case .accessory:
            if isEquipped(item) {
                equippedAccessory = nil
            } else {
                equippedAccessory = item
            }
        }
    }
}

