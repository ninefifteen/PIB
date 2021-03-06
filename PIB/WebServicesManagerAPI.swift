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
        var _customAllowedCharacterSet = NSMutableCharacterSet(charactersInString: "!*'();:@&=+$,[]").invertedSet.mutableCopy() as! NSMutableCharacterSet
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
                
                let httpResponse = response as! NSHTTPURLResponse
                
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
                
                let httpResponse = response as! NSHTTPURLResponse
                
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
    
    func downloadGoogleSummaryForCompanyWithTickerSymbol(tickerSymbol: String, onExchange exchangeDisplayName: String, withCompletion completion: ((summaryDictionary: [String: String], success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleSummaryUrlString = urlStringForGoogleSummaryForCompanyWithTickerSymbol(tickerSymbol, onExchange: exchangeDisplayName)
        let url = NSURL(string: googleSummaryUrlString)
        //println("Google Finance Summary URL: \(url!)")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            var summaryDictionary = [String: String]()
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleSummaryForCompanyWithTickerSymbol(_:onExchange:withCompletion:) rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    summaryDictionary = self.parseGoogleSummaryData(data)
                    let parseSuccess = summaryDictionary.count > 0 ? true : false
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        if completion != nil {
                            completion!(summaryDictionary: summaryDictionary, success: parseSuccess)
                        }
                    })
                    
                } else {
                    println("Unable To Download Company Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(summaryDictionary: summaryDictionary, success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code == -999 {  // Error caused by cancelling of the data task.
                println("Error caused by cancelling of the data task. Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(summaryDictionary: summaryDictionary, success: false)
                }
            } else {  // Any other error.
                println("Unable To Download Company Data. Connection Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(summaryDictionary: summaryDictionary, success: false)
                }
                self.sendConnectionErrorMessage()
            }
            self.decrementNetworkActivityCount()
        })
        
        dataTask.resume()
    }
    
    func downloadGoogleFinancialsForCompanyWithTickerSymbol(tickerSymbol: String, onExchange exchangeDisplayName: String, withCompletion completion: ((financialDictionary: [String: AnyObject], success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleFinancialMetricsUrlString = urlStringForGoogleFinancialsForCompanyWithTickerSymbol(tickerSymbol, onExchange: exchangeDisplayName)
        let url = NSURL(string: googleFinancialMetricsUrlString)
        //println("Google Finance Financials URL: \(url!)")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            var financialDictionary = [String: AnyObject]()
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleFinancialsForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    let financialDictionary = self.parseGoogleFinancialData(data)
                    let parseSuccess = financialDictionary.count > 0 ? true : false
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        if completion != nil {
                            completion!(financialDictionary: financialDictionary, success: parseSuccess)
                        }
                    })
                    
                } else {
                    println("Unable To Download Company Financial Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(financialDictionary: financialDictionary, success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code == -999 {  // Error caused by cancelling of the data task.
                println("Error caused by cancelling of the data task. Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(financialDictionary: financialDictionary, success: false)
                }
            } else {  // Any other error.
                println("Unable To Download Company Data. Connection Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(financialDictionary: financialDictionary, success: false)
                }
                self.sendConnectionErrorMessage()
            }
            self.decrementNetworkActivityCount()
        })
        
        dataTask.resume()
    }
    
    func downloadGoogleRelatedCompaniesForCompanyWithTickerSymbol(tickerSymbol: String, onExchange exchangeDisplayName: String, withCompletion completion: ((peerCompanies: [Company], success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        googleRelatedCompaniesUrlString = urlStringForGoogleRelatedCompaniesForCompanyWithTickerSymbol(tickerSymbol, onExchange: exchangeDisplayName)
        let url = NSURL(string: googleRelatedCompaniesUrlString)
        //println("Google Related Companies URL: \(url!)")
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            var peerCompanies = [Company]()
            
            if error == nil {
                
                //let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleRelatedCompaniesForCompanyWithTickerSymbol(_:onExchange:withCompletion:) rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as! NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    peerCompanies = self.parseGoogleRelatedCompaniesData(data)
                    
                    if completion != nil {
                        completion!(peerCompanies: peerCompanies, success: true)
                    }
                    
                } else {
                    println("Unable To Download Related Companies Data. HTTP Response Status Code: \(httpResponse.statusCode)")
                    if completion != nil {
                        completion!(peerCompanies: peerCompanies, success: false)
                    }
                    self.sendGeneralErrorMessage()
                }
            } else if error.code == -999 {  // Error caused by cancelling of the data task.
                println("Error caused by cancelling of the data task. Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(peerCompanies: peerCompanies, success: false)
                }
            } else {  // Any other error.
                println("Unable To Download Company Data. Connection Error: \(error.localizedDescription)")
                if completion != nil {
                    completion!(peerCompanies: peerCompanies, success: false)
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
        let cleanedSymbol = symbol.stringByReplacingOccurrencesOfString("-", withString: ".", options: .LiteralSearch, range: nil)
        let escapedSymbol = cleanedSymbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance?q=" + escapedExchange! + "%3A" + escapedSymbol!
        //println("urlStringForGoogleSummaryForCompanyWithTickerSymbol: \(urlString)")
        return urlString
    }
    
    func urlStringForGoogleFinancialsForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let cleanedSymbol = symbol.stringByReplacingOccurrencesOfString("-", withString: ".", options: .LiteralSearch, range: nil)
        let escapedSymbol = cleanedSymbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let escapedExchange = exchange.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        var urlString = "http://www.google.com/finance?q=" + escapedExchange! + "%3A" + escapedSymbol! + "&fstype=ii"
        //println("urlStringForGoogleFinancialsForCompanyWithTickerSymbol: \(urlString)")
        return urlString
    }
    
    func urlStringForGoogleRelatedCompaniesForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let cleanedSymbol = symbol.stringByReplacingOccurrencesOfString("-", withString: ".", options: .LiteralSearch, range: nil)
        let escapedSymbol = cleanedSymbol.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
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
    
    func marketCapValueStringFromRawString(rawString: String) -> String {
        
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
        
        return toString(value)
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
    
    func parseGoogleSummaryData(data: NSData) -> [String: String] {
        
        var emptyReturn = [String: String]()
        var summaryDictionary = ["Market Cap": "", "companyDescription": "", "street": "", "city": "", "state": "", "zipCode": "", "country": "", "employeeCount": "", "webLink": ""]
        
        let html = NSString(data: data, encoding: NSUTF8StringEncoding)
        let parser = NDHpple(HTMLData: html! as String)
        
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
                                        summaryDictionary["Market Cap"] = marketCapValueStringFromRawString(rawValueString)
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
        
        var isDescriptionSet = false
        let descriptionPath = "//div[@class='companySummary']"
        if let companyDescription = parser.searchWithXPathQuery(descriptionPath) {
            if companyDescription.count > 0 {
                for node in companyDescription {
                    if var rawCompanyDescriptionString: String = node.firstChild?.content {
                        rawCompanyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("�", withString: "’", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        let companyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                        summaryDictionary["companyDescription"] = companyDescriptionString
                        isDescriptionSet = true
                    }
                }
            }
        }
        if !isDescriptionSet {
            println("Description data not found at URL: \(googleSummaryUrlString).")
            return emptyReturn
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
                            summaryDictionary["street"] = rawStreetString
                        }
                        
                    case 2:
                        if let rawCityStateZipString: String = addressLine.content {
                            
                            var commaSplit = rawCityStateZipString.componentsSeparatedByString(",")
                            
                            if commaSplit.count > 0 {
                                
                                summaryDictionary["city"] = commaSplit[0]
                                
                                if commaSplit.count > 1 {
                                    var spaceSplit = commaSplit[1].componentsSeparatedByString(" ")
                                    if spaceSplit.count > 2 {
                                        summaryDictionary["state"] = spaceSplit[1]
                                        summaryDictionary["zipCode"] = spaceSplit[2]
                                    } else if spaceSplit.count > 1 {
                                        summaryDictionary["state"] = ""
                                        summaryDictionary["zipCode"] = spaceSplit[1]
                                    }
                                }
                                
                            } else {
                                summaryDictionary["city"] = "NA"
                            }
                        }
                        
                    case 4:
                        if let rawCountryString: String = addressLine.content {
                            let countryString = rawCountryString.stringByReplacingOccurrencesOfString("\n-", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                            summaryDictionary["country"] = countryString
                        }
                        
                    default:
                        break
                    }
                }
            }
        } else {
            println("Address data not found at URL: \(googleSummaryUrlString).")
            return emptyReturn
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
                    summaryDictionary["employeeCount"] = employeeCountString
                    isEmployeeCountSet = true
                }
            }
        }
        if !isEmployeeCountSet { println("Employee count data not found.") }
        
        var isWebLinkSet = false
        let webLinkPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[10]/div/a"
        if let webLink = parser.searchWithXPathQuery(webLinkPath) {
            for node in webLink {
                if let rawWebLinkString: String = node.firstChild?.content {
                    let webLinkString = rawWebLinkString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    summaryDictionary["webLink"] = webLinkString
                    isWebLinkSet = true
                }
            }
        }
        if !isWebLinkSet { println("Web link not found.") }
        
        return summaryDictionary
    }
    
    func parseGoogleFinancialData(data: NSData) -> [String: AnyObject] {
        
        let alternateContext = NSManagedObjectContext()
        alternateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        
        var emptyReturn = [String: AnyObject]()
        var financialDictionary = [String: AnyObject]()
        var financialMetrics = [FinancialMetric]()
        
        var currencyCode = ""
        
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
        
        let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: alternateContext)
        //var financialMetrics = company.financialMetrics.mutableCopy() as NSMutableSet
        
        let html = NSString(data: data, encoding: NSUTF8StringEncoding)
        let parser = NDHpple(HTMLData: html! as String)
        
        // Currency type.
        var isCurrencySet = false
        let currencyTypePath = "//th[@class='lm lft nwp']"
        if let currencyTypeArray = parser.searchWithXPathQuery(currencyTypePath) {
            if currencyTypeArray.count > 0 {
                if let currencyTypeStringRaw = currencyTypeArray[0].firstChild?.content {
                    var spaceSplit = currencyTypeStringRaw.componentsSeparatedByString(" ")
                    currencyCode = spaceSplit[3]
                    financialDictionary["currencyCode"] = currencyCode
                    financialDictionary["currencySymbol"] = currencySymbolForCurrencyCode(currencyCode)
                    isCurrencySet = true
                }
            }
        }
        if !isCurrencySet {
            println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString). Return false.")
            return emptyReturn
        }
        
        // Download currency exchange rate if necessary.
        var exchangeRate: Double = 1.0
        if currencyCode != "USD" {
            exchangeRate = downloadCurrencyExchangeRateFrom(currencyCode, to: "USD")
            if exchangeRate < 0.0 { // Exchange rate was not available.
                exchangeRate = 1.0
            } else {
                currencyCode = "USD"
                financialDictionary["currencyCode"] = currencyCode
                financialDictionary["currencySymbol"] = currencySymbolForCurrencyCode(currencyCode)
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
                            println("Unable to read data found at URL: \(googleFinancialMetricsUrlString). Return false.")
                            return emptyReturn
                        }
                    }
                }
            }
        } else {
            println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString). Return false.")
            return emptyReturn
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
                            let financialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                            financialMetric.date = datesArray[tdIndex - 1]
                            financialMetric.type = financialMetricType
                            financialMetric.value = NSString(string: valueString).doubleValue * valueMultiplier * exchangeRate
                            financialMetrics.append(financialMetric)
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
                
                let netOperatingIncomeMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                netOperatingIncomeMetric.type = "EBIT"
                netOperatingIncomeMetric.date = date
                netOperatingIncomeMetric.value = Double(operatingIncomeMetric.value) + Double(interestExpenseArray[index].value)
                netOperatingIncomeArray.append(netOperatingIncomeMetric)
                financialMetrics.append(netOperatingIncomeMetric)
                
                let ebitMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                ebitMetric.type = "Normal Net Operating Income"
                ebitMetric.date = date
                ebitMetric.value = Double(netOperatingIncomeMetric.value) + Double(unusualExpenseArray[index].value)
                ebitArray.append(ebitMetric)
                financialMetrics.append(ebitMetric)
                
                let ebitdaMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                ebitdaMetric.type = "EBITDA"
                ebitdaMetric.date = date
                ebitdaMetric.value = Double(ebitMetric.value) + Double(depreciationAmortizationArray[index].value)
                ebitdaArray.append(ebitdaMetric)
                financialMetrics.append(ebitdaMetric)
                
                let ebitdaMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                ebitdaMarginMetric.type = "EBITDA Margin"
                ebitdaMarginMetric.date = date
                ebitdaMarginMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(ebitdaMetric.value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                ebitdaMarginArray.append(ebitdaMarginMetric)
                financialMetrics.append(ebitdaMarginMetric)
                
                let profitMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                profitMarginMetric.type = "Profit Margin"
                profitMarginMetric.date = date
                profitMarginMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(netIncomeArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                profitMarginArray.append(profitMarginMetric)
                financialMetrics.append(profitMarginMetric)
                
                let grossMarginMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                grossMarginMetric.type = "Gross Margin"
                grossMarginMetric.date = date
                grossMarginMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(grossProfitArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                grossMarginArray.append(grossMarginMetric)
                financialMetrics.append(grossMarginMetric)
                
                let sgAndAPercentOfRevenueMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                sgAndAPercentOfRevenueMetric.type = "SG&A As Percent Of Revenue"
                sgAndAPercentOfRevenueMetric.date = date
                sgAndAPercentOfRevenueMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(sgAndAArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                sgAndAPercentOfRevenueArray.append(sgAndAPercentOfRevenueMetric)
                financialMetrics.append(sgAndAPercentOfRevenueMetric)
                
                let rAndDPercentOfRevenueMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                rAndDPercentOfRevenueMetric.type = "R&D As Percent Of Revenue"
                rAndDPercentOfRevenueMetric.date = date
                rAndDPercentOfRevenueMetric.value = Double(totalRevenueArray[index].value) != 0.0 ? (Double(rAndDArray[index].value) / Double(totalRevenueArray[index].value)) * 100.0 : 0.0
                rAndDPercentOfRevenueArray.append(rAndDPercentOfRevenueMetric)
                financialMetrics.append(rAndDPercentOfRevenueMetric)
                
                // Calculate and add growth metrics after first date has been iterated.
                if index > 0 {
                    
                    let revenueGrowthMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                    revenueGrowthMetric.type = "Revenue Growth"
                    revenueGrowthMetric.date = date
                    revenueGrowthMetric.value = Double(totalRevenueArray[index - 1].value) != 0.0 ? ((Double(totalRevenueArray[index].value) - Double(totalRevenueArray[index - 1].value)) / Double(totalRevenueArray[index - 1].value)) * 100.0 : 0.0
                    revenueGrowthArray.append(revenueGrowthMetric)
                    financialMetrics.append(revenueGrowthMetric)
                    
                    let netIncomeGrowthMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: nil)
                    netIncomeGrowthMetric.type = "Net Income Growth"
                    netIncomeGrowthMetric.date = date
                    netIncomeGrowthMetric.value = Double(netIncomeArray[index - 1].value) != 0.0 ? ((Double(netIncomeArray[index].value) - Double(netIncomeArray[index - 1].value))  / Double(netIncomeArray[index - 1].value)) * 100.0 : 0.0
                    netIncomeGrowthArray.append(netIncomeGrowthMetric)
                    financialMetrics.append(netIncomeGrowthMetric)
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
                println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString). Return false.")
                return emptyReturn
            }
            
            financialDictionary["financialMetrics"] = financialMetrics
            
        } else {
            println("Financial metrics not found at URL: \(googleFinancialMetricsUrlString). Return false.")
            return emptyReturn
        }
        
        return financialDictionary
    }
    
    func parseGoogleRelatedCompaniesData(data: NSData) -> [Company] {
        
        let alternateContext = NSManagedObjectContext()
        alternateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        
        var companies = [Company]()
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: alternateContext)
        
        let rawStringData = NSString(data: data, encoding: NSNonLossyASCIIStringEncoding)! as String
        //println("WebServicesManagerAPI parseGoogleRelatedCompaniesData rawStringData:\n\(rawStringData)")
        
        var rawCompaniesInfoStringArray = [String]()
        
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
        let alternateContext = NSManagedObjectContext()
        alternateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: alternateContext)
        
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
