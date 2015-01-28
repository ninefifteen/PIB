//
//  Company.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import Foundation
import CoreData

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
    @NSManaged var dataDownloadComplete: NSNumber
    @NSManaged var dataDownloadCompleteWithError: NSNumber
    @NSManaged var isTarget: NSNumber
    @NSManaged var peers: NSSet
    @NSManaged var targets: NSSet
    
    var summaryDownloadError = false
    var financialsDownloadError = false
    var relatedCompaniesDownloadError = false
    var summaryDownloadComplete: Bool = false
    var financialsDownloadComplete: Bool = false
    var relatedCompaniesDownloadComplete: Bool = false
    
    
    // MARK: - Class Methods
    
    class func saveNewTargetCompanyWithName(name: String, tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        var company: Company!
        
        if let savedCompany = Company.savedCompanyWithTickerSymbol(tickerSymbol, exchangeDisplayName: exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
            
            if savedCompany.isTarget.boolValue {   // Company is already saved to app as a target company.
                
                //updateSavedCompany(savedCompany)
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
        
        company.dataDownloadComplete = NSNumber(bool: false)
        company.isTarget = NSNumber(bool: true)
        
        WebServicesManagerAPI.sharedInstance.downloadGoogleSummaryForCompany(company, withCompletion: { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                company.summaryDownloadComplete = true
                company.summaryDownloadError = !success
                company.setDataDownloadCompleteIfAllCompleteForCompanyInManagedObjectContext(managedObjectContext)
            })
        })
        WebServicesManagerAPI.sharedInstance.downloadGoogleFinancialsForCompany(company, withCompletion: { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                company.financialsDownloadComplete = true
                company.financialsDownloadError = !success
                company.setDataDownloadCompleteIfAllCompleteForCompanyInManagedObjectContext(managedObjectContext)
            })
        })
        WebServicesManagerAPI.sharedInstance.downloadGoogleRelatedCompaniesForCompany(company, withCompletion: { (success) -> Void in
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                company.relatedCompaniesDownloadComplete = true
                company.relatedCompaniesDownloadError = !success
                company.setDataDownloadCompleteIfAllCompleteForCompanyInManagedObjectContext(managedObjectContext)
            })
        })
    }
    
    class func updateSavedCompany(company: Company, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        let companyName = company.name  // Needed for alert in the event the data not able to be downloaded.
        
        // Remove old finacial metrics to prepare for update.
        var financialMetrics = company.financialMetrics.mutableCopy() as NSMutableSet
        financialMetrics.removeAllObjects()
        company.financialMetrics = financialMetrics.copy() as NSSet
        
        company.dataDownloadComplete = NSNumber(bool: false)
        
        // Download fundamentals for newly added company.
        // IMPLEMENTATION NEEDED!!!
    }
    
    class func saveNewPeerCompanyWithName(name: String, tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        if !Company.isSavedCompanyWithTickerSymbol(tickerSymbol, exchangeDisplayName: exchangeDisplayName, inManagedObjectContext: managedObjectContext) {
            
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
            company.isTarget = NSNumber(bool: false)
            
            let companyName = name   // Used for error message in the event financial data is not found.
            
            // Download fundamentals for newly added company.
            // IMPLEMENTATION NEEDED!!!
        }
    }

    class func savedCompanyWithTickerSymbol(tickerSymbol: String, exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) -> Company? {
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        var requestError: NSError? = nil
        
        let predicate = NSPredicate(format: "(tickerSymbol == %@) AND (exchangeDisplayName == %@)", tickerSymbol, exchangeDisplayName)
        request.predicate = predicate
        var matchingCompaniesArray = managedObjectContext.executeFetchRequest(request, error: &requestError) as [Company]
        if requestError != nil {
            println("Fetch request error: \(requestError?.description)")
            return nil
        }
        
        if matchingCompaniesArray.count > 0 {
            return matchingCompaniesArray[0]
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
        
        let incompleteCompaniesPredicate = NSPredicate(format: "dataDownloadComplete == 0")
        request.predicate = incompleteCompaniesPredicate
        var incompleteCompaniesArray = managedObjectContext.executeFetchRequest(request, error: &requestError) as [Company]
        if requestError != nil {
            println("Fetch request error: \(requestError?.description)")
        }
        
        for company in incompleteCompaniesArray {
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
    
    func setDataDownloadCompleteIfAllCompleteForCompanyInManagedObjectContext(managedObjectContext: NSManagedObjectContext!) {
        
        if summaryDownloadComplete && financialsDownloadComplete && relatedCompaniesDownloadComplete {
            
            if summaryDownloadError || financialsDownloadError || relatedCompaniesDownloadError {
                dataDownloadCompleteWithError = NSNumber(bool: true)
            } else {
                dataDownloadComplete = NSNumber(bool: true)
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
    }
    
    class func sendDataNotFoundMessageForCompanyName(companyName: String) {
        NSNotificationCenter.defaultCenter().postNotificationName("DataNotFoundMessageForCompanyName", object: self, userInfo: ["companyName": companyName])
    }
    
    
    // MARK: - Instance Methods
    
    func addPeerCompanyWithTickerSymbol(tickerSymbol: String, withExchangeDisplayName exchangeDisplayName: String, inManagedObjectContext managedObjectContext: NSManagedObjectContext!) {
        
        let entityDescription = NSEntityDescription.entityForName("Company", inManagedObjectContext: managedObjectContext)
        let request = NSFetchRequest()
        request.entity = entityDescription
        
        var requestError: NSError? = nil
        
        let predicate = NSPredicate(format: "(tickerSymbol == %@) AND (exchangeDisplayName == %@)", tickerSymbol, exchangeDisplayName)
        request.predicate = predicate
        
        var matchingCompaniesArray = managedObjectContext.executeFetchRequest(request, error: &requestError) as [Company]
        if requestError != nil {
            println("Fetch request error: \(requestError?.description)")
            return
        }
        
        if matchingCompaniesArray.count > 0 {
            let peerCompany = matchingCompaniesArray[0]
            var peers = self.peers.mutableCopy() as NSMutableSet
            peers.addObject(peerCompany)
            self.peers = peers.copy() as NSSet
        }
    }
    
}
