//
//  SpecificCIDetails.swift
//  budgetory
//
//  Created by 양현서 on 11/17/25.
//
import SwiftUI

struct SpecificCIDetails: View {
    var board: Board
    @State private var showPointToast = false
    @State var isSucceedDelete: Bool = false
    @State var errorMessage: String?
    @Environment(\.dismiss) var dismiss //이전 뷰(부모 뷰)로 이동하기 위해 선언.
    
    var body: some View {
        ZStack {
            // 배경색
            Color(red: 0.90, green: 0.95, blue: 1.0)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 22) {

                    // 1. 내역명 (작은 글씨)
                    Text(board.title ?? "내역 없음")
                        .font(.subheadline)
                        .foregroundColor(.gray)

                    // 2. 금액 (가장 큰 글씨)
                    Text("\(board.amount ?? 0)원")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)

                    // 3. 카테고리
                    HStack {
                        Text("카테고리")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.7))

                        Spacer()

                        Text("\(board.categoryName)")
                            .font(.body)
                    }

                    // 4. 일시
                    HStack {
                        Text("일시")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.7))

                        Spacer()

                        Text(board.consumeAt ?? "")
                            .font(.body)
                    }

                    // 5. 메모
                    VStack(alignment: .leading, spacing: 8) {
                        Text("메모")
                            .font(.headline)
                            .foregroundColor(.black.opacity(0.7))

                        // 텍스트필드 스타일의 박스
                        Text(board.memo ?? "")
                            .font(.body)
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white)

                    }

                    // 버튼 구역
                    VStack(spacing: 16) {
                        //수정 버튼
                        /*
                        NavigationLink {
                            EditCI(
                                title: board.title ?? "",
                                amount: board.amount ?? 0,
                                categoryPK: board.categoryPK,
                                consumeAt: board.consumeAt ?? "",
                                memo: board.memo ?? '',
                                incomeConsumePK: board.incomeConsumePK
                                
                            )
                        } label: {
                            Text("수정하기")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(red: 1.0, green: 0.78, blue: 0.30)) // 주황+노랑 사이
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                         */
                        
                       

                        // 삭제 버튼
                        Button(action: delete) {
                            Text("삭제")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.red.opacity(0.85))
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    .padding(.top, 20)

                    Spacer()
                }
                .padding(24)
            }
            // 삭제 토스트
            if showPointToast {
                VStack {
                    Spacer()
                    Text("해당 내역이 삭제됩니다.")
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
        guard let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/CIDelete.php") else {
            print("url error")
            return
        }
        let body = "incomeConsumePK=\(board.incomeConsumePK)"
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
                isSucceedDelete=true
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


