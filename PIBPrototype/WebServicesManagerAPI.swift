//
//  WebServicesManagerAPI.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/6/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
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
    
    func downloadDescriptionForCompany(company: Company, withCompletion completion: ((success: Bool) -> Void)?) {
        
        incrementNetworkActivityCount()
        
        // Reduce company.exchangeDisp to first 3 characters.
        var range = NSMakeRange(0, 3)
        var abbreviatedExchDisp: String! = (company.exchangeDisp as NSString).substringWithRange(range)
        
        let tickerSymbol: String! = company.tickerSymbol
        
        let urlString = "http://msn.com/en-us/money/stockdetails/fi-126.1.\(tickerSymbol).\(abbreviatedExchDisp)?symbol=\(tickerSymbol)&form=PRFISB"
        println(urlString)
        
        let url = NSURL.URLWithString(urlString)
        
        let dataTask = NSURLSession.sharedSession().dataTaskWithURL(url, completionHandler: { (data, response, error) -> Void in
            
            if error == nil {
                
                let rawStringData: String = NSString(data: data, encoding: NSUTF8StringEncoding)
                println("rawStringData: \(rawStringData)")
                
                let httpResponse = response as NSHTTPURLResponse
                
                if httpResponse.statusCode == 200 {
                    
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
        
        activeDataTask = dataTask
        dataTask.resume()
    }
    
    // MARK: - Helper Methods
    
    func urlStringForSearchString(searchString: String) -> String {
        let escapedSearchString = searchString.stringByAddingPercentEscapesUsingEncoding(NSUTF8StringEncoding)
        let urlString = "http://d.yimg.com/autoc.finance.yahoo.com/autoc?query=" + escapedSearchString! + "&callback=YAHOO.Finance.SymbolSuggest.ssCallback"
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
        
        let json = JSON(data: data)["ResultSet"]["Result"]
        //println(json.description)
        
        if let count = json.arrayValue?.count {
            for index in 0...count-1 {
                
                var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
                
                if let exch = json[index]["exch"].stringValue {
                    company.exchange = exch
                }
                if let exchDisp = json[index]["exchDisp"].stringValue {
                    company.exchangeDisp = exchDisp
                }
                if let name = json[index]["name"].stringValue {
                    company.name = name
                }
                if let tickerSymbol = json[index]["symbol"].stringValue {
                    company.tickerSymbol = tickerSymbol
                }
                
                companies.append(company)
            }
        }
        
        return companies
    }
    
    func companiesFromJsonDictionary(dictionary: NSDictionary) -> [Company] {
        
        var companies = [Company]()
        let context = managedObjectContext
        let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: context!)
        
        for companyDictionary in (dictionary["ResultSet"] as NSDictionary)["Result"] as NSArray {
            
            var company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: nil)
            
            if let exch = companyDictionary["exch"] as? String {
                company.exchange = exch
            }
            if let exchDisp = companyDictionary["exchDisp"] as? String {
                company.exchangeDisp = exchDisp
            }
            if let name = companyDictionary["name"] as? String {
                company.name = name
            }
            if let tickerSymbol = companyDictionary["symbol"] as? String {
                company.tickerSymbol = tickerSymbol
            }
            
            companies.append(company)
        }
        
        return companies
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
