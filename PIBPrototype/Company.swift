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

    @NSManaged var exchange: String
    @NSManaged var exchangeDisplayName: String
    @NSManaged var name: String
    @NSManaged var tickerSymbol: String
    @NSManaged var companyDescription: String
    @NSManaged var financialMetrics: NSSet

}
