//
//  Company.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/30/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import Foundation
import CoreData

class Company: NSManagedObject {

    @NSManaged var street: String
    @NSManaged var city: String
    @NSManaged var state: String
    @NSManaged var zipCode: String
    @NSManaged var country: String
    @NSManaged var exchange: String
    @NSManaged var exchangeDisplayName: String
    @NSManaged var name: String
    @NSManaged var tickerSymbol: String
    @NSManaged var companyDescription: String
    @NSManaged var employeeCount: NSNumber
    @NSManaged var financialMetrics: NSSet

}
