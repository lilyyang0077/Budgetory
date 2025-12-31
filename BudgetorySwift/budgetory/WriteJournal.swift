//
//  WriteJournal.swift
//  budgetory
//
//  Created by 양현서 on 11/14/25.
//
import SwiftUI

struct WriteJournal: View {
    let consumption: ConsumptionChoose
    let userId = UserDefaults.standard.string(forKey: "LoginId") ?? ""
    
    @Environment(\.dismiss) var dismiss
    
    @State private var journalTitle: String = ""
    @State private var journalContents: String = ""
    @State private var isSaving = false
    @State var isSucceedJournal: Bool = false
    @State var errorMessage: String?
    @State private var showPointToast = false
    
    
    var body: some View {
        
        ZStack {
            Color(red: 0.85, green: 0.92, blue: 1.0)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    Text("일기 작성")
                        .font(.largeTitle)
                        .bold()
                    
                    // 선택한 소비를 카드로 표시
                    consumptionCard
                    
                    // 제목 입력
                    TextField("제목을 입력하세요", text: $journalTitle)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    
                    // 내용 입력
                    TextEditor(text: $journalContents)
                        .frame(height: 250)
                        .padding(10)
                        .background(Color.white)
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    
                    // 저장 버튼
                    Button(action: saveJournal) {
                        Text("저장하기")
                            .bold()
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.top, 10)
                    
                    //필수 항목 누락 시 에러 메시지 뜨기.
                    if let e = errorMessage {
                        Text(e).foregroundColor(.red).font(.callout)
                    }
                }
                .padding()
                
                //포인트 지급 안내 메시지.
                if showPointToast {
                    Text("포인트가 지급되었습니다!")
                        .padding()
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }.animation(.easeInOut(duration: 0.3), value: showPointToast)
        }
    }
    
    // 소비 카드 UI
    private var consumptionCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(consumption.date, formatter: dateFormatter)
                .font(.body)
                .foregroundColor(.black)
            
            Text(consumption.title)
                .font(.headline)
                .bold()
            
            Text("\(consumption.amount)원")
                .font(.subheadline)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: .gray.opacity(0.15), radius: 5, x: 0, y: 3)
    }
    
    // PHP에 데이터 저장
    func saveJournal() {
        guard let url=URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryWriteJournal.php")
        else{
            print("url error")
            return
        }
        
        let body = "userId=\(userId)&incomeConsumePK=\(consumption.incomeConsumePK)&journalTitle=\(journalTitle)&journalContents=\(journalContents)"
        
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
            if str == "1"{
                isSucceedJournal=true
                print("일기 추가 성공")
                DispatchQueue.main.async {
                    // 1) 토스트 메시지 띄우기
                    showPointToast = true
                    
                    // 2) 1.2초 뒤에 토스트 숨기고 화면 닫기
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                        showPointToast = false
                        dismiss()
                    }
                }
                
                
            }
            else{
                print("일기 추가 실패")
                errorMessage = "필수 항목이 누락되었습니다."
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
