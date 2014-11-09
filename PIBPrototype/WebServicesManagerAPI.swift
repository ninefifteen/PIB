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
    
    var managedObjectContext: NSManagedObjectContext!
    var networkActivityCount: Int = 0
    var activeDataTask: NSURLSessionDataTask?
    weak var delegate: WebServicesMangerAPIDelegate?
    
    
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
        
        let url = NSURL(string: urlStringForGoogleSummaryForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchange))
        //println(url)
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleSummaryForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        
                        self.parseAndAddGoogleSummaryData(data, forCompany: company)
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
    
    func downloadGoogleFinancialsForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        let url = NSURL(string: urlStringForGoogleFinancialsForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchange))
        //println(url)
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url!, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
                //println("WebServicesManagerAPI downloadGoogleSummaryForCompany rawStringData:\n\(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
                    dispatch_sync(dispatch_get_main_queue(), { () -> Void in
                        //self.addFinancialDataToCompany(company, fromData: data)
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
    
    func urlStringForGoogleSummaryForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let urlString = "http://www.google.com/finance?q=" + exchange + "%3A" + symbol
        return urlString
    }
    
    func urlStringForGoogleFinancialsForCompanyWithTickerSymbol(symbol: String, onExchange exchange: String) -> String {
        let urlString = "http://www.google.com/finance?q=" + exchange + "%3A" + symbol + "&fstype=ii"
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
    
    func addFinancialDataToCompany(company: Company, fromData data: NSData) {
        
        let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)!
        //println("rawStringData: \(rawStringData)")
        
        let json = JSON(data: data)["ReturnData"]
        //println(json)
        
        let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
        var financialMetrics = company.financialMetrics.mutableCopy() as NSMutableSet
        
        for (index: String, subJson: JSON) in json {
            
            if let type = subJson["Type"].string {
                
                for (index: String, subJson: JSON) in subJson["Data"] {
                    
                    let financialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                    
                    financialMetric.type = type
                    financialMetric.year = subJson["Year"].intValue
                    financialMetric.value = subJson["Value"].doubleValue
                    
                    financialMetrics.addObject(financialMetric)
                }
                
                company.financialMetrics = financialMetrics.copy() as NSSet
            }
        }
        
        // Save the context.
        var error: NSError? = nil
        if !managedObjectContext.save(&error) {
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
    
    
    // MARK: - HTML Parsing
    
    func parseAndAddGoogleSummaryData(data: NSData, forCompany company: Company) {
        
        let html = NSString(data: data, encoding: NSUTF8StringEncoding)
        let parser = NDHpple(HTMLData: html!)
        
        println("\nDescription:")
        
        let descriptionPath = "//div[@class='companySummary']"
        if let companyDescription = parser.searchWithXPathQuery(descriptionPath) {
            for node in companyDescription {
                if let rawCompanyDescriptionString: String = node.firstChild?.content {
                    let cleanedCompanyDescriptionString = rawCompanyDescriptionString.stringByReplacingOccurrencesOfString("\n", withString: "", options: NSStringCompareOptions.LiteralSearch, range: nil)
                    println(cleanedCompanyDescriptionString)
                }
            }
        }
        
        println("\nAddress:")
        
        let addressPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[8]"
        if let address = parser.searchWithXPathQuery(addressPath) {
            for node in address {
                for child in node.children! {
                    println(child.content?)
                }
            }
        }
        
        println("\nEmployees:")
        
        let employeesPath = "//div[@class='g-section g-tpl-right-1 sfe-break-top-5']/div[@class='g-unit g-first']/div[@class='g-c']/div[6]/table/tr[6]/td[2]"
        if let employees = parser.searchWithXPathQuery(employeesPath) {
            for node in employees {
                println(node.firstChild?.content?)
            }
        }
    }
    
}
