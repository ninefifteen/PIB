//
//  Company.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/22/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import Foundation
import CoreData

class Company: NSManagedObject {

    @NSManaged var exchange: String
    @NSManaged var exchangeDisp: String
    @NSManaged var name: String
    @NSManaged var tickerSymbol: String
    @NSManaged var returnData: String
    @NSManaged var totalRevenue: String
    @NSManaged var netIncome: String
    @NSManaged var grossProfit: String
    @NSManaged var rAndD: String
    @NSManaged var sgAndA: String
    
}
