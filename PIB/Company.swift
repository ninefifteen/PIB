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
        WebServicesManagerAPI.sharedInstance.downloadGoogleSummaryForCompany(company, withCompletion: { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                company.summaryDownloadComplete = true
                company.summaryDownloadError = !success
                dispatch_group_leave(dispatchGroup)
            })
        })
        
        dispatch_group_enter(dispatchGroup)
        WebServicesManagerAPI.sharedInstance.downloadGoogleFinancialsForCompany(company, withCompletion: { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                company.financialsDownloadComplete = true
                company.financialsDownloadError = !success
                dispatch_group_leave(dispatchGroup)
            })
        })
        
        dispatch_group_enter(dispatchGroup)
        WebServicesManagerAPI.sharedInstance.downloadGoogleRelatedCompaniesForCompany(company, withCompletion: { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                company.relatedCompaniesDownloadComplete = true
                company.relatedCompaniesDownloadError = !success
                dispatch_group_leave(dispatchGroup)
            })
        })
        
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
            WebServicesManagerAPI.sharedInstance.downloadGoogleSummaryForCompany(company, withCompletion: { (success) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    company.summaryDownloadComplete = true
                    company.summaryDownloadError = !success
                    dispatch_group_leave(dispatchGroup)
                })
            })
            
            dispatch_group_enter(dispatchGroup)
            WebServicesManagerAPI.sharedInstance.downloadGoogleFinancialsForCompany(company, withCompletion: { (success) -> Void in
                dispatch_async(dispatch_get_main_queue(), { () -> Void in
                    company.financialsDownloadComplete = true
                    company.financialsDownloadError = !success
                    dispatch_group_leave(dispatchGroup)
                })
            })
            
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
            
            println("\(name) already saved.")
            
            if completion != nil {
                completion!(success: false)
            }
        }
    }

    class func savedCompanyWithTickerSymbol(tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) -> Company? {
        
        let backgroundContext = NSManagedObjectContext()
        backgroundContext.persistentStoreCoordinator = managedObjectContext.persistentStoreCoordinator
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: backgroundContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        var requestError: NSError? = nil
        
        let predicate = NSPredicate(format: "(tickerSymbol == %@) AND (exchangeDisplayName == %@)", tickerSymbol, exchangeDisplayName)
        request.predicate = predicate
        var matchingCompaniesArray = backgroundContext.executeFetchRequest(request, error: &requestError) as [Company]
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
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(saveError), \(saveError.userInfo)")
            abort()
        }
    }
    
    
    // MARK: - Instance Methods
    
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
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            //println("Unresolved error \(error), \(error.userInfo)")
            abort()
        }
        var companyPeers = peers.mutableCopy() as NSMutableSet
        companyPeers.removeAllObjects()
        peers = companyPeers.copy() as NSSet
        
        if !managedObjectContext.save(&error) {
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
