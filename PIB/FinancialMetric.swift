//
//  FinancialMetric.swift
//  PIB
//
//  Created by Shawn Seals on 12/18/14.
//  Copyright (c) 2014 Scoutly. All rights reserved.
//

import Foundation
import CoreData

class FinancialMetric: NSManagedObject {

    @NSManaged var type: String
    @NSManaged var value: NSNumber
    @NSManaged var year: NSNumber
    @NSManaged var company: NSManagedObject

}
