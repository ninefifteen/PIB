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
    @NSManaged var isTarget: NSNumber
    @NSManaged var peers: NSSet
    @NSManaged var targets: NSSet
    

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
    
}
