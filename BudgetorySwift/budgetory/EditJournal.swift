//
//  EditJournal.swift
//  budgetory
//
//  Created by 양현서 on 11/14/25.
//

import SwiftUI

struct EditJournal: View {
    @Environment(\.dismiss) var dismiss
    
    @State var title: String
    @State var contents: String
    let journalPK: Int
    
    @State private var isSaving = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            
            Text("일기 수정")
                .font(.largeTitle)
                .bold()
            
            TextField("제목", text: $title)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)
            
            TextEditor(text: $contents)
                .frame(minHeight: 200)
                .padding()
                .background(Color.white)
                .cornerRadius(8)
                .shadow(radius: 1)

            Button(action: updateJournal) {
                Text("수정 완료")
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(red: 1.0, green: 0.99, blue: 0.93))

    }
    
    func updateJournal() {
        isSaving = true
        
        let url = URL(string: "http://124.56.5.77/sheep/BudgetoryPHP/BudgetoryEditJournal.php")!
        
        let body = "journalPK=\(journalPK)&title=\(title)&contents=\(contents)"
        let postData = body.data(using: .utf8)!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = postData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            isSaving = false

            if let error = error {
                print("error: \(error)")
                return
            }

            guard let data = data else { return }
            print(String(decoding: data, as: UTF8.self))

            DispatchQueue.main.async {
                dismiss()   // 저장 후 뒤로가기
            }
        }.resume()
    }
}
