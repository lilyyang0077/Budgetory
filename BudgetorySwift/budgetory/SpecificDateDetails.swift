//
//  SpecificDateDetails.swift
//  budgetory
//
//  Created by 양현서 on 11/3/25.
//

import SwiftUI

struct Board: Codable {
    var incomeConsumePK: Int
    var title: String?
    var amount: Int?
    var categoryPK: Int?
    var categoryName: String
    var memo: String?
    var consumeAt: String?
}

struct BoardItem: View {
    @State var boardData : Board
    var body: some View {
        HStack{
            Text("\(boardData.title ?? "")")
            Spacer()
            Text("\(boardData.amount ?? 0)원")
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
    }
}


struct Boards: Codable {
    var boards: [Board]
}

struct SpecificDateDetails: View {
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    @State var selectedDate: Date
    @State var boards: Boards=Boards(boards: [Board]())
    
    var body: some View {
        //선택한 날짜 표시
        VStack{
            Text("\(selectedDate, formatter: dateFormatter) 상세 내역")
                .font(.title3)
                .padding(.bottom, 10)
        }
        
        VStack {
            if boards.boards.isEmpty {
                Text("등록된 내역이 없습니다.\n 소비 내역을 추가하세요.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            else{
                List(boards.boards, id: \.incomeConsumePK) { item in
                    NavigationLink(
                        destination: SpecificCIDetails(board: item)
                    ) {
                        BoardItem(boardData: item)
                    }
                }
            }
        }.onAppear {
            guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetorySpecificDate.php") else {
                print("url error")
                return
            }
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let dateString = formatter.string(from: selectedDate)
            
            let body = "userId=\(userId)&selectedDate=\(dateString)"
            let encodedData = body.data(using: String.Encoding.utf8)
            request.httpBody = encodedData
            
            URLSession.shared.dataTask(with: request) { (data, response, error) in
                if let error = error {
                    print("error: \(error)")
                    return
                }
                guard let data = data else { return }
                let str = String(decoding: data, as: UTF8.self)
                print("data ? \(str)")
                
                do {
                    let str2 = String(decoding: data, as: UTF8.self)
                    print(str2)
                    let decoder = JSONDecoder()
                    if let jsonBoardData = try? decoder.decode(Boards.self, from: data) {
                        boards=jsonBoardData
                    }
                }
                
                
                
            }.resume()
        }
        
        
    }
    
}

// 날짜 표시용 포매터
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()





