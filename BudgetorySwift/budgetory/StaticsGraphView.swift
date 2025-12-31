//
//  barChartView.swift
//  budgetory
//
//  Created by 양현서 on 11/24/25.
//
import SwiftUI
import Charts

struct StatisticsGraphView: View {
    let data: [ChartBar]

    var body: some View {
        Chart {
            ForEach(data) { item in
                BarMark(
                    x: .value("날짜", item.month),
                    y: .value("금액", item.total)
                )
            }
        }
        .frame(height: 260)
        .padding(.horizontal)
    }
}

