//
//  Company.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import Foundation
import CoreData

enum DataState: Int16 {
    case DataDownloadInProgress = 0
    case DataDownloadCompleteWithError = 1
    case DataDownloadCompleteWithoutError = 2
}

class Company: NSManagedObject {

    @NSManaged var city: String
    @NSManaged var companyDescription: String
    @NSManaged var country: String
    @NSManaged var currencyCode: String
    @NSManaged var currencySymbol: String
    @NSManaged var employeeCount: NSNumber
    @NSManaged var exchange: String
    @NSManaged var exchangeDisplayName: String
    @NSManaged var name: String
    @NSManaged var state: String
    @NSManaged var street: String
    @NSManaged var tickerSymbol: String
    @NSManaged var webLink: String
    @NSManaged var zipCode: String
    @NSManaged var financialMetrics: NSSet
    @NSManaged var isTargetCompany: NSNumber
    @NSManaged var peers: NSSet
    @NSManaged var targets: NSSet
    @NSManaged var objectState: Int16
    
    var summaryDownloadError = false
    var financialsDownloadError = false
    var relatedCompaniesDownloadError = false
    var summaryDownloadComplete: Bool = false
    var financialsDownloadComplete: Bool = false
    var relatedCompaniesDownloadComplete: Bool = false
    
    var dataState: DataState {
        get { return DataState(rawValue: objectState) ?? .DataDownloadCompleteWithError }
        set { objectState = newValue.rawValue }
    }
    
    
    // MARK: - Class Methods
    
    class func saveNewTargetCompanyWithName(name: String, tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        var company: Company!
        
        if let savedCompany = Company.savedCompanyWithTickerSymbol(tickerSymbol, exchangeDisplayName: exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
            
            if savedCompany.isTargetCompany.boolValue {   // Company is already saved to app as a target company.
                
                //updateSavedCompany(savedCompany)  // Method not yet implemented.
                return
                
            } else {    // Company is saved to app but is only a peer.
                
                company = savedCompany
                
                // Remove old finacial metrics to prepare for update.
                var financialMetrics = company.financialMetrics.mutableCopy() as NSMutableSet
                financialMetrics.removeAllObjects()
                company.financialMetrics = financialMetrics.copy() as NSSet
            }
            
        } else {    // Company is NOT saved to app.
            
            // Create new company managed object.
            let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
            company = Company(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
            
            // Set attributes.
            company.name = name
            company.exchange = ""
            company.exchangeDisplayName = exchangeDisplayName
            company.tickerSymbol = tickerSymbol
            company.street = ""
            company.city = ""
            company.state = ""
            company.zipCode = ""
            company.country = ""
            company.companyDescription = ""
            company.webLink = ""
            company.currencySymbol = ""
            //company.currencyCode = ""
            company.employeeCount = 0
        }
        
        company.dataState = .DataDownloadInProgress
        company.isTargetCompany = NSNumber(bool: true)
        
        let dispatchGroup = dispatch_group_create()
        
        dispatch_group_enter(dispatchGroup)
        WebServicesManagerAPI.sharedInstance.downloadGoogleSummaryForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName) { (summaryDictionary, success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if success { company.addSummaryDataForCompanyInManagedObjectContext(managedObjectContext, fromSummaryDictionary: summaryDictionary) }
                company.summaryDownloadComplete = true
                company.summaryDownloadError = !success
                dispatch_group_leave(dispatchGroup)
            })
        }
        
        dispatch_group_enter(dispatchGroup)
        WebServicesManagerAPI.sharedInstance.downloadGoogleFinancialsForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName) { (financialDictionary, success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                if success { company.addFinancialDataForCompanyInManagedObjectContext(managedObjectContext, fromFinancialDictionary: financialDictionary) }
                company.financialsDownloadComplete = true
                company.financialsDownloadError = !success
                dispatch_group_leave(dispatchGroup)
            })
        }
        
        dispatch_group_enter(dispatchGroup)
        WebServicesManagerAPI.sharedInstance.downloadGoogleRelatedCompaniesForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName) { (peerCompanies, success) -> Void in
            
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                
                var savedRelatedCompanies = [Company]()
                var unsavedRelatedCompanies = [Company]()
                
                for peerCompany in peerCompanies {
                    if Company.isSavedCompanyWithTickerSymbol(peerCompany.tickerSymbol, exchangeDisplayName: peerCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
                        let savedCompany = Company.savedCompanyWithTickerSymbol(peerCompany.tickerSymbol, exchangeDisplayName: peerCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
                        savedRelatedCompanies.append(savedCompany!)
                    } else {
                        unsavedRelatedCompanies.append(peerCompany)
                    }
                }
                
                for savedRelatedCompany in savedRelatedCompanies {
                    company.addPeerCompanyWithTickerSymbol(savedRelatedCompany.tickerSymbol, withExchangeDisplayName: savedRelatedCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
                }
                
                if unsavedRelatedCompanies.count > 0 {
                    
                    let innerDispatchGroup = dispatch_group_create()
                    
                    for unsavedRelatedCompany in unsavedRelatedCompanies {
                        
                        dispatch_group_enter(innerDispatchGroup)
                        
                        Company.saveNewPeerCompanyWithName(unsavedRelatedCompany.name, tickerSymbol: unsavedRelatedCompany.tickerSymbol, exchangeDisplayName: unsavedRelatedCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext, withCompletion: { (success) -> Void in
                            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                                if success {
                                    company.addPeerCompanyWithTickerSymbol(unsavedRelatedCompany.tickerSymbol, withExchangeDisplayName: unsavedRelatedCompany.exchangeDisplayName, inManagedObjectContext: managedObjectContext)
                                }
                                dispatch_group_leave(innerDispatchGroup)
                            })
                        })
                    }
                    
                    dispatch_group_notify(innerDispatchGroup, dispatch_get_main_queue()) { () -> Void in
                        company.relatedCompaniesDownloadComplete = true
                        company.relatedCompaniesDownloadError = !success
                        dispatch_group_leave(dispatchGroup)
                    }
                    
                } else {
                    company.relatedCompaniesDownloadComplete = true
                    company.relatedCompaniesDownloadError = !success
                    dispatch_group_leave(dispatchGroup)
                }
            })
        }
        
        dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
            company.setDataStatusForCompanyInManagedObjectContext(managedObjectContext)
        }
    }
    
    class func updateSavedCompany(company: Company, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        // IMPLEMENTATION NEEDED!!!
        println("!!!Company.swift updateSavedCompany(_:inManagedObjectContext:) not implemented!!!")
    }
    
    class func saveNewPeerCompanyWithName(name: String, tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!, withCompletion completion: ((success: Bool) -> Void)?) {
        
        if !Company.isSavedCompanyWithTickerSymbol(tickerSymbol, exchangeDisplayName: exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
            
            //println("saveNewPeerCompanyWithName: \(name), tickerSymbol: \(tickerSymbol), exchangeDisplayName: \(exchangeDisplayName)")
            //println(tickerSymbol)
            
            // Create new company managed object.
            let entity = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
            let company: Company! = Company(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
            
            // Set attributes.
            company.name = name
            company.exchange = ""
            company.exchangeDisplayName = exchangeDisplayName
            company.tickerSymbol = tickerSymbol
            company.street = ""
            company.city = ""
            company.state = ""
            company.zipCode = ""
            company.country = ""
            company.companyDescription = ""
            company.webLink = ""
            company.currencySymbol = ""
            //company.currencyCode = ""
            company.employeeCount = 0
            company.isTargetCompany = NSNumber(bool: false)
            
            company.dataState = .DataDownloadInProgress
            company.isTargetCompany = NSNumber(bool: false)
            
            let dispatchGroup = dispatch_group_create()
            
            dispatch_group_enter(dispatchGroup)
            WebServicesManagerAPI.sharedInstance.downloadGoogleSummaryForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName) { (summaryDictionary, success) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if success { company.addSummaryDataForCompanyInManagedObjectContext(managedObjectContext, fromSummaryDictionary: summaryDictionary) }
                    company.summaryDownloadComplete = true
                    company.summaryDownloadError = !success
                    dispatch_group_leave(dispatchGroup)
                })
            }
            
            dispatch_group_enter(dispatchGroup)
            WebServicesManagerAPI.sharedInstance.downloadGoogleFinancialsForCompanyWithTickerSymbol(company.tickerSymbol, onExchange: company.exchangeDisplayName) { (financialDictionary, success) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    if success { company.addFinancialDataForCompanyInManagedObjectContext(managedObjectContext, fromFinancialDictionary: financialDictionary) }
                    company.financialsDownloadComplete = true
                    company.financialsDownloadError = !success
                    dispatch_group_leave(dispatchGroup)
                })
            }
            
            dispatch_group_notify(dispatchGroup, dispatch_get_main_queue()) { () -> Void in
                
                company.setDataStatusForCompanyInManagedObjectContext(managedObjectContext)
                
                if company.dataState == .DataDownloadCompleteWithoutError {
                    if completion != nil {
                        completion!(success: true)
                    }
                } else {
                    let theName = company.name
                    managedObjectContext.deleteObject(company)
                    if completion != nil {
                        completion!(success: false)
                    }
                }
            }
            
        } else {    // Company already saved.
            
            if completion != nil {
                completion!(success: false)
            }
        }
    }

    class func savedCompanyWithTickerSymbol(tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) -> Company? {
        
        let alternateContext = NSManagedObjectContext()
        alternateContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: alternateContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        var requestError: NSError? = nil
        
        let predicate = NSPredicate(format: "(tickerSymbol == %@) AND (exchangeDisplayName == %@)", tickerSymbol, exchangeDisplayName)
        request.predicate = predicate
        var matchingCompaniesArray = alternateContext.executeFetchRequest(request, error: &requestError) as [Company]
        if requestError != nil {
            println("Fetch request error: \(requestError?.description)")
            return nil
        }
        
        if matchingCompaniesArray.count > 0 {
            let savedCompany = matchingCompaniesArray[0]
            let savedCompanyId = savedCompany.objectID
            return managedObjectContext.objectWithID(savedCompanyId) as? Company
        } else {
            return nil
        }
    }
    
    class func isSavedCompanyWithTickerSymbol(tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) -> Bool {
        
        let company = savedCompanyWithTickerSymbol(tickerSymbol, exchangeDisplayName: exchangeDisplayName, inManagedObjectContext: managedObjectContext)
        return company != nil
    }
    
    class func removeIncompleteDataCompaniesInManagedObjectContext(managedObjectContext: NSManagedObjectContext!) {
                
        // Delete companies with incomplete data (download interrupted).
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        var requestError: NSError? = nil
        
        let incompleteCompaniesPredicate = NSPredicate(format: "objectState == 0")
        request.predicate = incompleteCompaniesPredicate
        var incompleteCompaniesArray = managedObjectContext.executeFetchRequest(request, error: &requestError) as [Company]
        if requestError != nil {
            println("Fetch request error: \(requestError?.description)")
        }
        
        for company in incompleteCompaniesArray {
            println("delete: \(company.name), dataState: \(company.dataState))")
            managedObjectContext.deleteObject(company)
        }
        
        // Save the context.
        var saveError: NSError? = nil
        if !managedObjectContext.save(&saveError) {
            println("Save Error in removeIncompleteDataCompaniesInManagedObjectContext(_:).")
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(saveError), \(saveError.userInfo)")
            abort()
        }
    }
    
    
    // MARK: - Instance Methods
    
    func addSummaryDataForCompanyInManagedObjectContext(managedObjectContext: NSManagedObjectContext!, fromSummaryDictionary summaryDictionary: [String: String]) {
        
        let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
        var mutableFinancialMetrics = financialMetrics.mutableCopy() as NSMutableSet
        
        let financialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
        financialMetric.type = "Market Cap"
        financialMetric.date = NSDate()
        financialMetric.value = NSString(string: summaryDictionary["Market Cap"]!).doubleValue
        mutableFinancialMetrics.addObject(financialMetric)
        
        financialMetrics = mutableFinancialMetrics.copy() as NSSet
        
        companyDescription = summaryDictionary["companyDescription"]!
        street = summaryDictionary["street"]!
        city = summaryDictionary["city"]!
        state = summaryDictionary["state"]!
        zipCode = summaryDictionary["zipCode"]!
        country = summaryDictionary["country"]!
        if let employeeCountInt = summaryDictionary["employeeCount"]!.toInt() { employeeCount = employeeCountInt }
        webLink = summaryDictionary["webLink"]!
    }
    
    func addFinancialDataForCompanyInManagedObjectContext(managedObjectContext: NSManagedObjectContext!, fromFinancialDictionary financialDictionary: [String: AnyObject]) {
        
        if let companyCurrencyCode = financialDictionary["currencyCode"] as? String {
            currencyCode = companyCurrencyCode
        }
        
        if let companyCurrencySymbol = financialDictionary["currencySymbol"] as? String {
            currencySymbol = companyCurrencySymbol
        }
        
        let entity = NSEntityDescription.entityForName("FinancialMetric", inManagedObjectContext: managedObjectContext)
        var mutableFinancialMetrics = financialMetrics.mutableCopy() as NSMutableSet
        
        if let financialMetricArray = financialDictionary["financialMetrics"] as? [FinancialMetric] {
            for financialMetric in financialMetricArray {
                let newFinancialMetric: FinancialMetric! = FinancialMetric(entity: entity!, insertIntoManagedObjectContext: managedObjectContext)
                newFinancialMetric.date = financialMetric.date
                newFinancialMetric.type = financialMetric.type
                newFinancialMetric.value = financialMetric.value
                mutableFinancialMetrics.addObject(newFinancialMetric)
            }
        }
        
        financialMetrics = mutableFinancialMetrics.copy() as NSSet
    }
    
    func setDataStatusForCompanyInManagedObjectContext(managedObjectContext: NSManagedObjectContext!) {
        
        if summaryDownloadError || financialsDownloadError /*|| relatedCompaniesDownloadError*/ {
            dataState = .DataDownloadCompleteWithError
        } else {
            dataState = .DataDownloadCompleteWithoutError
        }
        
        // Save all companies that are target companies or peers that download without error. Other peers deleted later.
        if isTargetCompany.boolValue || dataState == .DataDownloadCompleteWithoutError {
            // Save the context.
            var saveError: NSError? = nil
            if !managedObjectContext.save(&saveError) {
                println("Save Error in setDataStatusForCompanyInManagedObjectContext(_:).")
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                //println("Unresolved error \(saveError), \(saveError.userInfo)")
                abort()
            }
        }
    }
    
    func changeFromTargetToPeerInManagedObjectContext(managedObjectContext: NSManagedObjectContext!) {
        
        isTargetCompany = NSNumber(bool: false)
        var error: NSError? = nil
        if !managedObjectContext.save(&error) {
            println("Save Error in changeFromTargetToPeerInManagedObjectContext(_:) while changing isTargetCompany.")
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        var companyPeers = peers.mutableCopy() as NSMutableSet
        companyPeers.removeAllObjects()
        peers = companyPeers.copy() as NSSet
        
        if !managedObjectContext.save(&error) {
            println("Save Error in changeFromTargetToPeerInManagedObjectContext(_:) while removing peers.")
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }
    
    func removePeerCompany(peerCompany: Company, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        var companyPeers = peers.mutableCopy() as NSMutableSet
        companyPeers.removeObject(peerCompany)
        peers = companyPeers.copy() as NSSet
        
        if peerCompany.targets.count < 1 {
            managedObjectContext.deleteObject(peerCompany)
        }
        
        var error: NSError? = nil
        if !managedObjectContext.save(&error) {
            println("Save Error in changeFromTargetToPeerInManagedObjectContext(_:) while removing peers.")
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
    }

    func addPeerCompanyWithTickerSymbol(tickerSymbol: String, withExchangeDisplayName exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
                
        let savedPeerCompany = Company.savedCompanyWithTickerSymbol(tickerSymbol, exchangeDisplayName: exchangeDisplayName, inManagedObjectContext: managedObjectContext)
        
        if let peerCompany = savedPeerCompany {
            var peers = self.peers.mutableCopy() as NSMutableSet
            peers.addObject(peerCompany)
            self.peers = peers.copy() as NSSet
        }
    }
    
}
