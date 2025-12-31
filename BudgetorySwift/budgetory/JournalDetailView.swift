//
//  JournalDetailView.swift
//  budgetory
//
//  Created by 양현서 on 11/14/25.
//
import SwiftUI

struct JournalDetailView: View {
    var journal: Journal
    @State var isSucceedDelte: Bool = false
    @State var errorMessage: String?
    @State private var showPointToast = false
    @Environment(\.dismiss) var dismiss //이전 뷰(부모 뷰)로 이동하기 위해 선언.
    
    var body: some View {
        ZStack {
            // 기본 배경
            Color(red: 1.0, green: 0.99, blue: 0.93)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // 오른쪽 상단 작은 삭제 버튼
                    HStack {
                        Spacer()
                        Button(action: delete) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                                .font(.system(size: 18, weight: .bold))
                                .padding(.trailing, 12)
                        }
                    }

                    ZStack(alignment: .topLeading) {

                        // 노트 가로줄
                        VStack(spacing: 26) {
                            ForEach(0..<20) { _ in
                                Rectangle()
                                    .fill(Color.blue.opacity(0.08))
                                    .frame(height: 1)
                            }
                        }
                        .padding(.top, 12)

                        // 왼쪽 붉은 세로줄
                        Rectangle()
                            .fill(Color.red.opacity(0.35))
                            .frame(width: 2)
                            .padding(.leading, 10)

                        // 텍스트가 **직접 배경 위에 놓임**
                        VStack(alignment: .leading, spacing: 16) {
                            Text(journal.journalDate, formatter: dateFormatter)
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text(journal.title ?? "제목 없음")
                                .font(.title3)
                                .bold()

                            Text(journal.contents ?? "")
                                .font(.body)
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding(.leading, 24)   // 세로줄과 텍스트 겹치지 않게
                        .padding(.top, 20)
                    }
                    .padding(.horizontal)

                    // 아래쪽 주황색 수정 버튼
                    NavigationLink {
                        EditJournal(
                            title: journal.title ?? "",
                            contents: journal.contents ?? "",
                            journalPK: journal.journalPK
                        )
                    } label: {
                        Text("수정하기")
                            .font(.body)
                            .bold()
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.orange)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                .padding(.top)
            }

            // 삭제 토스트
            if showPointToast {
                VStack {
                    Spacer()
                    Text("지급된 포인트도 삭제됩니다.")
                        .padding()
                        .background(Color.black.opacity(0.75))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 40)
                        .transition(.opacity)
                }
                .zIndex(1)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showPointToast)
        .navigationTitle("일기 상세")
        .navigationBarTitleDisplayMode(.inline)
    }


    func delete(){
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryJournalDelete.php") else {
            print("url error")
            return
        }
        let body = "journalPK=\(journal.journalPK)"
        let encodedData = body.data(using: .utf8)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = encodedData
        
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
                isSucceedDelte=true
                print("삭제 성공")
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
                print("삭제 실패")
                errorMessage = "삭제가 실패하였습니다."
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

