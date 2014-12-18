//
//  WebServicesManagerAPI.swift
//  PIB
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
    
    var managedObjectContext: NSManagedObjectContext!
    var networkActivityCount: Int = 0
    var activeDataTask: NSURLSessionDataTask?
    weak var delegate: WebServicesMangerAPIDelegate?
    
    // Debugging properties.
    var logMetricsToConsole: Bool = false
    var googleSummaryUrlString = String()
    var googleFinancialMetricsUrlString = String()
    
    
    // MARK: - Main Methods
    
    func downloadCompaniesMatchingSearchTerm(searchTerm: String, withCompletion completion: ((companies: [Company], success: Bool) -> Void)?) {
        
        if activeDataTask?.state == NSURLSessionTaskState.Running {
            activeDataTask?.cancel()
        }
        
        incrementNetworkActivityCount()
        
        let url = NSURL(string: urlStringForSearchString(searchTerm))
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            var companies = [Company]()
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)
                //println("WebServicesManagerAPI downloadCompaniesMatchingSearchTerm rawStringData:\n\(rawStringData)")
                
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
    
    func downloadGoogleSummaryForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleSummaryUrlString = urlStringForGoogleSummaryForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchange)
        let url = NSURL(string: googleSummaryUrlString)
        //println(url!)
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleSummaryForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        let parseSuccess = self.parseAndAddGoogleSummaryData(data, forCompany: company)
                        if completion != nil {
                            completion!(success: parseSuccess)
                        }
                    })
                    
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
    
    func downloadGoogleFinancialsForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleFinancialMetricsUrlString = urlStringForGoogleFinancialsForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchange)
        let url = NSURL(string: googleFinancialMetricsUrlString)
        //println(url!)
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleSummaryForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        let parseSuccess = self.parseAndAddGoogleFinancialData(data, forCompany: company)
                        if completion != nil {
                            completion!(success: parseSuccess)
                        }
                    })
                    
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
    
    func urlStringForGoogleSummaryForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let escapedSymbol = symbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance?q=" + escapedExchange! + "%3A" + escapedSymbol!
        return urlString
    }
    
    func urlStringForGoogleFinancialsForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let escapedSymbol = symbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance?q=" + escapedExchange! + "%3A" + escapedSymbol! + "&fstype=ii"
        return urlString
    }
    
    func stripJsonPaddingFromData(data: NSData) -> NSData {
        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)!
        var range: NSRange = dataString.rangeOfString("(")
        range.location++
        range.length = dataString.length - range.location - 1
        return dataString.substringWithRange(range).dataUsingEncoding(NSUTF8StringEncoding)!
    }
    
    func companiesFromData(data: NSData) -> [Company] {
        
        var companies = [Company]()
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        
        // Use SwiftyJSON for handling JSON.
        let json = JSON(data: data)["ResultSet"]["Result"]
        //println(json.description)
        
        for (index: String, subJson: JSON) in json {
            
            var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
            
            if let exch = subJson["exch"].string {
                company.exchange = exch
            }
            if let exchDisp = subJson["exchDisp"].string {
                company.exchangeDisplayName = exchDisp
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
    
    func currencySymbolForCurrencyCode(currencyCode: String) -> String {
        
        switch currencyCode {
        case "AUD":
            return "$"
        case "CAD":
            return "$"
        case "CNY":
            return "¥"
        case "EGP":
            return "£"
        case "EUR":
            return "€"
        case "GBP":
            return "£"
        case "HKD":
            return "$"
        case "INR":
            return "₹"
        case "IRR":
            return "﷼"
        case "JPY":
            return "¥"
        case "KPW":
            return "₩"
        case "KRW":
            return "₩"
        case "MXN":
            return "$"
        case "RUB":
            return "₽"
        case "SAR":
            return "﷼"
        case "SGD":
            return "$"
        case "USD":
            return "$"
        default:
            return "(" + currencyCode + ")"
        }
    }
    
    func marketCapDoubleValueFromRawString(rawString: String) -> Double {
        
        var cleanedString = rawString.stringByReplacingOccurrencesOfString("\n", withString: "", options: .LiteralSearch, range: nil)
        var value: Double = 0.0
        if cleanedString.hasSuffix("T") {
            value = NSString(string: rawString.stringByReplacingOccurrencesOfString("T", withString: "", options: .LiteralSearch, range: nil)).doubleValue
            value *= 1000000000000
        } else if cleanedString.hasSuffix("B") {
            value = NSString(string: rawString.stringByReplacingOccurrencesOfString("B", withString: "", options: .LiteralSearch, range: nil)).doubleValue
            value *= 1000000000
        } else if cleanedString.hasSuffix("M") {
            value = NSString(string: rawString.stringByReplacingOccurrencesOfString("M", withString: "", options: .LiteralSearch, range: nil)).doubleValue
            value *= 1000000
        } else if cleanedString.hasSuffix("K") {
            value = NSString(string: rawString.stringByReplacingOccurrencesOfString("K", withString: "", options: .LiteralSearch, range: nil)).doubleValue
            value *= 1000
        } else {
            value = NSString(string: cleanedString).doubleValue
        }
        
        return value
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
            alert.view.tintColor = UIColor.blueColor()
            self.delegate?.webServicesManagerAPI!(self, errorAlert: alert)
        })
    }
    
    
    // MARK: - HTML Parsing
    
    func parseAndAddGoogleFinancialData(data: NSData, forCompany company: Company) -> Bool {
        
        // Arrays for calculating data.
        var revenueArray = Array<FinancialMetric>()
        var netIncomeArray = Array<FinancialMetric>()
        var operatingIncomeArray = Array<FinancialMetric>()
        var interestExpenseArray = Array<FinancialMetric>()
        var netOperatingIncomeArray = Array<FinancialMetric>()
        var unusualExpenseArray = Array<FinancialMetric>()
        var ebitArray = Array<FinancialMetric>()
        var depreciationAmortizationArray = Array<FinancialMetric>()
        var ebitdaArray = Array<FinancialMetric>()
        var ebitdaMarginArray = Array<FinancialMetric>()
        var profitMarginArray = Array<FinancialMetric>()
        var revenueGrowthArray = Array<FinancialMetric>()
        var netIncomeGrowthArray = Array<FinancialMetric>()
        var grossProfitArray = Array<FinancialMetric>()
        var grossMarginArray = Array<FinancialMetric>()
        var sgAndAArray = Array<FinancialMetric>()
        var sgAndAPercentOfRevenueArray = Array<FinancialMetric>()
        var rAndDArray = Array<FinancialMetric>()
        var rAndDPercentOfRevenueArray = Array<FinancialMetric>()
        
        let valueMultiplier: Double = 1000000.0 // Data from Google Finance is in millions.
        
        let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
        var financialMetrics = company.financialMetrics.mutableCopy() as NSMutableSet
        
        let html = NSString(data: data, encoding: NSUTF8StringEncoding)
        let parser = NDHpple(HTMLData: html!)
        
        // Currency type and symbol.
        let currencyTypePath = "//th[@class='lm lft nwp']"
        if let currencyTypeArray = parser.searchWithXPathQuery(currencyTypePath) {
            if currencyTypeArray.count > 0 {
                if let currencyTypeStringRaw = currencyTypeArray[0].firstChild?.content {
                    var spaceSplit = currencyTypeStringRaw.componentsSeparatedByString(" ")
                    company.currencyCode = spaceSplit[3]
                    company.currencySymbol = currencySymbolForCurrencyCode(company.currencyCode)
                }
            } else {
                println("\nFinancial metrics not found at URL: \(googleFinancialMetricsUrlString).\nReturn false.\n")
                return false
            }
        } else {
            println("\nFinancial metrics not found at URL: \(googleFinancialMetricsUrlString).\nReturn false.\n")
            return false
        }
        
        // Years for Google Finance metrics.
        var yearsArray = Array<Int>()
        let yearsPath = "//div[@id='incannualdiv']/table/thead/tr/th"
        if let years = parser.searchWithXPathQuery(yearsPath) {
            for (thIndex, tableHeading) in enumerate(years) {
                if thIndex > 0 {
                    if var rawYearString: String = tableHeading.firstChild?.content {
                        var spaceSplit = rawYearString.componentsSeparatedByString(" ")
                        var dashSplit = spaceSplit[3].componentsSeparatedByString("-")
                        let yearString = dashSplit[0]
                        yearsArray.append(yearString.toInt()!)
                    }
                }
            }
        } else {
            println("\nFinancial metrics not found at URL: \(googleFinancialMetricsUrlString).\nReturn false.\n")
            return false
        }
        
        // Metrics from Google Finance.
        let valuesPath = "//div[@id='incannualdiv']/table/tbody/tr"
        if let allValues = parser.searchWithXPathQuery(valuesPath) {
            
            for (trIndex, tableRow) in enumerate(allValues) {
                
                var tdIndex: Int = 0
                var financialMetricType = String()
                
                for tableData in tableRow.children! {
                    
                    if tdIndex == 0 {
                        if var rawValueString: String = tableData.firstChild?.content {
                            financialMetricType = rawValueString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            tdIndex++
                        }
                    } else {
                        var rawValueString = String()
                        var rawValueStringSet: Bool = false
                        
                        if let contentString: String = tableData.firstChild?.content {
                            rawValueString = contentString
                            rawValueStringSet = true
                        } else if let contentString: String = tableData.firstChild?.firstChild?.content {
                            rawValueString = contentString
                            rawValueStringSet = true
                        }
                        
                        if rawValueStringSet {
                            if rawValueString == "-" || rawValueString == "" {
                                rawValueString = "0.0"
                            }
                            let valueString = rawValueString.stringByReplacingOccurrencesOfString(",", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            let financialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                            financialMetric.year = yearsArray[tdIndex - 1]
                            financialMetric.type = financialMetricType
                            financialMetric.value = NSString(string: valueString).doubleValue * valueMultiplier
                            financialMetrics.addObject(financialMetric)
                            if logMetricsToConsole { println("Type: \(financialMetric.type), Year: \(financialMetric.year) Value: \(financialMetric.value)") }
                            
                            // Populate arrays for calculating metrics.
                            switch financialMetric.type {
                            case "Revenue":
                                revenueArray.append(financialMetric)
                            case "Net Income":
                                netIncomeArray.append(financialMetric)
                            case "Operating Income":
                                operatingIncomeArray.append(financialMetric)
                            case "Interest Expense(Income) - Net Operating":
                                interestExpenseArray.append(financialMetric)
                            case "Unusual Expense (Income)":
                                unusualExpenseArray.append(financialMetric)
                            case "Depreciation/Amortization":
                                depreciationAmortizationArray.append(financialMetric)
                            case "Gross Profit":
                                grossProfitArray.append(financialMetric)
                            case "Selling/General/Admin. Expenses, Total":
                                sgAndAArray.append(financialMetric)
                            case "Research & Development":
                                rAndDArray.append(financialMetric)
                            default:
                                break
                            }
                            tdIndex++
                        }
                    }
                }
            }
            
            // Sort arrays for calculations by year.
            revenueArray.sort({ $0.year < $1.year })
            netIncomeArray.sort({ $0.year < $1.year })
            operatingIncomeArray.sort({ $0.year < $1.year })
            interestExpenseArray.sort({ $0.year < $1.year })
            unusualExpenseArray.sort({ $0.year < $1.year })
            depreciationAmortizationArray.sort({ $0.year < $1.year })
            grossProfitArray.sort({ $0.year < $1.year })
            sgAndAArray.sort({ $0.year < $1.year })
            rAndDArray.sort({ $0.year < $1.year })
            
            // Add calculated metrics.
            for (index, operatingIncomeMetric) in enumerate(operatingIncomeArray) {
                
                let year = operatingIncomeMetric.year
                
                let netOperatingIncomeMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                netOperatingIncomeMetric.type = "EBIT"
                netOperatingIncomeMetric.year = year
                netOperatingIncomeMetric.value = Double(operatingIncomeMetric.value) + Double(interestExpenseArray[index].value)
                netOperatingIncomeArray.append(netOperatingIncomeMetric)
                financialMetrics.addObject(netOperatingIncomeMetric)
                
                let ebitMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                ebitMetric.type = "Normal Net Operating Income"
                ebitMetric.year = year
                ebitMetric.value = Double(netOperatingIncomeMetric.value) + Double(unusualExpenseArray[index].value)
                ebitArray.append(ebitMetric)
                financialMetrics.addObject(ebitMetric)
                
                let ebitdaMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                ebitdaMetric.type = "EBITDA"
                ebitdaMetric.year = year
                ebitdaMetric.value = Double(ebitMetric.value) + Double(depreciationAmortizationArray[index].value)
                ebitdaArray.append(ebitdaMetric)
                financialMetrics.addObject(ebitdaMetric)
                
                let ebitdaMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                ebitdaMarginMetric.type = "EBITDA Margin"
                ebitdaMarginMetric.year = year
                ebitdaMarginMetric.value = Double(revenueArray[index].value) != 0.0 ? (Double(ebitdaMetric.value) / Double(revenueArray[index].value)) * 100.0 : 0.0
                ebitdaMarginArray.append(ebitdaMarginMetric)
                financialMetrics.addObject(ebitdaMarginMetric)
                
                let profitMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                profitMarginMetric.type = "Profit Margin"
                profitMarginMetric.year = year
                profitMarginMetric.value = Double(revenueArray[index].value) != 0.0 ? (Double(netIncomeArray[index].value) / Double(revenueArray[index].value)) * 100.0 : 0.0
                profitMarginArray.append(profitMarginMetric)
                financialMetrics.addObject(profitMarginMetric)
                
                let grossMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                grossMarginMetric.type = "Gross Margin"
                grossMarginMetric.year = year
                grossMarginMetric.value = Double(revenueArray[index].value) != 0.0 ? (Double(grossProfitArray[index].value) / Double(revenueArray[index].value)) * 100.0 : 0.0
                grossMarginArray.append(grossMarginMetric)
                financialMetrics.addObject(grossMarginMetric)
                
                let sgAndAPercentOfRevenueMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                sgAndAPercentOfRevenueMetric.type = "SG&A As Percent Of Revenue"
                sgAndAPercentOfRevenueMetric.year = year
                sgAndAPercentOfRevenueMetric.value = Double(revenueArray[index].value) != 0.0 ? (Double(sgAndAArray[index].value) / Double(revenueArray[index].value)) * 100.0 : 0.0
                sgAndAPercentOfRevenueArray.append(sgAndAPercentOfRevenueMetric)
                financialMetrics.addObject(sgAndAPercentOfRevenueMetric)
                
                let rAndDPercentOfRevenueMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                rAndDPercentOfRevenueMetric.type = "R&D As Percent Of Revenue"
                rAndDPercentOfRevenueMetric.year = year
                rAndDPercentOfRevenueMetric.value = Double(revenueArray[index].value) != 0.0 ? (Double(rAndDArray[index].value) / Double(revenueArray[index].value)) * 100.0 : 0.0
                rAndDPercentOfRevenueArray.append(rAndDPercentOfRevenueMetric)
                financialMetrics.addObject(rAndDPercentOfRevenueMetric)
                
                // Calculate and add growth metrics after first year has been iterated.
                if index > 0 {
                
                    let revenueGrowthMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                    revenueGrowthMetric.type = "Revenue Growth"
                    revenueGrowthMetric.year = year
                    revenueGrowthMetric.value = Double(revenueArray[index - 1].value) != 0.0 ? ((Double(revenueArray[index].value) - Double(revenueArray[index - 1].value)) / Double(revenueArray[index - 1].value)) * 100.0 : 0.0
                    revenueGrowthArray.append(revenueGrowthMetric)
                    financialMetrics.addObject(revenueGrowthMetric)
                    
                    let netIncomeGrowthMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                    netIncomeGrowthMetric.type = "Net Income Growth"
                    netIncomeGrowthMetric.year = year
                    netIncomeGrowthMetric.value = Double(netIncomeArray[index - 1].value) != 0.0 ? ((Double(netIncomeArray[index].value) - Double(netIncomeArray[index - 1].value))  / Double(netIncomeArray[index - 1].value)) * 100.0 : 0.0
                    netIncomeGrowthArray.append(netIncomeGrowthMetric)
                    financialMetrics.addObject(netIncomeGrowthMetric)
                }
            }
            
            if logMetricsToConsole {
                for metric in netOperatingIncomeArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in ebitArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in ebitdaArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in ebitdaMarginArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in profitMarginArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in revenueGrowthArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in netIncomeGrowthArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in grossProfitArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in grossMarginArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in sgAndAPercentOfRevenueArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
                for metric in rAndDPercentOfRevenueArray {
                    println("Type: \(metric.type), Year: \(metric.year) Value: \(metric.value)")
                }
            }
            
            if financialMetrics.count < 1 {
                println("\nFinancial metrics not found at URL: \(googleFinancialMetricsUrlString).\nReturn false.\n")
                return false
            }
            
            company.financialMetrics = financialMetrics.copy() as NSSet

        } else {
            println("\nFinancial metrics not found at URL: \(googleFinancialMetricsUrlString).\nReturn false.\n")
            return false
        }
        
        return true
    }
    
    func parseAndAddGoogleSummaryData(data: NSData, forCompany company: Company) -> Bool {
        
        let html = NSString(data: data, encoding: NSUTF8StringEncoding)
        let parser = NDHpple(HTMLData: html!)
        
        let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
        var financialMetrics = company.financialMetrics.mutableCopy() as NSMutableSet
        
        var marketCapHeadingFound: Bool = false
        var marketCapTableRowIndex: Int = 0
        
        while !marketCapHeadingFound && marketCapTableRowIndex < 10 {
            marketCapTableRowIndex++
            let potentialHeadingPath = "//table[@class='snap-data']/tr[" + String(marketCapTableRowIndex) + "]/td[1]"
            
            if let potentialHeadingArray = parser.searchWithXPathQuery(potentialHeadingPath) {
                
                for node in potentialHeadingArray {
                    
                    if let rawPotentialHeading: String = node.firstChild?.content {
                        let cleanedPotentialHeading = rawPotentialHeading.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        
                        if cleanedPotentialHeading == "Mkt cap" {
                            let valuePath = "//table[@class='snap-data']/tr[" + String(marketCapTableRowIndex) + "]/td[2]"
                            
                            if let valuePathArray = parser.searchWithXPathQuery(valuePath) {
                                
                                for node in valuePathArray {
                                    
                                    if let rawValueString: String = node.firstChild?.content {
                                        let financialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                                        financialMetric.type = "Market Cap"
                                        financialMetric.year = 0
                                        financialMetric.value = marketCapDoubleValueFromRawString(rawValueString)
                                        financialMetrics.addObject(financialMetric)
                                        marketCapHeadingFound = true
                                        break
                                    }
                                }
                            }
                        }
                    }
                    if marketCapHeadingFound { break }
                }
            }
        }
        company.financialMetrics = financialMetrics.copy() as NSSet
        
        
        let descriptionPath = "//div[@class='companySummary']"
        if let companyDescription = parser.searchWithXPathQuery(descriptionPath) {
            if companyDescription.count > 0 {
                for node in companyDescription {
                    if var rawCompanyDescriptionString: String = node.firstChild?.content {
                        rawCompanyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("�", withString: "’", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        let companyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        company.companyDescription = companyDescriptionString
                    }
                }
            } else {
                println("\nDescription data not found at URL: \(googleSummaryUrlString).\nReturn false.\n")
                return false
            }
        } else {
            println("\nDescription data not found at URL: \(googleSummaryUrlString).\nReturn false.\n")
            return false
        }
        
        // Determine Address div index.
        var addressHeadingFound: Bool = false
        var addressDivIndex: Int = 0
        
        while !addressHeadingFound && addressDivIndex < 100 {
            
            addressDivIndex++
            let potentialHeadingPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[" + String(addressDivIndex) + "]/h3"
            
            if let potentialHeadingArray = parser.searchWithXPathQuery(potentialHeadingPath) {
                for node in potentialHeadingArray {
                    if let potentialHeading: String = node.firstChild?.content {
                        if potentialHeading == "Address" { addressHeadingFound = true }
                    }
                }
            }
        }
        addressDivIndex++
        
        let addressPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[" + String(addressDivIndex) + "]"
        if let address = parser.searchWithXPathQuery(addressPath) {
            for node in address {
                
                for (index, addressLine) in enumerate(node.children!) {
                    
                    switch index {
                        
                    case 0:
                        if let rawStreetString: String = addressLine.content {
                            company.street = rawStreetString
                        }
                        
                    case 2:
                        if let rawCityStateZipString: String = addressLine.content {
                            
                            var commaSplit = rawCityStateZipString.componentsSeparatedByString(",")
                            
                            if commaSplit.count > 0 {
                                
                                company.city = commaSplit[0]
                                
                                if commaSplit.count > 1 {
                                    var spaceSplit = commaSplit[1].componentsSeparatedByString(" ")
                                    if spaceSplit.count > 2 {
                                        company.state = spaceSplit[1]
                                        company.zipCode = spaceSplit[2]
                                    } else if spaceSplit.count > 1 {
                                        company.state = ""
                                        company.zipCode = spaceSplit[1]
                                    }
                                }
                                
                            } else {
                                company.city = "NA"
                            }
                        }
                        
                    case 4:
                        if let rawCountryString: String = addressLine.content {
                            let countryString = rawCountryString.stringByReplacingOccurrencesOfString("\n-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            company.country = countryString
                        }
                        
                    default:
                        break
                    }
                }
            }
        } else {
            println("\nAddress data not found at URL: \(googleSummaryUrlString).\nReturn false.\n")
            return false
        }
        
        // Determine Key Stats and Ratios div index.
        var keyStatsAndRatiosHeadingFound: Bool = false
        var keyStatsAndRatiosDivIndex: Int = 0
        
        while !keyStatsAndRatiosHeadingFound {
            
            keyStatsAndRatiosDivIndex++
            let potentialHeadingPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[" + String(keyStatsAndRatiosDivIndex) + "]/h3"
            
            if let potentialHeadingArray = parser.searchWithXPathQuery(potentialHeadingPath) {
                for node in potentialHeadingArray {
                    if let potentialHeading: String = node.firstChild?.content {
                        if potentialHeading == "Key stats and ratios" { keyStatsAndRatiosHeadingFound = true }
                    }
                }
            }
        }
        keyStatsAndRatiosDivIndex++
        
        let employeeCountPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[" + String(keyStatsAndRatiosDivIndex) + "]/table/tr[6]/td[2]"
        if let employeeCount = parser.searchWithXPathQuery(employeeCountPath) {
            for node in employeeCount {
                if let rawEmployeeCountString: String = node.firstChild?.content {
                    let employeeCountString = rawEmployeeCountString.stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
                    company.employeeCount = employeeCountString.toInt()!
                }
            }
        } else {
            println("Employee count data not found.")
        }
        
        let webLinkPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[10]/div/a"
        if let webLink = parser.searchWithXPathQuery(webLinkPath) {
            for node in webLink {
                if let rawWebLinkString: String = node.firstChild?.content {
                    let webLinkString = rawWebLinkString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    company.webLink = webLinkString
                }
            }
        } else {
            println("Web link not found.")
        }
        
        return true
    }
    
}
