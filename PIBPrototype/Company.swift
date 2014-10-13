//
//  Company.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/11/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import Foundation
import CoreData

class Company: NSManagedObject {

    @NSManaged var exchange: String
    @NSManaged var exchangeDisp: String
    @NSManaged var name: String
    @NSManaged var tickerSymbol: String
    @NSManaged var currentPERatioAsPercentOfFiveYearAveragePERatio: NSNumber
    @NSManaged var ebitdaMargin: NSNumber
    @NSManaged var ebitMargin: NSNumber
    @NSManaged var fiveYearAnnualCapitalSpendingGrowthRate: NSNumber
    @NSManaged var fiveYearAnnualDividendGrowthRate: NSNumber
    @NSManaged var fiveYearAnnualIncomeGrowthRate: NSNumber
    @NSManaged var fiveYearAnnualNormalizedIncomeGrowthRate: NSNumber
    @NSManaged var fiveYearAnnualRAndDGrowthRate: NSNumber
    @NSManaged var fiveYearAnnualRevenueGrowthRate: NSNumber
    @NSManaged var fiveYearAverageGrossProfitMargin: NSNumber
    @NSManaged var fiveYearAverageNetProfitMargin: NSNumber
    @NSManaged var fiveYearAveragePostTaxProfitMargin: NSNumber
    @NSManaged var fiveYearAveragePreTaxProfitMargin: NSNumber
    @NSManaged var fiveYearAverageRAndDAsPercentOfSales: NSNumber
    @NSManaged var fiveYearAverageSGAndAAsPercentOfSales: NSNumber
    @NSManaged var grossMargin: NSNumber
    @NSManaged var marketValueAsPercentOfRevenues: NSNumber
    @NSManaged var rAndDAsPercentOfSales: NSNumber
    @NSManaged var sgAndAAsPercentOfSales: NSNumber

}
