//
//  BarChart.swift
//  BitFlip
//
//  Created by Sean Ng Pack on 8/26/19.
//  Copyright © 2019 Lengjai. All rights reserved.
//

import Foundation
import Charts

class BarChart {
    
    // MARK: - Dependency injection variable
    
    var coreDataManager: CoreDataManager
    
    // MARK: - Initialization
    
    init(coreDataManager: CoreDataManager) {
        self.coreDataManager = coreDataManager
    }
    
    // MARK: - Functions
    
    /// Draw the bar chart comparing # of heads to # of tails
    ///
    /// - Parameters
    ///     - barChartView: the BarChartView passed from the graph controller
    ///
    func drawChart(_ barChartView: BarChartView) {
        
        // xAxis
        let xAxis = barChartView.xAxis
        xAxis.labelPosition = XAxis.LabelPosition.bottom
        xAxis.granularity = 1.0
        xAxis.drawGridLinesEnabled = false
        let labels = ["Heads ", "Tails"]
        xAxis.labelCount = labels.count
        xAxis.valueFormatter = IndexAxisValueFormatter(values:labels)
        
        // leftAxis
        let leftAxis = barChartView.leftAxis
        leftAxis.drawGridLinesEnabled = false
        leftAxis.axisMinimum = 0.0
        leftAxis.granularityEnabled = true
        leftAxis.granularity = 1.0
        
        // rightAxis
        let rightAxis = barChartView.rightAxis
        rightAxis.enabled = false
        rightAxis.axisMinimum = 0.0
        
        // legend
        let legend = barChartView.legend
        legend.enabled = false
        legend.wordWrapEnabled = true
        legend.horizontalAlignment = .center
        legend.verticalAlignment = .bottom
        legend.orientation = .horizontal
        legend.drawInside = false
        
        // barChart settings
        barChartView.minOffset = 0
        barChartView.noDataText = ""
        barChartView.animate(xAxisDuration: 0.5, yAxisDuration: 1.0)
        barChartView.isUserInteractionEnabled = false
        barChartView.drawGridBackgroundEnabled = false
        barChartView.chartDescription?.enabled = false
        
        let flips = coreDataManager.fetchOutcomes(range: 1000)
        let headsCount = flips["heads"]!
        let tailsCount = flips["tails"]!
        
        let swag = BarChartDataEntry(x: 0.0, y: Double(headsCount))
        let swag2 = BarChartDataEntry(x: 1.0, y: Double(tailsCount))
        let values1 = [swag, swag2]
        
        let chartDataSet = BarChartDataSet(entries: values1, label: "flips")
        
        let chartData = BarChartData()
        chartData.addDataSet(chartDataSet)
        
        barChartView.data = chartData
        
        self.prettifyData(chartData)
    }
    
    /// Make the datapoints look nicer
    func prettifyData(_ data: BarChartData) {
        data.setDrawValues(false)
    }
    
    /// Clear data from the chart
    func clear(_ barChartView: BarChartView) {
        barChartView.clear()
    }
}
