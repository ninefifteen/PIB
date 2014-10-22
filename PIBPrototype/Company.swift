//
//  Company.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/11/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import Foundation
import CoreData

class Company: NSManagedObject {

    @NSManaged var exchange: String
    @NSManaged var exchangeDisp: String
    @NSManaged var name: String
    @NSManaged var tickerSymbol: String
    @NSManaged var returnData: String

}
