//
//  DetailViewController.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/2/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    // MARK: - Properties
    
    //let company: Company!

    @IBOutlet weak var stockNameLabel: UILabel!
    @IBOutlet weak var stockExchangeLabel: UILabel!
    @IBOutlet weak var stockTickerLabel: UILabel!
    
    var company: Company!

    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        self.configureView()
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
        if let company: Company = self.company {
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
        }
    }
}

