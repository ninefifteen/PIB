//
//  PIBHelper.swift
//  PIBPrototype
//
//  Created by Shawn Seals on 11/10/14.
//  Copyright (c) 2014 Shawn Seals. All rights reserved.
//

import UIKit

class PIBHelper: NSObject {
   
    class func pibStandardStyleValueStringFromDoubleValue(value: Double) -> String {
        
        var modifiedValue = value
        var returnString = String()
        
        let formatter = NSNumberFormatter()
        formatter.usesSignificantDigits = true
        formatter.maximumSignificantDigits = 3
        formatter.minimumSignificantDigits = 3
        formatter.roundingMode = NSNumberFormatterRoundingMode.RoundHalfUp
        
        if modifiedValue >= 1000000000.0 {
            modifiedValue /= 1000000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + " B"
        } else if modifiedValue >= 1000000.0 {
            modifiedValue /= 1000000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + " M"
        } else if modifiedValue >= 1000.0 {
            modifiedValue /= 1000.0
            returnString = formatter.stringFromNumber(modifiedValue)! + " K"
        } else {
            returnString = formatter.stringFromNumber(modifiedValue)!
        }
        
        return returnString
    }
}
