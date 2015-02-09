//
//  WebServicesManagerAPI.swift
//  PIB
//
//  Created by Shawn Seals on 10/6/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//


import CoreData

class WebServicesManagerAPI: NSObject {
    
    // MARK: - Singleton
    
    class var sharedInstance: WebServicesManagerAPI {
        struct Singleton {
            static let instance = WebServicesManagerAPI()
        }
        return Singleton.instance
    }
    
    
    // MARK: - Properties
    
    var managedObjectContext: NSManagedObjectContext!
    var networkActivityCount: Int = 0
    var activeDataTask: NSURLSessionDataTask?
    
    var customAllowedCharacterSet: NSCharacterSet {
        var _customAllowedCharacterSet = NSMutableCharacterSet(charactersInString: "!*'();:@&=+$,[]").invertedSet.mutableCopy() as NSMutableCharacterSet
        _customAllowedCharacterSet.formIntersectionWithCharacterSet(NSCharacterSet.URLHostAllowedCharacterSet())
        return _customAllowedCharacterSet
    }
    
    // Debugging properties.
    var logMetricsToConsole: Bool = false
    var googleSummaryUrlString = String()
    var googleFinancialMetricsUrlString = String()
    var googleRelatedCompaniesUrlString = String()
    
    
    // MARK: - Main Methods
    
    func downloadCurrencyExchangeRateFrom(fromCurrency: String, to toCurrency: String) -> Double {  // Note: Synchronous network request.
        
        //println("URL: \(urlStringForExchangeRateFrom(fromCurrency, to: toCurrency))")
        let url = NSURL(string: urlStringForExchangeRateFrom(fromCurrency, to: toCurrency))
        let request = NSURLRequest(URL: url!)
        var response: NSURLResponse? = nil
        var error: NSError? = nil
        let responseData = NSURLConnection.sendSynchronousRequest(request, returningResponse: &response, error: &error) as NSData?
        
        if error == nil {
            if let httpResponse = response as? NSHTTPURLResponse {
                if httpResponse.statusCode == 200 {
                    
                    if let data = responseData {
                        
                        //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                        //println("WebServicesManagerAPI downloadCurrencyExchangeRateFrom rawStringData:\n\(rawStringData)")
                        
                        if let exchangeRateString = JSON(data: data)["query"]["results"]["rate"]["Rate"].string {
                            return (exchangeRateString as NSString).doubleValue
                        }
                        
                    } else {
                        println("Unable To Download Exhchange Rate Data. Response Data is nil")
                    }
                } else {
                    println("Unable To Download Exhchange Rate Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                }
            } else {
                println("Unable To Download Exhchange Rate Data. HTTP Response Status Code is nil")
            }
        } else {
            println("Unable To Download Exchange Rate Data. Connection Error: \(error?.localizedDescription)")
        }
        
        return -1.0 // Return of negative value indicates failure of function.
    }
    
    func downloadCompaniesMatchingSearchTerm(searchTerm: String, withCompletion completion: ((companies: [Company], success: Bool) -> Void)?) {
        
        if activeDataTask?.state == NSURLSessionTaskState.Running {
            activeDataTask?.cancel()
        }
        
        incrementNetworkActivityCount()
        
        let url = NSURL(string: urlStringForSearchString(searchTerm))
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            var companies = [Company]()
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadCompaniesMatchingSearchTerm rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    let paddingStrippedData = self.stripJsonPaddingFromData(data)
                    
                    companies = self.companiesFromYahooData(paddingStrippedData)
                    
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
    
    func checkConnectionToGoogleFinanceWithCompletion(completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        let url = NSURL(string: "http://www.google.com/finance")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        if completion != nil {
                            completion!(success: true)
                        }
                    })
                    
                } else {
                    println("http://www.google.com/finance HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(success: false)
                    }
                }
            } else if error.code != -999 {  // Error not caused by cancelling of the data task.
                println("http://www.google.com/finance Connection Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(success: false)
                }
            }
            self.decrementNetworkActivityCount()
        })
        
        dataTask.resume()
    }
    
    func downloadGoogleSummaryForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleSummaryUrlString = urlStringForGoogleSummaryForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName)
        let url = NSURL(string: googleSummaryUrlString)
        //println("Google Finance Summary URL: \(url!)")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
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
            } else if error.code == -999 {  // Error caused by cancelling of the data task.
                println("Error caused by cancelling of the data task. Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(success: false)
                }
            } else {  // Any other error.
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
        
        googleFinancialMetricsUrlString = urlStringForGoogleFinancialsForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName)
        let url = NSURL(string: googleFinancialMetricsUrlString)
        //println("Google Finance Financials URL: \(url!)")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleFinancialsForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        let parseSuccess = self.parseAndAddGoogleFinancialData(data, forCompany: company)
                        if completion != nil {
                            completion!(success: parseSuccess)
                        }
                    })
                    
                } else {
                    println("Unable To Download Company Financial Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code == -999 {  // Error caused by cancelling of the data task.
                println("Error caused by cancelling of the data task. Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(success: false)
                }
            } else {  // Any other error.
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
    
    func downloadGoogleRelatedCompaniesForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleRelatedCompaniesUrlString = urlStringForGoogleRelatedCompaniesForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName)
        let url = NSURL(string: googleRelatedCompaniesUrlString)
        //println("Google Related Companies URL: \(url!)")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleRelatedCompaniesForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    self.addGoogleRelatedCompaniesFromData(data, forCompany: company, withCompletion: { (success) -> Void in
                        if completion != nil {
                            completion!(success: success)
                        }
                    })
                    
                } else {
                    println("Unable To Download Related Companies Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code == -999 {  // Error caused by cancelling of the data task.
                println("Error caused by cancelling of the data task. Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(success: false)
                }
            } else {  // Any other error.
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
    
    func urlStringForExchangeRateFrom(fromCurrency: String, to toCurrency: String) -> String {
        let urlString = "http://query.yahooapis.com/v1/public/yql?q=select%20%2a%20from%20yahoo.finance.xchange%20where%20pair%20in%20%28%22" + fromCurrency + toCurrency + "%22%29&format=json&env=store://datatables.org/alltableswithkeys"
        return urlString
    }
    
    func urlStringForSearchString(searchString: String) -> String {
        var escapedSearchString = searchString.stringByAddingPercentEncodingWithAllowedCharacters(customAllowedCharacterSet)!
        let urlString = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=" + escapedSearchString + "&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
        //println("urlStringForSearchString: \(urlString)")
        return urlString
    }
    
    func urlStringForGoogleSummaryForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let escapedSymbol = symbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance?q=" + escapedExchange! + "%3A" + escapedSymbol!
        //println("urlStringForGoogleSummaryForCompanyWithTickerSymbol: \(urlString)")
        return urlString
    }
    
    func urlStringForGoogleFinancialsForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let escapedSymbol = symbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance?q=" + escapedExchange! + "%3A" + escapedSymbol! + "&fstype=ii"
        //println("urlStringForGoogleFinancialsForCompanyWithTickerSymbol: \(urlString)")
        return urlString
    }
    
    func urlStringForGoogleRelatedCompaniesForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let escapedSymbol = symbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance/related?q=" + escapedExchange! + "%3A" + escapedSymbol!
        //println("urlStringForGoogleRelatedCompaniesForCompanyWithTickerSymbol: \(urlString)")
        return urlString
    }
    
    func stripJsonPaddingFromData(data: NSData) -> NSData {
        let dataString = NSString(data: data, encoding: NSUTF8StringEncoding)!
        var range: NSRange = dataString.rangeOfString("(")
        range.location++
        range.length = dataString.length - range.location - 1
        return dataString.substringWithRange(range).dataUsingEncoding(NSUTF8StringEncoding)!
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
        NSNotificationCenter.defaultCenter().postNotificationName("WebServicesManagerAPIGeneralErrorMessage", object: nil)
    }
    
    func sendConnectionErrorMessage() {
        NSNotificationCenter.defaultCenter().postNotificationName("WebServicesManagerAPIConnectionErrorMessage", object: nil)
    }
    
    
    // MARK: - Parsing
    
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
                                        financialMetric.date = NSDate()
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
        
        var isDescriptionSet = false
        let descriptionPath = "//div[@class='companySummary']"
        if let companyDescription = parser.searchWithXPathQuery(descriptionPath) {
            if companyDescription.count > 0 {
                for node in companyDescription {
                    if var rawCompanyDescriptionString: String = node.firstChild?.content {
                        rawCompanyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("�", withString: "’", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        let companyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        company.companyDescription = companyDescriptionString
                        isDescriptionSet = true
                    }
                }
            }
        }
        if !isDescriptionSet {
            println("Description data not found at URL: \(googleSummaryUrlString), for company name: \(company.name). Return false.")
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
            println("Address data not found at URL: \(googleSummaryUrlString), for company name: \(company.name). Return false.")
            return false
        }
        
        // Determine Key Stats and Ratios div index.
        var keyStatsAndRatiosHeadingFound: Bool = false
        var keyStatsAndRatiosDivIndex: Int = 0
        
        while !keyStatsAndRatiosHeadingFound && keyStatsAndRatiosDivIndex < 200 {
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
        
        var isEmployeeCountSet = false
        let employeeCountPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[" + String(keyStatsAndRatiosDivIndex) + "]/table/tr[6]/td[2]"
        if let employeeCount = parser.searchWithXPathQuery(employeeCountPath) {
            for node in employeeCount {
                if let rawEmployeeCountString: String = node.firstChild?.content {
                    let employeeCountString = rawEmployeeCountString.stringByReplacingOccurrencesOfString("[^0-9]", withString: "", options: NSStringCompareOptions.RegularExpressionSearch, range: nil)
                    if let employeeCountInt = employeeCountString.toInt() {
                        company.employeeCount = employeeCountInt
                        isEmployeeCountSet = true
                    }
                }
            }
        }
        if !isEmployeeCountSet { println("Employee count data not found for company name: \(company.name).") }
        
        var isWebLinkSet = false
        let webLinkPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[10]/div/a"
        if let webLink = parser.searchWithXPathQuery(webLinkPath) {
            for node in webLink {
                if let rawWebLinkString: String = node.firstChild?.content {
                    let webLinkString = rawWebLinkString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    company.webLink = webLinkString
                    isWebLinkSet = true
                }
            }
        }
        if !isWebLinkSet { println("Web link not found.") }
        
        return true
    }
    
    func parseAndAddGoogleFinancialData(data: NSData, forCompany company: Company) -> Bool {
        
        // Arrays for calculating data.
        var revenueArray = Array<FinancialMetric>()
        var totalRevenueArray = Array<FinancialMetric>()
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
        
        // Currency type.
        var isCurrencySet = false
        let currencyTypePath = "//th[@class='lm lft nwp']"
        if let currencyTypeArray = parser.searchWithXPathQuery(currencyTypePath) {
            if currencyTypeArray.count > 0 {
                if let currencyTypeStringRaw = currencyTypeArray[0].firstChild?.content {
                    var spaceSplit = currencyTypeStringRaw.componentsSeparatedByString(" ")
                    company.currencyCode = spaceSplit[3]
                    company.currencySymbol = currencySymbolForCurrencyCode(company.currencyCode)
                    isCurrencySet = true
                }
            }
        }
        if !isCurrencySet {
            println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString), for company name: \(company.name). Return false.")
            return false
        }
        
        // Download currency exchange rate if necessary.
        var exchangeRate: Double = 1.0
        if company.currencyCode != "USD" {
            exchangeRate = downloadCurrencyExchangeRateFrom(company.currencyCode, to: "USD")
            if exchangeRate < 0.0 { // Exchange rate was not available.
                exchangeRate = 1.0
            } else {
                company.currencyCode = "USD"
                company.currencySymbol = currencySymbolForCurrencyCode(company.currencyCode)
            }
        }
        
        // Dates for Google Finance metrics.
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        var datesArray = Array<NSDate>()
        let datesPath = "//div[@id='incannualdiv']/table/thead/tr/th"
        if let dates = parser.searchWithXPathQuery(datesPath) {
            for (thIndex, tableHeading) in enumerate(dates) {
                if thIndex > 0 {
                    if var rawDateString: String = tableHeading.firstChild?.content {
                        var spaceSplit = rawDateString.componentsSeparatedByString(" ")
                        var cleanedDateString: String = spaceSplit[3].stringByReplacingOccurrencesOfString("\n", withString: "", options: .LiteralSearch, range: nil)
                        if let date = dateFormatter.dateFromString(cleanedDateString) {
                            datesArray.append(date)
                        } else {
                            println("Unable to read data found at URL: \(googleFinancialMetricsUrlString), for company name: \(company.name). Return false.")
                            return false
                        }
                    }
                }
            }
        } else {
            println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString), for company name: \(company.name). Return false.")
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
                            financialMetric.date = datesArray[tdIndex - 1]
                            financialMetric.type = financialMetricType
                            financialMetric.value = NSString(string: valueString).doubleValue * valueMultiplier * exchangeRate
                            financialMetrics.addObject(financialMetric)
                            if logMetricsToConsole { println("Type: \(financialMetric.type), Date: \(dateFormatter.stringFromDate(financialMetric.date)), Value: \(financialMetric.value)") }
                            
                            // Populate arrays for calculating metrics.
                            switch financialMetric.type {
                            case "Revenue":
                                revenueArray.append(financialMetric)
                            case "Total Revenue":
                                totalRevenueArray.append(financialMetric)
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
            
            // Sort arrays for calculations by date.
            revenueArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            totalRevenueArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            netIncomeArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            operatingIncomeArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            interestExpenseArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            unusualExpenseArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            depreciationAmortizationArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            grossProfitArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            sgAndAArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            rAndDArray.sort({ $0.date.compare($1.date) == NSComparisonResult.OrderedAscending })
            
            // Add calculated metrics.
            for (index, operatingIncomeMetric) in enumerate(operatingIncomeArray) {
                
                let date = operatingIncomeMetric.date
                
                let netOperatingIncomeMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                netOperatingIncomeMetric.type = "EBIT"
                netOperatingIncomeMetric.date = date
                netOperatingIncomeMetric.value = Double(operatingIncomeMetric.value) + Double(interestExpenseArray[index].value)
                netOperatingIncomeArray.append(netOperatingIncomeMetric)
                financialMetrics.addObject(netOperatingIncomeMetric)
                
                let ebitMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                ebitMetric.type = "Normal Net Operating Income"
                ebitMetric.date = date
                ebitMetric.value = Double(netOperatingIncomeMetric.value) + Double(unusualExpenseArray[index].value)
                ebitArray.append(ebitMetric)
                financialMetrics.addObject(ebitMetric)
                
                let ebitdaMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                ebitdaMetric.type = "EBITDA"
                ebitdaMetric.date = date
                ebitdaMetric.value = Double(ebitMetric.value) + Double(depreciationAmortizationArray[index].value)
                ebitdaArray.append(ebitdaMetric)
                financialMetrics.addObject(ebitdaMetric)
                
                let ebitdaMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                ebitdaMarginMetric.type = "EBITDA Margin"
                ebitdaMarginMetric.date = date
                ebitdaMarginMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(ebitdaMetric.value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                ebitdaMarginArray.append(ebitdaMarginMetric)
                financialMetrics.addObject(ebitdaMarginMetric)
                
                let profitMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                profitMarginMetric.type = "Profit Margin"
                profitMarginMetric.date = date
                profitMarginMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(netIncomeArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                profitMarginArray.append(profitMarginMetric)
                financialMetrics.addObject(profitMarginMetric)
                
                let grossMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                grossMarginMetric.type = "Gross Margin"
                grossMarginMetric.date = date
                grossMarginMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(grossProfitArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                grossMarginArray.append(grossMarginMetric)
                financialMetrics.addObject(grossMarginMetric)
                
                let sgAndAPercentOfRevenueMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                sgAndAPercentOfRevenueMetric.type = "SG&A As Percent Of Revenue"
                sgAndAPercentOfRevenueMetric.date = date
                sgAndAPercentOfRevenueMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(sgAndAArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                sgAndAPercentOfRevenueArray.append(sgAndAPercentOfRevenueMetric)
                financialMetrics.addObject(sgAndAPercentOfRevenueMetric)
                
                let rAndDPercentOfRevenueMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                rAndDPercentOfRevenueMetric.type = "R&D As Percent Of Revenue"
                rAndDPercentOfRevenueMetric.date = date
                rAndDPercentOfRevenueMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(rAndDArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                rAndDPercentOfRevenueArray.append(rAndDPercentOfRevenueMetric)
                financialMetrics.addObject(rAndDPercentOfRevenueMetric)
                
                // Calculate and add growth metrics after first date has been iterated.
                if index > 0 {
                    
                    let revenueGrowthMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                    revenueGrowthMetric.type = "Revenue Growth"
                    revenueGrowthMetric.date = date
                    revenueGrowthMetric.value = Double(totalRevenueArray[index - 1].value) != 0.0 ? ((Double(totalRevenueArray[index].value) - Double(totalRevenueArray[index - 1].value)) / Double(totalRevenueArray[index - 1].value)) * 100.0 : 0.0
                    revenueGrowthArray.append(revenueGrowthMetric)
                    financialMetrics.addObject(revenueGrowthMetric)
                    
                    let netIncomeGrowthMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                    netIncomeGrowthMetric.type = "Net Income Growth"
                    netIncomeGrowthMetric.date = date
                    netIncomeGrowthMetric.value = Double(netIncomeArray[index - 1].value) != 0.0 ? ((Double(netIncomeArray[index].value) - Double(netIncomeArray[index - 1].value))  / Double(netIncomeArray[index - 1].value)) * 100.0 : 0.0
                    netIncomeGrowthArray.append(netIncomeGrowthMetric)
                    financialMetrics.addObject(netIncomeGrowthMetric)
                }
            }
            
            if logMetricsToConsole {
                for metric in netOperatingIncomeArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in ebitArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in ebitdaArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in ebitdaMarginArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in profitMarginArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in revenueGrowthArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in netIncomeGrowthArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in grossProfitArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in grossMarginArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in sgAndAPercentOfRevenueArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
                for metric in rAndDPercentOfRevenueArray {
                    println("Type: \(metric.type), Date: \(dateFormatter.stringFromDate(metric.date)), Value: \(metric.value)")
                }
            }
            
            if financialMetrics.count < 1 {
                println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString), for company name: \(company.name). Return false.")
                return false
            }
            
            company.financialMetrics = financialMetrics.copy() as NSSet
            
        } else {
            println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString), for company name: \(company.name). Return false.")
            return false
        }
        
        return true
    }
    
    func addGoogleRelatedCompaniesFromData(data: NSData, forCompany company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        let relatedCompanies = parseGoogleRelatedCompaniesData(data)
        var savedRelatedCompanies = [Company]()
        var unsavedRelatedCompanies = [Company]()
        
        if relatedCompanies.count > 0 {
            
            for relatedCompany in relatedCompanies {
                if Company.isSavedCompanyWithTickerSymbol(relatedCompany.tickerSymbol, exchangeDisplayName: relatedCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
                    savedRelatedCompanies.append(relatedCompany)
                } else {
                    unsavedRelatedCompanies.append(relatedCompany)
                }
            }
            
            for savedRelatedCompany in savedRelatedCompanies {
                company.addPeerCompanyWithTickerSymbol(savedRelatedCompany.tickerSymbol, withExchangeDisplayName: savedRelatedCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
            }
            
            let dispatchGroup = dispatch_group_create()
            
            let count = unsavedRelatedCompanies.count
            var index = 1
            for unsavedRelatedCompany in unsavedRelatedCompanies {
                dispatch_group_enter(dispatchGroup)
                Company.saveNewPeerCompanyWithName(unsavedRelatedCompany.name, tickerSymbol: unsavedRelatedCompany.tickerSymbol, exchangeDisplayName: unsavedRelatedCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext, withCompletion: { (success) -> Void in
                    if success {
                        company.addPeerCompanyWithTickerSymbol(unsavedRelatedCompany.tickerSymbol, withExchangeDisplayName: unsavedRelatedCompany.exchangeDisplayName, inManagedObjectContext: self.managedObjectContext)
                    }
                    dispatch_group_leave(dispatchGroup)
                })
                index++
            }
            
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
                if completion != nil {
                    completion!(success: true)
                }
            }
            
        } else {
            
            if completion != nil {
                completion!(success: true)
            }
        }
    }
    
    func parseGoogleRelatedCompaniesData(data: NSData) -> Array<Company> {
        
        var companies = [Company]()
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        
        let rawStringData = NSString(data: data, encoding: NSNonLossyASCIIStringEncoding)! as String
        //println("WebServicesManagerAPI parseGoogleRelatedCompaniesData rawStringData:\n\(rawStringData)")
        
        var rawCompaniesInfoStringArray = Array<String>()
        
        if rawStringData.rangeOfString("google.finance.data = ", options: .LiteralSearch, range: nil, locale: nil) != nil {
            let firstSplit = rawStringData.componentsSeparatedByString("google.finance.data = ")
            if firstSplit.count > 0 {
                if firstSplit[1].rangeOfString(";\ngoogle.finance.data.numberFormat", options: .LiteralSearch, range: nil, locale: nil) != nil {
                    let secondSplit = firstSplit[1].componentsSeparatedByString(";\ngoogle.finance.data.numberFormat")
                    if secondSplit.count > 0 {
                        if secondSplit[0].rangeOfString("values:", options: .LiteralSearch, range: nil, locale: nil) != nil {
                            rawCompaniesInfoStringArray = secondSplit[0].componentsSeparatedByString("values:")
                            if rawCompaniesInfoStringArray.count > 0 {
                                rawCompaniesInfoStringArray.removeAtIndex(0)
                                rawCompaniesInfoStringArray.removeAtIndex(0)
                            }
                        }
                    }
                }
            }
        }
        
        for rawCompanyInfoString in rawCompaniesInfoStringArray {
            
            var companyInfoString = rawCompanyInfoString.componentsSeparatedByString("}")[0]
            companyInfoString = companyInfoString.stringByReplacingOccurrencesOfString("[", withString: "", options: .LiteralSearch, range: nil)
            companyInfoString = companyInfoString.stringByReplacingOccurrencesOfString("]", withString: "", options: .LiteralSearch, range: nil)
            companyInfoString = companyInfoString.stringByReplacingOccurrencesOfString(" \"", withString: "", options: .LiteralSearch, range: nil)
            companyInfoString = companyInfoString.stringByReplacingOccurrencesOfString("\"", withString: "", options: .LiteralSearch, range: nil)
            
            var cleanedCompanyInfoArray = companyInfoString.componentsSeparatedByString(",")
            
            //println("cleanedCompanyInfoArray count: \(cleanedCompanyInfoArray.count) content: \(cleanedCompanyInfoArray)")
            
            let indexOfExchangeDisplayName = cleanedCompanyInfoArray.count - 3
            let exchangeDisplayName = cleanedCompanyInfoArray[indexOfExchangeDisplayName]
            
            if exchangeDisplayName != "" {
                
                let tickerSymbol = cleanedCompanyInfoArray[0]
                let companyName = cleanedCompanyInfoArray[1]
                //println("tickerSymbol: \(tickerSymbol), companyName: \(companyName), exchangeDisplayName: \(exchangeDisplayName)")
                
                var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
                company.exchangeDisplayName = exchangeDisplayName
                company.tickerSymbol = tickerSymbol
                company.name = companyName
                
                companies.append(company)
            }
        }
        
        return companies
    }
    
    func companiesFromYahooData(data: NSData) -> [Company] {
        
        var companies = [Company]()
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        
        // Use SwiftyJSON for handling JSON.
        let json = JSON(data: data)["ResultSet"]["Result"]
        //println(json.description)
        
        for (index: String, subJson: JSON) in json {
            
            if let type = subJson["type"].string {
                if type == "S" {
                    if let tickerSymbol = subJson["symbol"].string {
                        if tickerSymbol.rangeOfString(".") == nil {
                            var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
                            company.tickerSymbol = tickerSymbol
                            if var exchDisp = subJson["exchDisp"].string {
                                if exchDisp == "OTC Markets" { exchDisp = "OTCMKTS" }
                                company.exchangeDisplayName = exchDisp
                            }
                            if let exch = subJson["exch"].string {
                                company.exchange = exch
                            }
                            if let name = subJson["name"].string {
                                company.name = name
                            }
                            
                            companies.append(company)
                        }
                    }
                }
            }
        }
        
        return companies
    }
    
}
