//
//  JournalDateChoose.swift
//  budgetory
//
//  Created by 양현서 on 11/14/25.
//
import SwiftUI


struct ConsumptionChoose: Codable {
    var incomeConsumePK: Int
    var date: Date = Date()
    var title: String
    var amount: Int
    
}
struct ConsumptionChooseItem: View {
    @State var consumptionChooseData : ConsumptionChoose
    var body: some View {
        HStack{
            Text(consumptionChooseData.title)
            Text(consumptionChooseData.date, formatter: dateFormatter)
            Text(String(consumptionChooseData.amount))
        }
    }
}

struct ConsumptionChooses: Codable {
    var consumptionChooses: [ConsumptionChoose]
}


//메인
struct JournalDateChoose: View {
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? "" //로그인 한 userID를 어느 뷰에서든 활용할 수 있도록 변수 지정.
    @State var consumptionChooses: ConsumptionChooses = ConsumptionChooses(consumptionChooses: [])

    var body: some View {
        NavigationView {
            ZStack {
                // 전체 배경색
                Color(red: 0.93, green: 0.97, blue: 1.0)
                    .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 12) {

                    //제목
                    Text("소비 선택")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, 20)
                        .padding(.horizontal)

                    //설명 문구
                    Text("충동적 소비를 한 내역들이에요.\n이 중에 일기를 작성할 소비를 골라보세요.")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding(.horizontal)

                    //리스트
                    if consumptionChooses.consumptionChooses.isEmpty {

                        VStack(spacing: 10) {
                            Spacer().frame(height: 30)

                            Text("소비가 없어요")
                                .font(.subheadline) // title3 → headline 로 축소
                                .foregroundColor(.gray)

                            Text("소비 내역을 추가해보세요!")
                                .font(.subheadline)
                                .foregroundColor(.gray)

                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(.horizontal)
                        
                    } else {
                        List {
                            ForEach(consumptionChooses.consumptionChooses, id: \.incomeConsumePK) { item in
                                 NavigationLink( //Navigation을 지정해서 사용자가 선택한 항목을 일기를 작성하는 뷰로 넘김.
                                    destination: WriteJournal(consumption: item)
                                ) {
                                    cardView(for: item)
                                }
                                .listRowSeparator(.hidden)
                                .listRowBackground(Color.clear)
                            }
                        }
                        .listStyle(.plain)
                    }

                }
            }
            .onAppear { loadData() } //화면이 등장할 때 loadDate() 함수 실행되도록 지정
        }
    }

    //항목 하나 UI. 리스트 항목들을 분리된 느낌을 주기 위해 동글동글한 UI를 만들어 줌.
    @ViewBuilder
    func cardView(for item: ConsumptionChoose) -> some View {
        VStack(alignment: .leading, spacing: 6) {

            Text(item.date, formatter: dateFormatter) //dateFormatter 활용.
                .font(.body)
                .foregroundColor(.black)

            Text(item.title)
                .font(.headline)
                .bold()

            Text("\(item.amount)원")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 3)
    }


    // 데이터 불러오는 부분
    func loadData() {
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/JournalDateChoose.php") else {
            print("url error")
            return
        }
        let body = "userId=\(userId)" //위에서 선언한 userID를 php로 넘김.
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

            if let jsonConsumptionChooseData = try? decoder.decode(ConsumptionChooses.self, from: data) {
                DispatchQueue.main.async {
                    consumptionChooses = jsonConsumptionChooseData //받아온 데이터를 UI에서 사용하는 변수에 저장
                }
            }
        }.resume()
    }
}


// 날짜 표시용 포매터
private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
}()
