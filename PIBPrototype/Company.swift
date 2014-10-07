//
//  Company.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 10/2/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import Foundation
import CoreData

//@objc(Company)

class Company: NSManagedObject {

    @NSManaged var name: String
    @NSManaged var exchange: String
    @NSManaged var tickerSymbol: String

}
