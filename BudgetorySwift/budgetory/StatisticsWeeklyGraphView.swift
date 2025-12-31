//
//  StaticsWeeklyGraphView.swift
//  budgetory
//
//  Created by 양현서 on 11/29/25.
//

import SwiftUI
import Charts

struct StatisticsWeeklyGraphView: View {
    let data: [ChartWeeklyBar]
    let onSwipeLeft: () -> Void
    let onSwipeRight: () -> Void

    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("날짜", item.weekRangeLabel),
                    y: .value("금액", item.total)
                )
            }
        }
        .frame(height: 260)
        .padding(.horizontal)
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width < -50 {
                        onSwipeLeft()     // 다음 페이지 요청
                    } else if value.translation.width > 50 {
                        onSwipeRight()    // 이전 페이지 요청
                    }
                }
        )
    }
}
