//
//  DetailViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/2/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController, CPTPlotDataSource {
    
    // MARK: - Properties
    
    //let company: Company!

    @IBOutlet weak var stockNameLabel: UILabel!
    @IBOutlet weak var stockExchangeLabel: UILabel!
    @IBOutlet weak var stockTickerLabel: UILabel!
    
    @IBOutlet weak var graphView: CPTGraphHostingView!
    
    var company: Company!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
        self.addTestPlot()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func configureView() {
        // Update the user interface for the detail item.
        if let company: Company = self.company {
            if let label = self.stockNameLabel { label.text = company.name }
            if let label = self.stockExchangeLabel { label.text = company.exchange }
            if let label = self.stockTickerLabel { label.text = company.tickerSymbol }
            if let label = self.stockTickerLabel { title = company.tickerSymbol }
        }
        
        // Temporary: Log all company properties to console.
        /*if let company: Company = self.company {
            println("CurrentPERatioAsPercentOfFiveYearAveragePERatio: \(company.currentPERatioAsPercentOfFiveYearAveragePERatio)")
            println("EBITDAMargin: \(company.ebitdaMargin)")
            println("EBITMargin: \(company.ebitMargin)")
            println("FiveYearAnnualCapitalSpendingGrowthRate: \(company.fiveYearAnnualCapitalSpendingGrowthRate)")
            println("FiveYearAnnualDividendGrowthRate: \(company.fiveYearAnnualDividendGrowthRate)")
            println("FiveYearAnnualIncomeGrowthRate: \(company.fiveYearAnnualIncomeGrowthRate)")
            println("FiveYearAnnualNormalizedIncomeGrowthRate: \(company.fiveYearAnnualNormalizedIncomeGrowthRate)")
            println("FiveYearAnnualRAndDGrowthRate: \(company.fiveYearAnnualRAndDGrowthRate)")
            println("FiveYearAnnualRevenueGrowthRate: \(company.fiveYearAnnualRevenueGrowthRate)")
            println("FiveYearAverageGrossProfitMargin: \(company.fiveYearAverageGrossProfitMargin)")
            println("FiveYearAverageNetProfitMargin: \(company.fiveYearAverageNetProfitMargin)")
            println("FiveYearAveragePostTaxProfitMargin: \(company.fiveYearAveragePostTaxProfitMargin)")
            println("FiveYearAveragePreTaxProfitMargin: \(company.fiveYearAveragePreTaxProfitMargin)")
            println("FiveYearAverageRAndDAsPercentOfSales: \(company.fiveYearAverageRAndDAsPercentOfSales)")
            println("FiveYearAverageSGAndAAsPercentOfSales: \(company.fiveYearAverageSGAndAAsPercentOfSales)")
            println("GrossMargin: \(company.grossMargin)")
            println("MarketValueAsPercentOfRevenues: \(company.marketValueAsPercentOfRevenues)")
            println("RAndDAsPercentOfSales: \(company.rAndDAsPercentOfSales)")
            println("SGAndAAsPercentOfSales: \(company.sgAndAAsPercentOfSales)")
        }*/
    }
    
    func addTestPlot() {
        
        // create graph
        var graph = CPTXYGraph(frame: CGRectZero)
        graph.title = "Hello Graph"
        graph.paddingLeft = 0
        graph.paddingTop = 0
        graph.paddingRight = 0
        graph.paddingBottom = 0
        
        // hide the axes
        var axes = graph.axisSet as CPTXYAxisSet
        var lineStyle = CPTMutableLineStyle()
        lineStyle.lineWidth = 0
        axes.xAxis.axisLineStyle = lineStyle
        axes.yAxis.axisLineStyle = lineStyle
        
        // add a pie plot
        var pie = CPTPieChart()
        pie.dataSource = self
        pie.pieRadius = (self.graphView.frame.size.width * 0.9) / 2.0
        graph.addPlot(pie)
        
        self.graphView.hostedGraph = graph
    }
    
    // MARK: - CPTPlotDataSource
    
    func numberOfRecordsForPlot(plot: CPTPlot!) -> UInt {
        return 4
    }
    
    func numberForPlot(plot: CPTPlot!, field fieldEnum: UInt, recordIndex idx: UInt) -> NSNumber! {
        return idx+1
    }
}

