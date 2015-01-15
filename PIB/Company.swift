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

}
