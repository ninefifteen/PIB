//
//  FinancialMetric.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/30/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import Foundation
import CoreData

class FinancialMetric: NSManagedObject {

    @NSManaged var type: String
    @NSManaged var year: NSNumber
    @NSManaged var value: NSNumber
    @NSManaged var company: Company

}
