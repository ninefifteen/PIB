//
//  WebServicesManagerAPI.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/6/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import UIKit
import CoreData

@objc protocol WebServicesMangerAPIDelegate: class {
    optional func webServicesManagerAPI(manager: WebServicesManagerAPI, errorAlert alert: UIAlertController)
}

class WebServicesManagerAPI: NSObject {
    
    // MARK: - Properties
    
    var managedObjectContext: NSManagedObjectContext? = nil
    var networkActivityCount: Int = 0
    var activeDataTask: NSURLSessionDataTask?
    weak var delegate: WebServicesMangerAPIDelegate?
    
    let xigniteApiKey: String = "9BDE96F9CF53466188C1E992BBE56ED1"
    
    let fundamentalsArray: [String] = ["CurrentPERatioAsPercentOfFiveYearAveragePERatio", "EBITDAMargin", "EBITMargin", "FiveYearAnnualCapitalSpendingGrowthRate", "FiveYearAnnualDividendGrowthRate", "FiveYearAnnualIncomeGrowthRate", "FiveYearAnnualNormalizedIncomeGrowthRate", "FiveYearAnnualRAndDGrowthRate", "FiveYearAnnualRevenueGrowthRate", "FiveYearAverageGrossProfitMargin", "FiveYearAverageNetProfitMargin", "FiveYearAveragePostTaxProfitMargin", "FiveYearAveragePreTaxProfitMargin", "FiveYearAverageRAndDAsPercentOfSales", "FiveYearAverageSGAndAAsPercentOfSales", "GrossMargin", "MarketValueAsPercentOfRevenues", "RAndDAsPercentOfSales", "SGAndAAsPercentOfSales"]
    
    // MARK: - Main Methods
    
    func downloadCompaniesMatchingSearchTerm(searchTerm: String, withCompletion completion: ((companies: [Company], success: Bool) -> Void)?) {
        
        if activeDataTask?.state == NSURLSessionTaskState.Running {
            activeDataTask?.cancel()
        }
        
        incrementNetworkActivityCount()
        
        let url = NSURL.URLWithString(urlStringForSearchString(searchTerm))
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            
            var companies = [Company]()
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)
                //println("rawStringData: \(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    let paddingStrippedData = self.stripJsonPaddingFromData(data)
                    
                    companies = self.companiesFromData(paddingStrippedData)
                    
                    if completion != nil {
                        completion!(companies: companies, success: true)
                    }
                    
                } else {
                    println("Unable To Download Company Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(companies: companies, success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code != -999 {  // Error not caused by cancelling of the data task.
                println("Unable To Download Company Data. Connection Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(companies: companies, success: false)
                }
                self.sendConnectionErrorMessage()
            }
            self.decrementNetworkActivityCount()
        })
        
        activeDataTask = dataTask
        dataTask.resume()
    }
    
    func downloadFundamentalsForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        let url = NSURL.URLWithString(urlStringForFundamentsForCompanyWithTickerSymbol(company.tickerSymbol))
        //println(url)
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)
                //println("rawStringData: \(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        self.addFundamentalsToCompany(company, fromData: data)
                    })
                    
                    if completion != nil {
                        completion!(success: true)
                    }
                    
                } else {
                    println("Unable To Download Company Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code != -999 {  // Error not caused by cancelling of the data task.
                println("Unable To Download Company Data. Connection Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(success: false)
                }
                self.sendConnectionErrorMessage()
            }
            self.decrementNetworkActivityCount()
        })
        
        dataTask.resume()
    }
    
    // MARK: - Helper Methods
    
    func urlStringForSearchString(searchString: String) -> String {
        let escapedSearchString = searchString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let urlString = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=" + escapedSearchString! + "&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
        return urlString
    }
    
    func urlStringForFundamentsForCompanyWithTickerSymbol(symbol: String) -> String {
        
        var fundamentals: String = ""
        
        for fundamental in fundamentalsArray {
            if fundamentals.isEmpty {
                fundamentals = fundamental
            } else {
                fundamentals += "," + fundamental
            }
        }
        
        let urlString = "http://fundamentals.xignite.com/xFundamentals.json/GetCompanyFundamentalList?_Token=\(xigniteApiKey)&IdentifierType=Symbol&Identifier=\(symbol)&FundamentalTypes=\(fundamentals)&UpdatedSince="
        
        return urlString
    }
    
    func stripJsonPaddingFromData(data: NSData) -> NSData {
        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)
        var range: NSRange = dataString.rangeOfString("(")
        range.location++
        range.length = dataString.length - range.location - 1
        return dataString.substringWithRange(range).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    func companiesFromData(data: NSData) -> [Company] {
        
        var companies = [Company]()
        let context = managedObjectContext
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: context!)
        
        // Use SwiftyJSON for handling JSON.
        let json = JSON(data: data)["ResultSet"]["Result"]
        //println(json.description)
        
        for (index: String, subJson: JSON) in json {
            
            var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
            
            if let exch = subJson["exch"].string {
                company.exchange = exch
            }
            if let exchDisp = subJson["exchDisp"].string {
                company.exchangeDisp = exchDisp
            }
            if let name = subJson["name"].string {
                company.name = name
            }
            if let tickerSymbol = subJson["symbol"].string {
                company.tickerSymbol = tickerSymbol
            }
            
            companies.append(company)
        }
        
        return companies
    }
    
    func addFundamentalsToCompany(company: Company, fromData data: NSData) {
        
        let context = managedObjectContext!
        let json = JSON(data: data)["Fundamentals"]
        
        let formatter: NSNumberFormatter = NSNumberFormatter()
        formatter.numberStyle = NSNumberFormatterStyle.DecimalStyle
        
        for (index: String, subJson: JSON) in json {
            
            if let type = subJson["Type"].string {
                
                switch type {

                case "CurrentPERatioAsPercentOfFiveYearAveragePERatio":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.currentPERatioAsPercentOfFiveYearAveragePERatio = value
                        }
                    }
                    
                case "EBITDAMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.ebitdaMargin = value
                        }
                    }
                    
                case "EBITMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.ebitMargin = value
                        }
                    }
                    
                case "FiveYearAnnualCapitalSpendingGrowthRate":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAnnualCapitalSpendingGrowthRate = value
                        }
                    }
                    
                case "FiveYearAnnualDividendGrowthRate":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAnnualDividendGrowthRate = value
                        }
                    }
                    
                case "FiveYearAnnualIncomeGrowthRate":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAnnualIncomeGrowthRate = value
                        }
                    }
                    
                case "FiveYearAnnualNormalizedIncomeGrowthRate":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAnnualNormalizedIncomeGrowthRate = value
                        }
                    }
                    
                case "FiveYearAnnualRAndDGrowthRate":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAnnualRAndDGrowthRate = value
                        }
                    }
                    
                case "FiveYearAnnualRevenueGrowthRate":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAnnualRevenueGrowthRate = value
                        }
                    }
                    
                case "FiveYearAverageGrossProfitMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAverageGrossProfitMargin = value
                        }
                    }
                    
                case "FiveYearAverageNetProfitMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAverageNetProfitMargin = value
                        }
                    }
                    
                case "FiveYearAveragePostTaxProfitMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAveragePostTaxProfitMargin = value
                        }
                    }
                    
                case "FiveYearAveragePreTaxProfitMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAveragePreTaxProfitMargin = value
                        }
                    }
                    
                case "FiveYearAverageRAndDAsPercentOfSales":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAverageRAndDAsPercentOfSales = value
                        }
                    }
                    
                case "FiveYearAverageSGAndAAsPercentOfSales":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.fiveYearAverageSGAndAAsPercentOfSales = value
                        }
                    }
                    
                case "GrossMargin":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.grossMargin = value
                        }
                    }
                    
                case "MarketValueAsPercentOfRevenues":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.marketValueAsPercentOfRevenues = value
                        }
                    }
                    
                case "RAndDAsPercentOfSales":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.rAndDAsPercentOfSales = value
                        }
                    }
                    
                case "SGAndAAsPercentOfSales":
                    if let valueString = subJson["Value"].string {
                        if let value: NSNumber = formatter.numberFromString(valueString) {
                            company.sgAndAAsPercentOfSales = value
                        }
                    }
                    
                default:
                    break
                }
            }
        }
        // Save the context.
        var error: NSError? = nil
        if !context.save(&error) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
    
    // MARK: - Network Activity Indicator
    
    func incrementNetworkActivityCount() {
        
        if networkActivityCount == 0 {
            NSNotificationCenter.defaultCenter().postNotificationName("ATNetworkActivityHasStarted", object: self)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = true
            })
        }
        
        networkActivityCount++
    }
    
    func decrementNetworkActivityCount() {
        
        networkActivityCount--
        
        if networkActivityCount < 1 {
            NSNotificationCenter.defaultCenter().postNotificationName("ATNetworkActivityHasEnded", object: self)
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            })
        }
    }
    
    // MARK: - Session Error Handling
    
    func sendGeneralErrorMessage() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alert = UIAlertController(title: "Error", message: "Unable to download data", preferredStyle: UIAlertControllerStyle.Alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(action)
            self.delegate?.webServicesManagerAPI!(self, errorAlert: alert)
        })
    }
    
    func sendConnectionErrorMessage() {
        dispatch_async(dispatch_get_main_queue(), { () -> Void in
            let alert = UIAlertController(title: "Connection Error", message: "You do not appear to be connected to the internet", preferredStyle: UIAlertControllerStyle.Alert)
            let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil)
            alert.addAction(action)
            self.delegate?.webServicesManagerAPI!(self, errorAlert: alert)
        })
    }
    
}
